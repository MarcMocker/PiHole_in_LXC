#!/usr/bin/env bash

function info { echo -e "\e[32m[info] $*\e[39m"; }
function done { echo -e "\e[32m[done] $*\e[39m"; exit 0; }
function warn { echo -e "\e[33m[warn] $*\e[39m"; }
function error { echo -e "\e[31m[error] $*\e[39m"; exit 1; }

LOG=/root/.log/$(date -I)
NULL=/dev/null
URL=https://raw.githubusercontent.com/MarcMocker/PiHole_in_LXC/main/install
UNBOUD_CONF=/etc/unbound/unbound.conf.d/pi-hole.conf
SETUP_VARS=/etc/pihole/setupVars.conf
ROOT_HINTS=/var/lib/unbound/root.hints
AUTOUPDATE_SCRIPT=/root/autoupdate.sh

mkdir /root/.log
mkdir $LOG

clear

info updating dependencies...
info updating dependencies... >> $LOG/updates.log
apt-get update >> $LOG/updates.log

info updating installed packages...
info updating installed packages... >> $LOG/updates.log
apt-get dist-upgrade -y  >> $LOG/updates.log

info installing dependencies...
info installing dependencies... >> $LOG/updates.log
apt-get install curl wget git -y >> $LOG/updates.log

info removing unused packages...
info removing unused packages... >> $LOG/updates.log
apt-get autoremove -y >> $LOG/updates.log


info installing PiHole...
info installing PiHole... >> $LOG/pihole.log
curl -sSL https://install.pi-hole.net | bash
cp -b /etc/pihole/install.log $LOG/pihole.log

clear
info updating dependencies...
info updating installed packages...
info installing dependencies...
info removing unused packages...
info installing PiHole...

info installing Unbound...
info installing Unbound... >> $LOG/unbound.log
apt-get install unbound -y >> $LOG/unbound.log

info loading hints of DNS rootservers...
info loading hints of DNS rootservers... >> $LOG/unbound.log
wget https://www.internic.net/domain/named.root -qO- | tee $ROOT_HINTS >> $LOG/unbound.log

info setting up the unbound configuration file for pihole...
info setting up the unbound configuration file for pihole... >> $LOG/unbound.log
wget $URL/pi-hole.conf -qO- | tee $UNBOUD_CONF >> $LOG/unbound.log
sleep 10
service unbound restart >> $LOG/unbound.log

info checking if DNS server is set properly
info checking if DNS server is set properly >> $LOG/pihole.log
if ! grep -q "PIHOLE_DNS_1=127.0.0.1#5335" "$SETUP_VARS"; then
    warn DNS need to be set manually >> $LOG/pihole.log
    echo ""
    warn SET UNBOUND THE ONLY DNS SERVER:
    warn ""
    warn "in the webui go to Settings > DNS"
    warn there you add the custom DNS entry:
    warn "        127.0.0.1#5335"
    warn and remove the selected upstream
    warn DNS servers.
    echo ""
else
    info DNS set correctly
    info DNS set correctly >> $LOG/pihole.log
fi

info Please set a new password for the webgui:
info Please set a new password for the webgui:  >> $LOG/pihole.log

read -r -s -p "> "

PASSWD=$REPLY
/usr/local/bin/pihole -a -p "$PASSWD"
if [ $? -eq 0 ]; then
    info You are going to need this to log into your webinterface.
    info New password set correctly  >> $LOG/pihole.log
else
    warn Password no set caused by an error.  >> $LOG/pihole.log
    echo -e "\n"
    warn Password no set caused by an error.
    warn You may need to set it manually issuing
    warn ""
    warn "           pihole -a -p"
    echo ""
fi


grep autoupdate.sh < /etc/crontab > $NULL && done "Installation finished sucessfully!" || info Configuring automatic updates:
info Configuring automatic updates: >> $LOG/autoupdates.log

wget $URL/autoupdate.sh -qO- | tee $AUTOUPDATE_SCRIPT >> $LOG/autoupdates.log
chmod +x $AUTOUPDATE_SCRIPT

info Please set a new update policy:
info ""
info "DEFAULT: update on boot             [1]"
info "OPTION:  update daily at 1am        [2]"
info "OPTION:  update never automatically [3]"
info ""

read -r -p "> "
UPDATE_POLICY=$REPLY
case $UPDATE_POLICY in
    [1]* ) echo @reboot root ./root/autoupdate.sh >> /etc/crontab && info "selected option [1]" && info "selected option [1]" >> $LOG/autoupdates.log;;
    [2]* ) echo "0 1 * * * ./root/autoupdate.sh > /dev/null" >> /etc/crontab && info "selected option [2]" && info "selected option [2]" >> $LOG/autoupdates.log;;
    [3]* ) info "selected option [3] \n[info] This requires patching the system manually" && info "selected option [3] \n[info] This requires patching the system manually" >> $LOG/autoupdates.log;;
    * ) echo @reboot root ./root/autoupdate.sh >> /etc/crontab && info "selected default [1]" && info "selected default [1]" >> $LOG/autoupdates.log;;
esac

done Installation finished sucessfully!
