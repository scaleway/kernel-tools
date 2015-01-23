diff --git a/drivers/cpuidle/cpuidle-mvebu-v7.c b/drivers/cpuidle/cpuidle-mvebu-v7.c
index 38e6861..3716a1f 100644
--- a/drivers/cpuidle/cpuidle-mvebu-v7.c
+++ b/drivers/cpuidle/cpuidle-mvebu-v7.c
@@ -50,17 +50,17 @@ static struct cpuidle_driver armadaxp_idle_driver = {
 	.states[0]		= ARM_CPUIDLE_WFI_STATE,
 	.states[1]		= {
 		.enter			= mvebu_v7_enter_idle,
-		.exit_latency		= 10,
+		.exit_latency		= 100,
 		.power_usage		= 50,
-		.target_residency	= 100,
+		.target_residency	= 1000,
 		.name			= "MV CPU IDLE",
 		.desc			= "CPU power down",
 	},
 	.states[2]		= {
 		.enter			= mvebu_v7_enter_idle,
-		.exit_latency		= 100,
+		.exit_latency		= 1000,
 		.power_usage		= 5,
-		.target_residency	= 1000,
+		.target_residency	= 10000,
 		.flags			= MVEBU_V7_FLAG_DEEP_IDLE,
 		.name			= "MV CPU DEEP IDLE",
 		.desc			= "CPU and L2 Fabric power down",
