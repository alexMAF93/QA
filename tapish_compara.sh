#!/bin/bash


SOURCE=list_of_items.txt
SYS=items_from_CRQ.txt


for i in `cat items_from_CRQ.txt | cut -d'-' -f 1`
do
	if [[ ! `grep -iw ^$i $SOURCE` ]]
 	then 
		printf "$i --> NOT FOUND\n"
		continue
	fi
	cnt=0
	cnt_ip=0


	SYS_CPUs=`cat $SOURCE | grep -iw ^$i | head -1 | awk '{print $3}'`
	SYS_RAM_raw=`cat $SOURCE | grep -iw ^$i | head -1 | awk '{print $2}'`
	SYS_IPs=`cat $SOURCE | grep -iw ^$i | head -1 | awk '{for(j=4;j<=NF;++j)print $j}'`
	[[ $SYS_RAM_raw ]] && SYS_RAM=$((SYS_RAM_raw/1024))


	DOC_CPUs=`cat $SYS | grep -iw ^$i | head -1 | cut -d '-' -f 2`
	DOC_RAM=`cat $SYS | grep -wi ^$i | head -1 | cut -d '-' -f 4`
	DOC_IP=`cat $SYS | grep -wi ^$i | head -1 | cut -d '-' -f5 | sed 's/-//g'`


	printf '=%.0s' {1..30};	printf '\n'
	printf "Configuration Item: $i\n\n"


	if [[ $DOC_CPUs -eq $SYS_CPUs ]]
	then
		cnt=$((cnt+1))
	else
		printf "The number of CPUs is wrong: Documented: $DOC_CPUs ; Configured: $SYS_CPUs\n"
	fi


	if [[ $DOC_RAM -eq $SYS_RAM ]]
	then
		cnt=$((cnt+1))
	else
		printf "The amount of RAM is wrong: Documented: $DOC_RAM ; Configured: $SYS_RAM\n"
	fi


	for IP in `echo $SYS_IPs | sed 's/,//g'`
	do
		if [[ "$IP" == "$DOC_IP" ]]
		then
			cnt_ip=$((cnt_ip+1))
		fi
	done
	if [[ $cnt_ip -eq 0 ]]
	then
		printf "The IP address is wrong: Documented: $DOC_IP ; Configured: `echo $SYS_IPs | tr '\n' ' '`\n"
	else
		cnt=$((cnt+cnt_ip))
	fi


	if [[ $cnt -eq 3 ]]
	then
		printf "Name: $i, CPUs: $DOC_CPUs, RAM: $DOC_RAM, IP: $DOC_IP -->> OK\n"
	fi


	printf '=%.0s' {1..30};	printf '\n'

done
