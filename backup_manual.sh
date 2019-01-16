#!/bin/bash


SERVER=$1
OPTION=$2


networker_check() {

echo "Is the backup enabled in Networker ?"
nsr_clientres | grep -i $SERVER | grep -i Enabled || echo "Backup not enabled in Networker!"
echo =================

}


reference_check() {

echo "Is the server present in the reference.txt file ?"
cat /opt/networker/scripts/reporting/t03/lists/reference.txt | grep -i $SERVER || echo "The server is not present in reference.txt"
echo =================

}


restore_check() {

echo "Restore test for $SERVER"
recover -c $SERVER -R $SERVER  -iR -a /nsr/res/nsrladb -d /tmp/Restore
echo =================

}


_check() {

networker_check
reference_check
restore_check

}


start_checks () {

if [[ `echo $OPTION | egrep -q "^restore$|^reference$|^networker$"; echo $?` == 0 || "$OPTION" == "" ]]
then
	${OPTION}_check
else
	echo "Invalid option"
	usage
fi

}


usage() {

echo "Usage: $0 SERVER [OPTION]"
echo "OPTION can be:"
echo "networker ->> check if the server is enabled in Networker"
echo "reference ->> check if the server is present in reference.txt file"
echo "restore ->> perform a restore test"
echo "If no option is specified, it's assumed that all tests are required"
echo "Call this script on the backup master as root. You can copy it with this command"
echo "scp $0 scp BACKUP_MASTER:"
exit 7

}


if [[ "$SERVER" == "" ]]
then
	usage
fi


echo =================
echo $SERVER
echo =================


start_checks

