#!/bin/bash

SERVER=$1
#BACKUP_SCRIPT='/usr/local/avamar/7.0.0-427/QA_tools/verify_vclient_backup.sh'
BACKUP_SCRIPT='/usr/local/avamar/7.0.0-427/QA_tools/verify_client_bk.sh'
BACKUP_SERVER='voaclivr'
if [[ "$SERVER" == "" ]]
then
	printf "\n\tUsage: $0 SERVER\n\n"
	printf "\tExample: $0 VG1062YR\n\n\n"
	exit 27
fi

VCENTER=`/opt/oquat/qualitycenter/src/Vodafone/Bundle/AcceptanceBundle/Scripts/DECOM/decom.pl $1 | grep "vCenter Name" | head -1 | cut -d: -f2 | sed 's/\ //g'`
if [[ ! "$VCENTER" ]]
then
	VCENTER=`/home/oquat/malex/GET_IDs/get_VCenter.pl $SERVER | head -1  | sed 's/Vcenter//Ig' | sed s/://g | sed 's/ - //g' | tr -s ' ' | sed 's/\ //g'`
fi

if [[ ! "$VCENTER" || "$VCENTER" == "-" ]]
then
	printf "\n$SERVER is not registered on a VCenter\n\n"
	exit 27
fi

ssh -q $BACKUP_SERVER "sudo $BACKUP_SCRIPT -v $VCENTER -c $SERVER"
