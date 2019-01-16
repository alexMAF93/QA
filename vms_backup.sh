#!/bin/bash


usage() {
cat <<EOF
	Usage: $0 CRQ_ID
EOF
exit 7
}

if [[ ! $1 ]]
then
	usage
fi


CRQ_ID=$1
QUERY=/home/oquat/malex/my_query.pl
CRQ=`$QUERY "select NAME from CRQ where ID = ${CRQ_ID}" | cut -d' ' -f1`
CRQ_DIR=/opt/oquat/qualitycenter/web/files/${CRQ}
BACKUP_FILE=${CRQ_DIR}/backup_proof.txt
BACKUP_FILE_temp=${CRQ_DIR}/backup_proof_1.txt
BACKUP_SCRIPT=/home/oquat/malex/backup_VMs.sh
VMs=`$QUERY "select NAME from TESTITEM where CRQ_ID = ${CRQ_ID} and TIER2_ID in ('3', '40', '39', '6', '7', '8', '9', '22', '23', '24', '78', '100', '26', '27', '28', '29', '30', '31', '88', '89', '13', '14', '15', '87', '1063') ORDER BY NAME ASC" | cut -d'|' -f 1`


if [[ -s $BACKUP_FILE ]]
then
	> $BACKUP_FILE
fi


for i in $VMs
do
	echo "Now working on ${i}..."
	echo "================" >> "$BACKUP_FILE_temp"
	echo "$i" >> "$BACKUP_FILE_temp"
	echo "================" >> "$BACKUP_FILE_temp"
	timeout -s 9 5m $BACKUP_SCRIPT $i >> "$BACKUP_FILE_temp"
	echo "================" >> "$BACKUP_FILE_temp"
	printf "\n\n\n" >> "$BACKUP_FILE_temp"
        IS_FAILED=`grep -c "found ..* successfull" $BACKUP_FILE_temp | cut -d':' -f1 || echo 0`
	cat "$BACKUP_FILE_temp" >> "$BACKUP_FILE"
	if [[ $IS_FAILED -gt 0 ]]
	then
		echo "... Successful backup has been found ..."
        else
		echo "... The backup has FAILED ..."
	fi
        printf "\n"
	rm "$BACKUP_FILE_temp"
done


unix2dos "$BACKUP_FILE" 
