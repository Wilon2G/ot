#!/bin/bash
echo $USER
wget https://github.com/Wilon2G/ot/archive/refs/heads/master.zip 
unzip master.zip
sudo touch /var/log/ot.log
sed -i "s/my_user/$USER/g" ot-master/ot.conf.json
sudo cp ot-master/ot.conf.json  /usr/ot.conf.json
sudo cp ot-master/ot.sh  /usr/local/bin/ot



