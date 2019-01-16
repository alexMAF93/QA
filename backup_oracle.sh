#!/bin/bash

if [[ -z $1 ]]
then
printf "\n\n\n\tusage: $0 SERVER DATABASE BACKUP_MASTER\n\n"
else

SERVER=$1
BAZA=$2
BKPMASTER=$3
ALEGERE=$4
DATA=`date +"%Y%m"`


if [[ "$4" == "" ]]
then

echo "Alege din optiunile de mai jos: "
echo "1) Successful backup"
echo "2) Entry in reference.txt"
echo "3) Entry in Networker"
echo -n "->>"
read optz

case $optz in
1)ssh $BKPMASTER "cat /opt/networker/scripts/reporting/t02/reports/*$DATA* | grep -i $BAZA | head -15" 2>/dev/null;;
2)ssh $BKPMASTER "cat /opt/networker/scripts/reporting/t03/lists/reference.txt | grep -i $BAZA || echo \"$BAZA not found in reference.txt\"" 2>/dev/null;;
3)ssh $BKPMASTER "/opt/networker/admincmd/nsr_clientres | grep -i $SERVER" 2>/dev/null;;


esac


else
case $4 in
1)ssh $BKPMASTER "cat /opt/networker/scripts/reporting/t02/reports/*$DATA* | grep -i $BAZA | head -15" 2>/dev/null;;
2)ssh $BKPMASTER "cat /opt/networker/scripts/reporting/t03/lists/reference.txt | grep -i $BAZA || echo \"$BAZA not found in reference.txt\"" 2>/dev/null;;
3)ssh $BKPMASTER "/opt/networker/admincmd/nsr_clientres | grep -i $SERVER" 2>/dev/null;;


esac

fi

fi
