#!/usr/bin/env bash

function info-log {
    echo -e "\e[32m[info] $*\e[39m";
    echo -e "\e[32m[info] $*\e[39m" >> "$LOG";
}
function success {
    echo -e "\e[32m[done] $*\e[39m";
    echo -e "\e[32m[done] $*\e[39m" >> "$LOG";
    exit 0;
}
function echo-log {
    echo -e "$*";
    echo -e "$*" >> "$LOG";
}

LOG=/root/.log/add_blocklists.log
GRAVITY=/etc/pihole/gravity.db
URL=https://raw.githubusercontent.com/MarcMocker/PiHole_in_LXC/main/lists
GENERAL=general

SERVICES[0]=Amazon
SERVICES[1]=Baidu
SERVICES[2]=Chan
SERVICES[3]=Facebook
SERVICES[4]=Google
SERVICES[5]=HP
SERVICES[6]=LG
SERVICES[7]=Samsung
SERVICES[8]=Synology
SERVICES[9]=Twitch
SERVICES[10]=Ubisoft
SERVICES[5]=Windows-Telemetry
SERVICES[5]=Xiaomi


# like to add lists at all? else exit


function add_to_db(){
    LISTS=$1
    for LIST in $(curl "$URL/$LISTS"); do
        echo-log "[info] adding $LIST to the database..."
        sqlite3 $GRAVITY "INSERT INTO "adlist" ("address","enabled","comment") VALUES ('$LIST','1','$LISTS');"
        echo-log "[info] done."
    done

}

for SERVICE in "${SERVICES[@]}"
do
    info-log Do you like to add the $SERVICE tracking list? [Y/n]
    read -r -p "> "

    case $REPLY in
        [Nn]* ) info-log "skipping $SERVICE-list...";;
        * ) info-log "adding $SERVICE-list.selected default [1].." && add_to_db $SERVICE;;
    esac
done


info-log adding $GENERAL anti-tracker lists:
add_to_db $GENERAL
info-log done.

info-log updating gravity...
/usr/local/bin/pihole -g > $LOG
info-log done.

success All lists successfully enabled!
