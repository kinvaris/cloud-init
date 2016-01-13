#!/bin/bash

sudo apt-get install -y --force-yes kvm libvirt0 python-libvirt virtinst ntp

sudo sed -i '/PermitRootLogin/s/ .*/ yes/' /etc/ssh/sshd_config
sudo sed -i '/PasswordAuthentication/s/ .*/ yes/' /etc/ssh/sshd_config
sudo echo 1 > /proc/sys/vm/swappiness
sudo echo "vm.swappiness=1" >> /etc/sysctl.conf
sudo echo "134217728" > /proc/sys/vm/dirty_background_bytes
sudo echo "vm.dirty_background_bytes = 134217728" >> /etc/sysctl.conf

echo "deb http://apt.openvstorage.org eugene-updates main" > /etc/apt/sources.list.d/ovsaptrepo.list

sudo apt-get update
sudo apt-get install -y --force-yes -t eugene-updates openvstorage-hc
