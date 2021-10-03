#!/usr/bin/env bash

set -euo pipefail

function info { echo -e "\e[32m[info] $*\e[39m"; }
function warn { echo -e "\e[33m[warn] $*\e[39m"; }

TEMPDIR=$(mktemp -d)
NULL=/dev/null
URL=https://raw.githubusercontent.com/MarcMocker/PiHole_in_LXC/main/install
UNBOUD_CONF=/etc/unbound/unbound.conf.d/pi-hole.conf
SETUP_VARS=/etc/pihole/setupVars.conf
ROOT_HINTS=/var/lib/unbound/root.hints
AUTOUPDATE_SCRIPT=/root/autoupdate.sh


info updating dependencies...
apt-get update > $NULL

info updating installed packages...
apt-get dist-upgrade -y  > $NULL

info removing unused packages...
apt-get autoremove -y > $NULL


cd $TEMPDIR

info installing PiHole...
curl -sSL https://install.pi-hole.net | bash

info installing Unbound...
apt-get install unbound -y > $NULL

info loading hints of DNS rootservers..
wget https://www.internic.net/domain/named.root -qO- | sudo tee $ROOT_HINTS > $NULL

info setting up the unbound configuration file for pihole...
wget $URL/pi-hole.conf -qO- | sudo tee $UNBOUD_CONF > $NULL
service unbound restart > $NULL

info setting unbound as only DNS server...
if [ ! -f "$SETUP_VARS" ]; then
    warn setupVars.conf not available
    exit 1
fi
LINE_DNS_1=$(grep -n "PIHOLE_DNS_1" $SETUP_VARS | cut -d: -f1)
LINE_DNS_2=$(grep -n "PIHOLE_DNS_2" $SETUP_VARS | cut -d: -f1)
sed "${LINE_DNS_1}s/.*/PIHOLE_DNS_1=127.0.0.1#5335/g" $SETUP_VARS > $NULL
sed "${LINE_DNS_2}s/.*/PIHOLE_DNS_2=/g" $SETUP_VARS > $NULL

warn Please set a new password for the webgui running: pihole -a -p
# the pihole command is located in /usr/local/bin
export PATH="/usr/local/bin:$PATH"
echo export PATH='/usr/local/bin:$PATH' >> $HOME/.bashrc

info Configuring automatic updates:
wget $URL/autoupdate.sh -qO- | sudo tee $AUTOUPDATE_SCRIPT > $NULL
chmod +x $AUTOUPDATE_SCRIPT

info Please set a new update policy:
while true; do
    read -p "Do you wish to automatically update on boot [b], daily [d] or nothing of those [n]?" bpn
    case $bpn in
        [Bb]* ) echo @reboot root ./root/autoupdate.sh >> /etc/crontab; break;;
        [Dd]* ) echo "0 1 * * * ./root/autoupdate.sh > /dev/null" >> /etc/crontab; break;;
        [Nn]* ) warn Then you may setup a cronjob manually to ensure your system keeps patched.; break;;
        * ) echo "Please answer boot, periodically or nothing.";;
    esac
done
