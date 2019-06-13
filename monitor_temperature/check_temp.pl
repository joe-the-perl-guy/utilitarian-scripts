#!/usr/bin/perl
use warnings;
use strict;
use lib '/home/pi/perl5/lib/perl5';
use XML::Simple;
use DBI;

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


#__Read the API key and chat ID from 
#__an XML config file.
#__Using a config file makes sure you
#__do not need to store any sensitive 
#__credentials in your script
#__also helps when you need to change
#__the same password across multiple scripts.

#__THE PATH WHERE YOUR CONFIG FILE IS STORED. MAKE SURE THE USER WHO RUNS THIS PERL SCRIPT
#__CAN READ FROM THIS DIRECTORY. USE chown user:group filename on Linux
my $path='/static/config/config.xml';
my $xml;

#__Try to read the XML config file. If it doesn't exist then show an error message and exit the script
eval{
	$xml=XMLin($path);
};

if($@){
	print "<<$0>><<ERROR>><<XML config not found at \"$path\">>\n";
	exit;
}


#_Load the API keys and other configuration from the XML config file.
my $telegram_api_key =$xml->{telegram}->{key}; #telegram API key for your bot
my $telegram_chatid =$xml->{telegram}->{chatid}; #chat id of the telegram room to which the bot will send the message
my $temp_limit =$xml->{rpi}->{max_temp}; #max temperature limit for your Raspberry-Pi after which you want to be alerted

#_Set the verbosity of logs
my $log_level=$xml->{rpi}->{$0}->{loglevel};

#__Initialize DB parameters. I use SQLite.
my $driver   = $xml->{database}->{driver};
my $database = $xml->{database}->{name};
my $autocommit = $xml->{database}->{autocommit};
my $dsn = "dbi:$driver:dbname=$database";
my $userid = $xml->{database}->{username};
my $password = $xml->{database}->{password};

#__connect to the sqlite database
my $dbh = DBI->connect($dsn,$userid,$password,{ AutoCommit => $autocommit }) or die DBI->errstr;


if ($log_level>1) { print "<<$0>><<DEBUG>><<Loaded parameters>><<>>\n" };

#if the parameters above are not defined, exit the script.
unless($telegram_api_key && $telegram_chatid && $temp_limit){
	if ($log_level >= 0) { print "<<$0>><<ERROR>><<Either API key, ChatID or MaxTemp isn't defined. Please check $path>><<>>\n" };
	exit;
}

#__How should telegram interpret the text message being sent
#__See here for more info: https://core.telegram.org/bots/api#markdown-style
my $parse_mode='Markdown';

#__The output of the vcgencmd measure_temp
#__command looks like temp=45.8'C
#__to extract the numeric temperature
#__use linux's sed utility to remove
#__any extra text.

#__text to be removed store in
#__separate array elements
my @remove_text = ('temp=','\'C');

#__Measure the temperature and use sed to remove the extra text 
#__so that we only have the numeric value left.
my $rpi_temp = `vcgencmd measure_temp | sed "s/$remove_text[0]//" | sed "s/$remove_text[1]//"`;

#__Remove extra spaces
chomp $rpi_temp ;

#__If the temperature is NOT within limits, then send a message
#__Otherwise just log the temperature to a database and exit.
if($rpi_temp > $temp_limit){

	#__Current timestamp. This uses Linux's date command for now.
	# **--TO BE FIXED--**
	my $dt=`date +"%F %T"`;
	chomp $dt;
	
	#__Compose the message to be sent over Telegram.
	my $message = "$dt: WARNING!! RaspberryPi temprature HIGH: $rpi_temp";
	
	if ($log_level >=0) { print "<<$0>><<WARN>><<$message>><<$dt>>\n" };
	
	#__Use curl to send the request. This is a quick and dirty approach with no error handling.
	# **--TO BE FIXED--**
	my $send_message = `curl -s 'https://api.telegram.org/bot$telegram_api_key/sendMessage' -d '{"chat_id":"$telegram_chatid","text":"$message","parse_mode":"$parse_mode"}' -H 'Content-Type: application/json'`;
}
