#!/usr/bin/env bash

sleep 180
apt-get update >> /tmp/cron_after_reboot
apt-get dist-upgrade -y >> /tmp/cron_after_reboot
apt-get autoremove -y >> /tmp/cron_after_reboot
pihole -up >> /tmp/cron_after_reboot
pihole updateGravity >> /tmp/cron_after_reboot
