#!/usr/bin/perl -w
# Mer Kernel config specification checker
# http://wiki.merproject.org/wiki/Adaptation_Guide

# CONFIG must be set to one of the permitted values "," seperated and
# multiple values permitted

# y = set and enabled
# m = set and module
# n = must be unset (commented out)
#
# "value" = must be set to "value"
# /regexp/ = "value" which matches regexp
#
# ! = Failure will be warned, not errored

# Known issues with the basic parser:
# * # in regexps or strings cause issues if there's no trailing #
# * can't have "," in /regexp/

use Text::ParseWords;
use strict;
use Term::ANSIColor;
use File::Basename;

my $debug = 0;
my %config;

# Parse input argument
my $type = shift;
my $file = shift;

if (!$type or !$file) {
    print "Usage: ./verify_kernel_config.pl <type> <kernel config>\n";
    print "types: lxc nfs-rootfs\n";
    exit;
}

# Read according to check type

my $input = dirname($0)."/configs/$type.conf";
open (my $DATA, "<", $input) || die "Error: type $type does not exist!";

while (<$DATA>) {
    next if /^\s*(#.*)?$/ ; # skip comments and blank lines
    chomp;

    my ($conf, $allowed) = split(' ', $_, 2);

    # Remove and capture any trailing comment (dubious matching here
    # since comments in a "" or // will be removed too)
    my $comment;
    if ($allowed =~ s/(#\s*)(.*)?$//) {
        $comment = $2 if $2;
    }

    # http://perldoc.perl.org/Text/ParseWords.html
    my @allowed = parse_line(",", 1, $allowed);

    my $warning;
    # Strip leading/trailing space for each value and check for warnings
    foreach (@allowed) {
        s/^\s+|\s+$//g;
        $warning = 1 if $_ eq "!" ;
    }

    # Each CONFIG_* has an array of allowed values, a comment and a flag
    # to say it's only a warning (in which case we print the comment)
    $config{$conf} = {allowed => \@allowed,
                      comment => $comment,
                      warning => $warning };
}

print "\nScanning\n" if $debug;
open (my $FILE, "<", $file) || die "Error: file $file does not exist !!";
while (<$FILE>) {
    next if /^\s*(#.*)?$/ ; # skip comments and blank lines
    chomp;
    my ($conf, $value) = split('=', $_, 2);

    # Only check CONFIG_* values we know about
    next unless $config{$conf};

    my $c = $config{$conf};

    print "$conf matched, checking..." if $debug;
    $c->{"value"} = $value; # Store the value for later reporting

    my $allowed = $c->{"allowed"};
    for my $allow (@$allowed) {
        if (substr($allow,1,1) eq '/') { # regexps
            print "Do a regex match : \"$value\" =~ $allow\n" if $debug;

        } elsif (substr($allow,1,1) eq '"') { # strings
            print "Do a string match : $allow == $value\n" if $debug;
            if ($value eq $allow) {$c->{"valid"} = 1; }

        } else { # plain y/m values
            print "match y/m : $value == $allow\n" if $debug;
            if ($value eq $allow) {$c->{"valid"} = 1; }
        }
    }
    if ($c->{"valid"}) { print "OK\n" if $debug;}
}

print "Results\n" if $debug;
my $fatal = 0;
for my $conf (keys %config) {
    my $c = $config{$conf};

    if (! $c->{"valid"}) { # Check for 'n' case
        foreach my $allow (@{$c->{"allowed"}}) {
            if (("$allow" eq "n") and ! $c->{"value"}) {
                $c->{"valid"} = 1;
            }
        }
    }

    # Now report
    if (! $c->{"valid"}) {
        print defined($c->{"warning"}) ? colored("WARNING: ", 'bright_yellow') : colored("ERROR: ", 'bright_red');
        print colored("$conf", 'bright_white') , " is invalid, ";
        if ($c->{"value"}) {
            print "Value is: ". $c->{"value"} .", ";
        } else {
            print "It is unset, ";
        }
        print "Allowed values : ".join(", ", @{$c->{"allowed"}}) ."\n";
        if (! $c->{"warning"}) {
            $fatal = 1;
        }
    }
}
exit $fatal;
