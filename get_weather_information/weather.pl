#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use DBI;
use XML::Simple;

my $log_level=0;

########################################################################
#
# VERSION - 0.1.20190226
#
# THIS SCRIPT IS USED TO SEND YOU A TELEGRAM
# MESSAGE WITH THE CURRENT WEATHER CONDITIONS AT A GIVEN PLACE
#
# THE WEATHER INFORMATION IS PROVIDED # BY THE GOOD FOLKS AT OPENWEATHERMAP.ORG
#
# THINGS TO BE DONE:
# 	1. ADD SUPPORT FOR LATITUDE AND LONGITUDE
# 	2. ADD SUPPORT FOR SENDING FORECAST INSTEAD OF CURRENT CONDITIONS
#

# PATH OF THE CONFIGURATION FILE
# SEE xx FOR MORE DETAILS
my $path='/static/config/config.xml';
my $xml =XMLin($path);

if($path){
	print "<<DEBUG>><<Loaded XML file>><<>>\n" if $log_level>0;
}else{
	print "<<ERROR>><<Unable to load XML config>><<>>\n";
	exit;
}

# LOAD THE WEATHER API DATA
my $name = $xml->{personal}->{name};
my $weather_api_key = $xml->{openweathermap}->{key};
my $city_id = $xml->{openweathermap}->{trimulgherry};
my $telegram_api_key = $xml->{telegram}->{key};
my $telegram_chatid = $xml->{telegram}->{chatid};


if($weather_api_key && $city_id && $telegram_api_key){
	print "<<DEBUG>><<All parameters loaded successfully>><<>>\n" if $log_level>0;
}else{
	print "<<ERROR>><<Unable to load weather API parameters>><<>>\n";
}

my $ua = LWP::UserAgent->new();
my $uri = "https://api.openweathermap.org/data/2.5/weather?id=$city_id&APPID=$weather_api_key&units=metric";

my $response = $ua->get($uri);
if($response->is_success){
	print "<<DEBUG>><<Received response from Weather API>><<>>\n" if $log_level>0;
	my $json = decode_json($response->content);
	my $message = "*Hello $name*".', here is the current weather information\n\n';
	$message .= 'City: '.$json->{"name"}.'\n';
	$message .= 'Weather: '.$json->{"weather"}->[0]->{"description"}.'\n';
	$message .= 'Temp.: '.$json->{"main"}->{"temp"}.'C \n';
	$message .= 'Min. Temp.: '.$json->{"main"}->{"temp_min"}.'C \n';
	$message .= 'Max. Temp.: '.$json->{"main"}->{"temp_max"}.'C \n';
	$message .= 'Humidity: '.$json->{"main"}->{"humidity"}.'%\n';
	my $send_message = `curl -s 'https://api.telegram.org/bot$telegram_api_key/sendMessage' -d '{"chat_id":"$telegram_chatid","text":"$message","parse_mode":"Markdown"}' -H 'Content-Type: application/json'`;
}else{
	print "<<ERROR>><<$response->status_line>><<>>\n";
}
