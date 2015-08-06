#!/usr/bin/perl
# A simple trap handler

use LWP::Simple;
use URI::Escape;

# get current time
my $now_string = localtime;

# set to 1 to enable additional logging
my $debug = 0;

# set log file name
my $LOG_FILE = 'C:\Program Files\uptime software\uptime\scripts\snmp-trap-script\trap_to_ext_event.log';

# open log file for writing
open(LOGFILE, ">> $LOG_FILE");
print LOGFILE "\n------------------------------\n";

# log current time
print LOGFILE "$now_string\n";

# process the trap:
my $hostname = <STDIN>;
chomp($hostname);
my $ipaddress = <STDIN>;
chomp($ipaddress);

$ipaddress =~ /([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/;
$ipaddress = $1;

# write hostname and ip address to debug file
print LOGFILE "Hostname: $hostname\nIP Address: $ipaddress\n";

# MonitoringStationHost is the where the up.time Monitoring Station is installed.
# Ensure you can get to it from where this script is executed.
my $MonitoringStationHost = 'localhost';
# MonitoringStationPort is the API port that up.time uses
# The default is 9996
my $MonitoringStationPort = '9996';
# ExternalMonitorName is the name of the external event service that the script will change the status of.
my $ExternalMonitorName = 'SNMP Trap (member)';
# AlertStatus is the status you want to have the external event service changed to be.
# The options are 0 - OK, 1 - Warning, 2 - Critical, 3 - Unknown
my $AlertStatus = '2';

# Log monitor name for clarity (even though it is the same for all)
print LOGFILE "Service Monitor Name: $ExternalMonitorName\n";

# only log OID/value pairs if debug enabled
print LOGFILE "OID:\tValue\n" if ($debug);

# Read OID and value pairs into arrays
while(<STDIN>) {
    ($oid, $value) = /([^\s]+)\s+(.*)/;
    push @oids, $oid;
    push @values, $value;
	print LOGFILE "${oid}:\t${value}\n" if ($debug); # only log OID/value pairs if debug enabled
}

# Write to log file if no OID/value pairs are received, then stop script
print LOGFILE "ERROR: Quitting because the trap provided no OIDs.\n" if ($#oids < 1);
die "no oids" if ($#oids < 1);

my $message = '';
my $alertURI = '';

# Join OID/value pairs into a one line string for service monitor message
for($i = 0; $i <= $#oids; $i++) {
	$message .= "$oids[$i] = $values[$i] ";
}

# Convert message and monitor name to URI friendly format; write to log if debug enabled
$message = uri_escape($message);
print LOGFILE "URI Escaped Messaged: $message\n" if ($debug);
$ExternalMonitorName = uri_escape($ExternalMonitorName);
print LOGFILE "URI Escaped Monitor Name: $ExternalMonitorName\n" if ($debug);

# Build URI used to post new external monitor status
$alertURI = "http://$MonitoringStationHost:$MonitoringStationPort/command?command=externalcheck&name=$ExternalMonitorName&status=$AlertStatus&message=$message&hostname=$ipaddress";
print LOGFILE "Alert URI: $alertURI\n" if ($debug); # long string; only log if debug enabled 

# Post URI to up.time, simultaneously check response status, then log success or fail
if ( is_success( getprint( $alertURI ) ) ) {
	print LOGFILE "Successfully updated monitor status\n";
} else {
	print LOGFILE "Failed to update monitor status\n";
}

# Close log file
close(LOGFILE);
