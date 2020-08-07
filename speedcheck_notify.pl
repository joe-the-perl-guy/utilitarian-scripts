#!/usr/bin/perl
use warnings;
use strict;

############################################################
#
# THIS SCRIPT CHECKS THE SPEED OF YOUR INTERNET CONNECTION
# AND REPORTS IT USING notify-send
# IT USES THE FOLLOWING TOOLS. IF THESE AREN'T INSTALLED
# PLEASE INSTALL THEM
#
###########################################################

# CHECK IF speedtest AND notify-send ARE INSTALLED
my $speedcheck_path = `which speedtest`;
chomp($speedcheck_path);
my $notifysend_path = `which notify-send`;
chomp($notifysend_path);

if($speedcheck_path eq ''){
	print "The tool 'speedtest-cli' is not installed. Please install it.\nOn Ubuntu run this command: sudo apt install speedtest-cli\n";
	exit;
}elsif($notifysend_path eq ''){
	print "The tool 'notify-send' is not installed. Please install it.\n";
	exit;
}


if(-e 'speedcheck_notify.sh'){
	my $current_speed = `sh speedcheck_notify.sh`;
	my $speed_threshold = 20.00;
	chomp($current_speed);
	if($current_speed < $speed_threshold){
		`$notifysend_path "Current speed ($current_speed Mbit/s) less than ($speed_threshold Mbit/s)"`;
	}
}else{
	print "\n\t\t**ERROR** - a required file as not found.\n\n\tThe file \"speedcheck_notify.sh\" was not found.\n\tFollow these instructions to create it and run this script again.\n\n";
	print "\t1. Copy and run the following command - without adding any extra spaces or characters.\n";
	print "\t".'echo \'echo `speedtest --simple --no-upload --secure | grep "Download" | sed "s/Download: //g" | sed "s/ Mbit\/s//g"`\' >> speedcheck_notify.sh'."\n";
	print "\t2. That's it. You're done.\n";
	exit;
}
