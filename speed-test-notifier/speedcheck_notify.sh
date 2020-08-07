echo `speedtest --simple --no-upload --secure | grep "Download" | sed "s/Download: //g" | sed "s/ Mbit\/s//g"`
