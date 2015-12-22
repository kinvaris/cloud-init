#!/bin/bash

#Title: Open vInstaller
#Author: Jonas Libbrecht
#Version: 3.0

#
## FETCH GENERAL PARAMETERS
#

#for output reasons
RED='\033[0;31m'
NC='\033[0m' # No Color
BLUE='\033[0;34m'
GREEN='\033[0;32m'

#parameters
username="root"
password="rooter"
repo_url="http://apt.openvstorage.org"
ovs_version="eugene"
ovs_package="openvstorage-hc" #openvstorage-hc or openvstorage
ovs=true #start auto install ovs
contrail=false #use of opencontrail in setup

#
## CHANGE DEFAULT PARAMETERS IF REQUIRED
#

# store arguments in a special array 
args=("$@")
# get number of elements 
ELEMENTS=${#args[@]}

# fetch params from args
for ((i=0;i<$ELEMENTS;i++)); do
	#create temp var
	j=$i
	case "${args[${i}]}" in
		"-v"|"--version")
			ovs_version=${args[${j}+1]}
			;;
		"-u"|"--url")
			repo_url=${args[${j}+1]}
			;;
		"-r"|"--package")
			ovs_package=${args[${j}+1]}
			;;
		"-p"|"--password")
			password=${args[${j}+1]}
			;;
		"-C"|"-B"|"--contrail"|"--nobridge")
			contrail=true
			;;
		"-S"|"--nosetup")
			ovs=false
			;;
		"--help")
		
			#
			## MAN PAGE
			#
		
			printf "${BLUE}Welcome to help page: ${NC}"
			echo " "
			echo "-p or --password supersecretpass = use alternative password (optional) (DEFAULT=$password) "
			echo "-v or --version chicago-community or denver = use alternative password (optional) (DEFAULT=$ovs_version) "
			echo "-u or --url http://apt.openvstorage.org = use alternative password (optional) (DEFAULT=$repo_url) "
			echo "-r or --package openvstorage = use alternative password (optional) (DEFAULT=$ovs_package) "
			echo "-B, -C, --nobridge or --contrail = do not check for local bridge (optional) (DEFAULT=check for bridge)"
			echo "-S or --nosetup = do not start ovs installation automatically (optional) (DEFAULT=autostart ovs installation)"
			echo "--help = display this help page"
			exit
			;;
        esac
done

printf "${BLUE}Done setting-up variables${NC}\n"

#
## Start of actual setup
#

if [ "$contrail" = false ] ; then
    if grep -q br0 /etc/network/interfaces; then
        printf "${GREEN}Found a bridge (br0) in the /etc/network/interfaces config, installation will continue...!${NC}"
    else
        printf "${RED}NO bridge (br0) was found in /etc/network/interfaces config, please run operations/openstack_ovs_project/controller/install/add_controller_bridge.sh script or check the /etc/network/interfaces for mistakes${NC}"
        exit
    fi
else
    printf "${GREEN}Continuing without checking for local bridge, because Open Contrail uses hook...${NC}"
    echo ""
fi

#Installing virtualization packages and others...
printf "${BLUE}Installing needed packages${NC}\n"
sudo apt-get update
sudo apt-get install -y --force-yes kvm libvirt0 python-libvirt virtinst libvirt-bin virt-manager ntp htop nload vim git byobu smartmontools mc fping qemu-utils genisoimage

#prepare the compute for installation
printf "${BLUE}Changing root remote permissions${NC}\n"
sudo sed -i '/PermitRootLogin/s/ .*/ yes/' /etc/ssh/sshd_config
sudo sed -i '/PasswordAuthentication/s/ .*/ yes/' /etc/ssh/sshd_config

#changing root password to rooter
printf "${BLUE}Changing root password to: $password${NC}\n"
sudo echo -e "$password\n$password" | passwd $username

printf "${BLUE}Optimizing VM configs for OVS installation${NC}\n"
#Decrease the swapiness of the OS
sudo echo 1 > /proc/sys/vm/swappiness
sudo echo "vm.swappiness=1" >> /etc/sysctl.conf

#Update the VM dirty_background_bytes
sudo echo "134217728" > /proc/sys/vm/dirty_background_bytes
sudo echo "vm.dirty_background_bytes = 134217728" >> /etc/sysctl.conf

#add ovs apt-repo
printf "${BLUE}Getting OVS packages and installing it ${RED}(configure incoming...)${NC}\n"
rm -f /etc/apt/sources.list.d/ppa-tcpcloud-openvstorage.list
rm -f /etc/apt/sources.list.d/openvstorage.list
rm -f /etc/apt/sources.list.d/ovsaptrepo.list
echo "deb $repo_url $ovs_version main" > /etc/apt/sources.list.d/ovsaptrepo.list

#install (NOT CONFIGURE) ovs
sudo apt-get update
sudo apt-get install -y --force-yes -t $ovs_version $ovs_package

#configure ovs
if [ "$ovs" = true ] ; then
    printf "${GREEN}Starting configuration of ovs... ${NC}\n"
    sudo ovs setup
else
    printf "${RED}Installation has ended WITHOUT configuration of OVS LIKE DESIRED... ${NC}\n"
    exit
fi
