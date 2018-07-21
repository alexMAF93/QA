#!/bin/bash


for i in `cat list.txt`
do
	SERVER=`echo $i | cut -d'-' -f1`
	ID=`echo $i | cut -d'-' -f2`
	DIR=${SERVER}_${ID}
	if [[ ! -d $DIR ]]
	then
		mkdir $DIR
	fi
	
	for j in `ls | grep -i $SERVER`
	do
		case $j in
		*Linux.raw)
			cat $j > $DIR/os.raw
			;;
		*cr_os.raw)
			cat $j > $DIR/custreq.raw
			;;
		*whoami.raw)
			cat $j > $DIR/whoami.raw
			;;
		esac
	done
	zip ${SERVER}.zip ${DIR}/*
done
