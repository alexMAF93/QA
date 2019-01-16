#!/bin/bash
BAZE=/home/oquat/malex/BAZE/baze
> $BAZE


if [[ "$1" == "" ]]
then
	printf "\n\n\tusage: $0 SERVER1 [SERVER2...n]\n\n"
	exit 27
fi


h=`echo $@ | sed 's/,/ /g' | sed 's/\&/ /g' | tr -s ' ' | tr [a-z] [A-Z]`

for i in $h
do
	ssh -q $i ps -ef | grep pmon | tr -s " " | cut -d " " -f 8 | sed s/^/"==========>>>> "/g | sed s/"ora_pmon_"//g | sed s/"asm_pmon_"//g >> ${BAZE}_${i} 2>/dev/null
	sleep 1
done


clear
for i in $h
do
	echo $i
	cat ${BAZE}_${i} | egrep -v "+ASM"\|"pmon" | sort -u
	echo
done


rm ${BAZE}*
