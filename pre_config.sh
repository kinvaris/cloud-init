#!/bin/bash

#Title: OVS-config-seeder
#Description: Installer for the desired OVS pre_config
#Author: Jonas Libbrecht
#Version: 2 (compatible with OVS Eugene)

#for output reasons
RED='\033[0;31m'
NC='\033[0m' # No Color
BLUE='\033[0;34m'
GREEN='\033[0;32m'

#
## FETCH GENERAL PARAMETERS
#

#General information of local node
IP="$(ip a | grep $1 | grep inet | cut -d " " -f 6 | cut -d "/" -f 1)"
USER="root"
PASSWORD="rooter" #password also used to connect to others nodes IF JOIN_CLUSTER=True
OVS_MASTER="True" #True or False (recommendation: 3 ovs master nodes in 1 cluster)

#Cluster information
CLUSTER_NAME=$2
JOIN_CLUSTER="False" #True or False
MASTER_IP=$IP

#Local hypervisor information
HYPERVISOR_TYPE="KVM" #KVM OR VMWARE
HYPERVISOR_NAME="${HYPERVISOR_TYPE,,}$(echo $IP | cut -d "." -f 4)"

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
        "-p"|"--password")
                PASSWORD=${args[${j}+1]}
                ;;
        "-M"|"--nomaster")
                OVS_MASTER="False"
                MASTER_IP=${args[${j}+1]}
		JOIN_CLUSTER="True"
                ;;
	"-j"|"--joincluster")
		MASTER_IP=${args[${j}+1]}
		JOIN_CLUSTER="True"
		;;
	"-t"|"--type")
		HYPERVISOR_TYPE=${args[${j}+1]}
		;;
	"-n"|"--name")
		HYPERVISOR_NAME=${args[${j}+1],,}
		;;
	"--help")
	
		#
		## MAN PAGE
		#
	
		printf "${BLUE}Welcome to help page: ${NC}"
		echo " "
		echo "\$1 (first parameter) = interface where OVS will be installed (required)"
		echo "\$2 (second parameter) = ovs cluster name (required)"
		echo "-p or --password supersecretpass = use alternative password (optional) (DEFAULT=rooter) "
		echo "-M or --nomaster 0.0.0.0 = defined when extra node is needed, when this is selected you do not need --joincluster because extra nodes can't do stand-alone (optional) (DEFAULT=True)"
		echo "-j or --joincluster 0.0.0.0 = defined when a node is in need to join a existing custer (optional) (DEFAULT=False)"
		echo "-t or --type KVM = defined when another hypervisor is used than the default (optional) (DEFAULT=KVM, OTHER(S)=VMWARE)"
		echo "-n or --name awesomehypervisorname = defined when in need of other hypervisor name (optional) (DEFAULT=HYPERVISOR_TYPE + last number of hosts IP address)"
		echo "--help = display this help page"
		exit
		;;
        esac
done

printf "${BLUE}Done setting-up variables${NC}\n"

#
## Creation of actual preconfig
#

printf "${BLUE}Creating OVS preconfig${NC}\n"

cat << EOF > /tmp/openvstorage_preconfig.cfg
[setup]
target_ip = $IP
target_password = $PASSWORD
cluster_name = $CLUSTER_NAME
cluster_ip = $IP
master_ip = $MASTER_IP
master_password = $PASSWORD
join_cluster = $JOIN_CLUSTER
disk_layout = None #deprecated from chicago
hypervisor_type = $HYPERVISOR_TYPE
hypervisor_name = $HYPERVISOR_NAME
hypervisor_ip = $IP
hypervisor_username = $USER
hypervisor_password = $PASSWORD
auto_config = True
verbose = True
configure_memcached = $OVS_MASTER
configure_rabbitmq = $OVS_MASTER
EOF

#
## Exiting ...
#

printf "${GREEN}Done...${NC}\n"
