#!/bin/bash


usage ()
{
cat <<EOF
Usage:
	$0 CRQ_ID 
EOF
}

CRQ_ID=$1


if [[ ! "$CRQ_ID" ]] || [[ $# -gt 1 ]]
then
	usage
	exit 0
fi


for i in `/home/oquat/malex/getIDs.pl $CRQ_ID | cut -d' ' -f2`
do
	qcsh /home/oquat/malex/QCScripts/users.qcs --testitemid=$i
	echo
done
