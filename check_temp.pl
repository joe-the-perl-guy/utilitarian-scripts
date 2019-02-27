#!/usr/bin/perl
use warnings;
use strict;
use lib "/home/pi/perl5/lib/perl5";
use XML::Simple;

my $log_level=0;

##############################################
##
## THIS SCRIPT READS THE TEMPERATURE OF A
## RASPBERRY PI AND SENDS AN ALERT TO A 
## TELEGRAM ROOM IF IT EXCEEDS A CERTAIN
## LIMIT.
## YOU CAN ALSO USE THIS SCIRPT TO SEND
## AN ALERT IF THE DISK SPACE FALLS BELOW A
## CERTAIN LIMIT.
##
## YOU NEED TO:
##	1. CREATE A BOT ON TELEGRAM: https://core.telegram.org/bots#creating-a-new-bot
##	2. CREATE A GROUP AND ADD THE BOT TO IT.
##	3. GET THE CHATID FOR THE ROOM USING THESE INSTRUCTIONS: https://stackoverflow.com/a/32572159
##	4. CREATE THE CONFIG.XML FILE. BEST LOCATION IS AT /static/config/config.xml
##
##
#############################################


# Read the API key and chat ID from 
# an XML config file.
# Using a config file makes sure you
# do not need to store any sensitive 
# credentials in your script
# also helps when you need to change
# the same password across multiple scripts.

# THE PATH WHERE YOUR CONFIG FILE IS STORED.
# MAKE SURE THE USER WHO RUNS THIS PERL SCRIPT
# CAN READ FROM THIS DIRECTORY.
# USE chown user:group filename on Linux
my $path='/static/config/config.xml'; 
my $xml =XMLin($path);
my $telegram_api_key =$xml->{telegram}->{key}; #telegram API key for your bot
my $telegram_chatid =$xml->{telegram}->{chatid}; #chat id of the telegram room to which the bot will send the message
my $temp_limit =$xml->{rpi}->{max_temp}; #max temperature limit for your Raspberry-Pi after which you want to be alerted

print "<<$0>><<DEBUG>><<Loaded parameters>><<>>\n" if $log_level>1;

#if the parameters above are not defined, exit the script.
unless($telegram_api_key && $telegram_chatid && $temp_limit){
	print "<<$0>><<ERROR>><<Either API key, ChatID or MaxTemp isn't defined. Please check $path>><<>>\n" if $log_level >=0;
	exit;
}

my $parse_mode='Markdown';

#The output of the vcgencmd measure_temp
# command is like temp=45.8'C
# to extract the numeric temperature
# use linux's sed utility to remove
# any extra text.
my @remove_text = ('temp=','\'C');

my $rpi_temp = `vcgencmd measure_temp | sed "s/$remove_text[0]//" | sed "s/$remove_text[1]//"`;
chomp($rpi_temp);
if($rpi_temp > $temp_limit){
	my $dt=`date +"%F %T"`;
	chomp $dt;
	my $message = "$dt: WARNING!! RaspberryPi temprature HIGH: $rpi_temp";
	print "<<$0>><<WARN>><<$message>><<$dt>>\n" if $log_level >=0;
	my $send_message = `curl -s 'https://api.telegram.org/bot$telegram_api_key/sendMessage' -d '{"chat_id":"$telegram_chatid","text":"$message","parse_mode":"$parse_mode"}' -H 'Content-Type: application/json'`;
}
