#!/usr/bin/env sh
TMP=/tmp/installation.sh

# URL of install script
URL=https://raw.githubusercontent.com/MarcMocker/PiHole_in_LXC/main/install

if [ "$(uname)" != "Linux" ]; then
  echo "OS NOT SUPPORTED"
  exit 1
fi

DISTRO=$(cat /etc/*-release | grep -w ID | cut -d= -f2 | tr -d '"')
if [ "$DISTRO" != "ubuntu" ]; then
  echo "DISTRO NOT SUPPORTED"
  exit 1
fi

rm -rf $TMP
wget -O "$TMP" "$URL/$DISTRO.sh"

chmod +x "$TMP"

# the pihole command is located in /usr/local/bin
export PATH="/usr/local/bin:$PATH"
echo export PATH='/usr/local/bin:$PATH' >> $HOME/.bashrc

if [ "$(command -v bash)" ]; then
  sudo bash "$TMP"
fi
