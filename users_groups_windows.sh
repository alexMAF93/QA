#!/bin/bash


RAW=/opt/oquat/qualitycenter/data/raw
OUTPUT=/home/oquat/malex/CHK_users/windows.temp


if [[ "$1" == "" || "$2" == "" ]]
then
	printf "\tusage: $0 TESTITEM_ID users/groups\n"
	exit 27
fi


[[ -s $RAW/$1/bladelogic.raw ]] && FILE=$RAW/$1/bladelogic.raw
[[ -s $RAW/$1/manual/bladelogic.raw ]] && FILE=$RAW/$1/manual/bladelogic.raw


if [ ! -f $FILE ]
then
	printf "bladelogic.raw does not exist\n"
	exit 27
fi


case "$2" in
	users) 
		START_LINE=`cat $FILE | grep -n begin_win_net_user | cut -d: -f 1 | head -1`
		END_LINE=`cat $FILE | grep -n end_win_net_user | cut -d: -f 1 | head -1`
	;;
	groups)
		START_LINE=`cat $FILE | grep -n begin_win_net_localgroup | cut -d: -f 1 | head -1`
		END_LINE=`cat $FILE | grep -n end_win_net_localgroup | cut -d: -f 1 | head -1`
	;;
esac


cat $FILE | tail -n +"$START_LINE" | head -n $((END_LINE-START_LINE+1)) > $OUTPUT


printf "List the $2 you want to check:\n"
LIST=`cat`

clear
cat $FILE | grep Hostname | cut -d: -f 2
printf "\n"
for i in $LIST
do
	if `grep -qwi $i $OUTPUT`
	then
		printf "%-30s %-30s\n" "$i" "--> OK"
	else
		printf "%-30s %-30s\n" "$i" "--> the user does not exist on the server"
	fi
done


rm $OUTPUT
