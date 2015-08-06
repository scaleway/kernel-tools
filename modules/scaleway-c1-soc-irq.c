/*
 * Scaleway C1 SoC IRQ handling
 *
 * Copyright (C) 2014-2015 Scaleway
 *
 * Manfred Touron <mtouron@scaleway.com>
 *
 * This file is licensed under the terms of the GNU General Public
 * License version 2.  This program is licensed "as is" without any
 * warranty of any kind, whether express or implied.
 */

#include <linux/kernel.h>
#include <linux/reboot.h>
#include <linux/module.h>
#include <linux/interrupt.h>
#include <linux/irq.h>
#include <linux/err.h>
#include <linux/of_gpio.h>
#include <linux/idr.h>
#include <linux/slab.h>
#include <linux/platform_device.h>
#include <linux/reboot.h>
#include <linux/sysrq.h>
#include <linux/syscalls.h>
#include <linux/kthread.h>
#include <linux/gpio.h>

#define SCALEWAYC1_GPIO_SWRESET 47
#define SCALEWAYC1_GPIO_BOOTED 42

static int g_irq = -1;
static struct task_struct *task;
static int need_reboot = 0;
static atomic_t probe_count = ATOMIC_INIT(0);
static DECLARE_WAIT_QUEUE_HEAD(probe_waitqueue);
static void scalewayc1_reboot(void);

static int scalewayc1_reboot_thread(void *arg) {
  /* block the thread and wait for a wakeup.
   wakeup is done in two cases: module unload and reset gpio state change */
  wait_event_interruptible(probe_waitqueue, atomic_read(&probe_count) > 0);

  /* clean the counter */
  atomic_dec(&probe_count);

  /* reboot if woke up from gpio state change */
  if (need_reboot) {
    scalewayc1_reboot();
  }

  return 0;
}

static void scalewayc1_reboot(void) {
  /* Call /sbin/reset */
  char *argv[] = {
    "/sbin/init",
    "6",
    NULL
  };
  char *envp[] = {
    "HOME=/",
    "PWD=/",
    "PATH=/sbin",
    NULL
  };
  int ret;

  ret = call_usermodehelper(argv[0], argv, envp, UMH_WAIT_PROC);
  if (!ret) {
    printk("Scaleway C1 SoC IRQ: Soft resetting\n");
  } else {
    printk("Scaleway C1 SoC IRQ: cannot soft-reset\n");
  }
}

static irqreturn_t scalewayc1_irq_resethandler(int irq, void *dev_id) {
  /* handled when reset gpio state changed */
  if (irq == g_irq) {
    need_reboot = 1;
    atomic_inc(&probe_count);
    wake_up(&probe_waitqueue);
    irq_clear_status_flags(irq, IRQ_LEVEL);
  }
  return IRQ_HANDLED;
}

static int __init scalewayc1gpio_init(void) {
  unsigned int gpio_r;
  unsigned int gpio_b;

  printk(KERN_DEBUG "Scaleway C1 SoC IRQ: initializing\n");

  /* create reboot thread */
  task = kthread_create(scalewayc1_reboot_thread, NULL, "scaleway-c1-soc-irq");
  if (IS_ERR(task)) {
    printk(KERN_ALERT "Scaleway C1 SoC IRQ: kthread_create error\n");
    return -1;
  }
  wake_up_process(task);

  /* setup an irq that watch the reset gpio state */
  gpio_r = SCALEWAYC1_GPIO_SWRESET;
  if (gpio_request(gpio_r, "softreset") < 0) {
    printk(KERN_ALERT "Scaleway C1 SoC IRQ: [softreset] cannot be requested\n");
    return -1;
  }
  if (gpio_direction_input(gpio_r) < 0) {
    gpio_free(gpio_r);
    printk(KERN_ALERT "Scaleway C1 SoC IRQ: gpio_direction_input error\n");
    return -1;
  }
  if ((g_irq = gpio_to_irq(gpio_r)) < 0) {
    gpio_free(gpio_r);
    printk(KERN_ALERT "Scaleway C1 SoC IRQ: gpio_to_irq error\n");
    return -1;
  }
  irq_clear_status_flags(g_irq, IRQ_LEVEL);
  if (request_any_context_irq(g_irq, scalewayc1_irq_resethandler,
				IRQF_TRIGGER_FALLING, "scaleway-c1", NULL) < 0) {
    gpio_free(gpio_r);
    printk(KERN_ALERT "Scaleway C1 SoC IRQ: request_any_context_irq error\n");
    return -1;
  }

  /* enable console, switch the booted gpio */
  gpio_b = SCALEWAYC1_GPIO_BOOTED;
  if (gpio_request(gpio_b, "booted") < 0) {
    gpio_free(gpio_r);
    printk(KERN_ALERT "Scaleway C1 SoC IRQ: [booted] cannot be requested\n");
    return -1;
  }
  if (gpio_direction_output(gpio_b, 0) < 0) {
    gpio_free(gpio_b);
    gpio_free(gpio_r);
    printk(KERN_ALERT "Scaleway C1 SoC IRQ: gpio_direction_output error\n");
    return -1;
  }
  printk(KERN_INFO "Scaleway C1 SoC IRQ: initialized\n");
  return 0;
}

static void __exit scalewayc1gpio_cleanup(void) {
  printk(KERN_DEBUG "Scaleway C1 SoC IRQ: cleaning\n");

  /* terminate the thread */
  need_reboot = 0;
  atomic_inc(&probe_count);
  wake_up(&probe_waitqueue);

  /* ensure free irq */
  if (-1 == g_irq) {
    free_irq(g_irq, NULL);
  }

  /* free gpio */
  gpio_free(SCALEWAYC1_GPIO_SWRESET);
  gpio_free(SCALEWAYC1_GPIO_BOOTED);
  kthread_stop(task);
  printk(KERN_DEBUG "Scaleway SoC IRQ cleaned\n");
}

module_init(scalewayc1gpio_init);
module_exit(scalewayc1gpio_cleanup);

MODULE_AUTHOR("Scaleway");
MODULE_DESCRIPTION("Scaleway - Scaleway C1 SoC IRQ");
MODULE_LICENSE("GPL");
