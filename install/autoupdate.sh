#!/usr/bin/env bash

function info {
    echo -e "\e[32m[info] $*\e[39m";
    echo -e "\e[32m[info] $*\e[39m" >> $LOG;
}

LOG=/tmp/autoupdate.log

touch $LOG

sleep 180

info apt-get update
apt-get update >> $LOG

info apt-get dist-upgrade -y
apt-get dist-upgrade -y >> $LOG

info apt-get autoremove -y
apt-get autoremove -y >> $LOG

info pihole -up
/usr/local/bin/pihole -up >> $LOG
