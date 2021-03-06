#!/usr/bin/env bash

# GENERAL PURPOSE LOGGING FUNCTIONS
function info {
    echo -e "\e[32m[info] $*\e[39m";
}
function info-log {
    echo -e "\e[32m[info] $*\e[39m";
    echo -e "\e[32m[info] $*\e[39m" >> $LOG;
}
function success {
    echo -e "\e[32m[done] $*\e[39m";
    echo -e "\e[32m[done] $*\e[39m" >> $LOG;
    exit 0;
}
function warn {
    echo -e "\e[33m[warn] $*\e[39m";
    echo -e "\e[33m[warn] $*\e[39m" >> $LOG;
}
function error {
    echo -e "\e[31m[error] $*\e[39m";
    echo -e "\e[31m[error] $*\e[39m" >> $LOG;
    exit 1;
}

# VARS
LOG=/root/.log/install.log
NULL=/dev/null
URL=https://raw.githubusercontent.com/MarcMocker/PiHole_in_LXC/main/install
UNBOUD_CONF=/etc/unbound/unbound.conf.d/pi-hole.conf
SETUP_VARS=/etc/pihole/setupVars.conf
ROOT_HINTS=/var/lib/unbound/root.hints
AUTOUPDATE_SCRIPT=/root/autoupdate.sh
TMP=/tmp
ADD_BLOCKLISTS=/add_blocklists.sh

# SCRIPT-CONTENT RELATED FUNCTIONS
function setup_autoupdate {
    info-log Configuring automatic updates:

    wget $URL/autoupdate.sh -qO- | tee $AUTOUPDATE_SCRIPT >> $LOG
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
        [1]* ) echo @reboot root /root/autoupdate.sh >> /etc/crontab && info-log "selected option [1]";;
        [2]* ) echo "0 1 * * * /root/autoupdate.sh > /dev/null" >> /etc/crontab && info-log "selected option [2]";;
        [3]* ) info-log "selected option [3] \n[info] This requires patching the system manually";;
        * ) echo @reboot root /root/autoupdate.sh >> /etc/crontab && info-log "selected default [1]";;
    esac
}

# CODE
mkdir /root/.log

clear

info-log updating dependencies...
apt-get update >> $LOG

info-log updating installed packages...
apt-get dist-upgrade -y  >> $LOG

info-log installing dependencies...
apt-get install curl wget git -y >> $LOG

info-log removing unused packages...
apt-get autoremove -y >> $LOG


info-log installing PiHole...
curl -sSL https://install.pi-hole.net | bash
cat /etc/pihole/install.log >> $LOG

clear
info updating dependencies...
info updating installed packages...
info installing dependencies...
info removing unused packages...
info installing PiHole...

info-log installing Unbound...
apt-get install unbound -y >> $LOG

info-log loading hints of DNS rootservers...
wget https://www.internic.net/domain/named.root -qO- | tee $ROOT_HINTS >> $LOG

info-log setting up the unbound configuration file for pihole...
wget $URL/pi-hole.conf -qO- | tee $UNBOUD_CONF >> $LOG
sleep 10
service unbound restart >> $LOG

info-log checking if DNS server is set properly
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
    info-log DNS set correctly
fi

info-log Please set a new password for the webgui:

read -r -s -p "> "

PASSWD=$REPLY
/usr/local/bin/pihole -a -p "$PASSWD"
if [ $? -eq 0 ]; then
    info New password set correctly  >> $LOG
    info-log You are going to need this to log into your webinterface.
else
    warn Password no set caused by an error.  >> $LOG
    echo -e "\n"
    warn Password no set caused by an error.
    warn You may need to set it manually issuing:
    warn ""
    warn "           pihole -a -p"
    echo ""
fi


grep autoupdate.sh < /etc/crontab > $NULL || setup_autoupdate


info-log ""
info-log Installation finished sucessfully!
info-log ""

echo ""

info-log Do you like to preset blocklists? [Y/n]
read -r -p "> "
case $REPLY in
    [Nn]* ) success "terminating installer...";;
    * ) info-log Starting script... && wget -O "$TMP/$ADD_BLOCKLISTS" "$URL/$ADD_BLOCKLISTS" && bash $TMP/$ADD_BLOCKLISTS;;
esac
