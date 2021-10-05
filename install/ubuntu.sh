#!/usr/bin/env bash

function info { echo -e "\e[32m[info] $*\e[39m"; }
function warn { echo -e "\e[33m[warn] $*\e[39m"; }

TEMPDIR=$(mktemp -d)
NULL=/dev/null
URL=https://raw.githubusercontent.com/MarcMocker/PiHole_in_LXC/main/install
UNBOUD_CONF=/etc/unbound/unbound.conf.d/pi-hole.conf
SETUP_VARS=/etc/pihole/setupVars.conf
ROOT_HINTS=/var/lib/unbound/root.hints
AUTOUPDATE_SCRIPT=/root/autoupdate.sh

clear

info updating dependencies...
apt-get update > $NULL

info updating installed packages...
apt-get dist-upgrade -y  > $NULL

info installing curl...
apt-get install curl -y > $NULL

info removing unused packages...
apt-get autoremove -y > $NULL


cd "$TEMPDIR" || warn "cd TEMPDIR failed, please consider writing a bugreport" && exit 1

info installing PiHole...
curl -sSL https://install.pi-hole.net | bash

info installing Unbound...
apt-get install unbound -y > $NULL

info loading hints of DNS rootservers..
wget https://www.internic.net/domain/named.root -qO- | tee $ROOT_HINTS > $NULL

info setting up the unbound configuration file for pihole...
wget $URL/pi-hole.conf -qO- | tee $UNBOUD_CONF > $NULL
sleep 10
service unbound restart > $NULL

info checking if DNS server is set properly
if ! grep -q "PIHOLE_DNS_1=127.0.0.1#5335" "$SETUP_VARS"; then
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
fi

info Please set a new password for the webgui:
warn antes del read
read -r -s -p "> "
warn despues del read
PASSWD=$REPLY
/usr/local/bin/pihole -a -p "$PASSWD"
if [ $? -eq 0 ]; then
    info You are going to need this to log into your webinterface.
else
    echo -e "\n"
    warn Password no set caused by an error.
    warn You may need to set it manually issuing
    warn ""
    warn "           pihole -a -p"
    echo ""
fi


grep autoupdate.sh < /etc/crontab && info Installation finished sucessfully! && exit 0 || info Configuring automatic updates:

wget $URL/autoupdate.sh -qO- | tee $AUTOUPDATE_SCRIPT > $NULL
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
    [1]* ) echo @reboot root ./root/autoupdate.sh >> /etc/crontab && info "selected option [1]";;
    [2]* ) echo "0 1 * * * ./root/autoupdate.sh > /dev/null" >> /etc/crontab && info "selected option [2]";;
    [3]* ) info "selected option [3] \n[info] This requires patching the system manually";;
    * ) echo @reboot root ./root/autoupdate.sh >> /etc/crontab && info "selected default [1]";;
esac

info Installation finished sucessfully!
