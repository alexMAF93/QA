#!/bin/bash


#1 -- ID
#2 -- NAME
#3 -- CRQ


FILES="/home/oquat/malex/TESTAREA"
TEMP="${FILES}/CHK_users/temp_${1}_${2}.txt"
INP="/opt/oquat/qualitycenter/web/files/${3}/${2}_users.txt"
INPUT="/home/oquat/malex/TESTAREA/CHK_users/tmp_${1}_${2}"
DIR=""


if [ $# -lt 2 ]
then
	exit 27
fi



if [ -f /opt/oquat/qualitycenter/data/raw/$1/custreq.raw ]
then
	grep begin_cr_user_group /opt/oquat/qualitycenter/data/raw/$1/custreq.raw 2>&1 >/dev/null && DIR="/opt/oquat/qualitycenter/data/raw/$1/"
fi
if [ -f /opt/oquat/qualitycenter/data/raw/$1/manual/custreq.raw ]
then
	grep begin_cr_user_group /opt/oquat/qualitycenter/data/raw/$1/manual/custreq.raw 2>&1 >/dev/null && DIR="/opt/oquat/qualitycenter/data/raw/$1/manual/"
fi


if [[ "$DIR" == ""  ]]
then
	echo
	echo "NOT_OK: Cannot access custreq.raw"
	echo
	echo "NOT_OK: Please check the raw file"
	echo
	rm  $INPUT $INP
	exit 27
fi


SIZE_OF_INP=`ls -l $INP | awk '{print $5}' || echo 0`
if [ $SIZE_OF_INP -eq 0 ]
then
	rm $INPUT $INP
        exit 27
fi


cat $INP | sed 's/^\ //g' | sed '/^$/d' | tr -s ' ' > $INPUT

CNT=`cat $INPUT | wc -l` # the number of lines of the input file
if [ $CNT -eq 0 ]
then
	printf "N/A: No users requested in ASIC"
	rm  $INPUT $INP
	exit 0
fi


BEGIN=`cat $DIR/custreq.raw | grep -n begin_cr_user_group | cut -d: -f 1` # the line number of the line where users listing begins
END=`cat $DIR/custreq.raw | grep -n end_cr_user_group | cut -d: -f 1` # the line number of the line where users listing ends


cat $DIR/custreq.raw | tail -n +$BEGIN | head -$(($END-$BEGIN+1)) | egrep -v begin_cr_user_group\|end_cr_user_group\|HomeDir | tr -s ' ' ':' > $TEMP



linie=1 # the first user that has to be checked


while [ $linie -le $CNT ] # going through the input file


do # unset some variables


	unset PRIMARY_GROUP
	unset PRIMARY_GROUP1
	unset HOME_DIR
	unset HOME_DIR1
	unset ARRAY_SEC_GRP
	unset ARRAY_SEC_GRP1
	unset SEC_GRP
	unset SEC_GRP1
	DIM_SEC_GRP=0
	DIM_SEC_GRP1=0


	USER=`cat $INPUT | tr -s ' ' | awk NR==$linie'{print $1}'` # the first column of each line represents the user

	if [ -z $USER ] # if the line is empty, increase the counter and continue the loop
	then
		linie=$((linie+1))
		continue
	fi

	TEST_USER=`cat $TEMP | grep -w ^"$USER:" | cut -d: -f 1` # check if the user is on the server

	if [ -z $TEST_USER ] # if it is not on the server, then skip to the next line
	then
		echo -e "The user `cat $INPUT | awk NR==$linie`  should exist on the server ->> NOT_OK" | sed "s/\bno\b//g"
		linie=$((linie+1))
		echo "************************************"
		continue
	fi


	HOME_DIR=`cat $INPUT | tr -s ' ' | awk NR==$linie | cut -d ' ' -f 2 | sed 's/\/$//g'` 
	PRIMARY_GROUP=`cat $INPUT | tr -s ' ' | awk NR==$linie | cut -d ' ' -f 3` 

	HOME_DIR1=`cat $TEMP | grep -w ^"$TEST_USER:" | cut -d: -f 2 | sed 's/\/$//g'` 
	PRIMARY_GROUP1=`cat $TEMP | grep -w ^"$TEST_USER:" | cut -d: -f 3`


	NR_CLM=`cat $INPUT | tr -s ' ' | awk NR==$linie | sed 's/,/ /g' | wc -w` # the number of columns

	if [ $NR_CLM -gt 3 ] # if there are more than 3 columns, it means that the secondary groups need to be checked
	then 
		CNT_GRP=0
		SEC_GRP=`cat $INPUT | awk NR==$linie | cut -d ' ' -f4-$NR_CLM` # add everything after the third column to a variable and appends everything from it to an array 
		for ADD_GRP in $SEC_GRP # the array with the secondary groups from ASIC
		do ARRAY_SEC_GRP[$CNT_GRP]=$ADD_GRP
			CNT_GRP=$((CNT_GRP+1))
		done

		CNT_GRP1=0
		SEC_GRP1=`cat $TEMP | grep -w ^"$TEST_USER:" | cut -d: -f4- | tr ':' ' '` 
		for ADD_GRP1 in $SEC_GRP1 # the secondary groups that are on the server
		do
			ARRAY_SEC_GRP1[$CNT_GRP1]=$ADD_GRP1
			CNT_GRP1=$((CNT_GRP1+1))
		done

		# the number of elements from each array
		DIM_SEC_GRP=`echo ${#ARRAY_SEC_GRP[*]}` 
		DIM_SEC_GRP1=`echo ${#ARRAY_SEC_GRP1[*]}`


		CNT_GRP=0
		while [ $CNT_GRP -le $((DIM_SEC_GRP-1)) ] 
		do

			CNT_GRP1=0
			while [ $CNT_GRP1 -le $((DIM_SEC_GRP1-1)) ] 
			do


				if [[ "${ARRAY_SEC_GRP[$CNT_GRP]}" == "${ARRAY_SEC_GRP1[$CNT_GRP1]}" ]] # if the group is in both arrays, it is deleted from the first array
				then unset ARRAY_SEC_GRP[$CNT_GRP]
					CNT_GRP=$((CNT_GRP+1))
					CNT_GRP1=0
					continue
				fi
				CNT_GRP1=$((CNT_GRP1+1))
			done
				CNT_GRP=$((CNT_GRP+1))
		done
		DIM_SEC_GRP=`echo ${#ARRAY_SEC_GRP[*]}`

	fi


	if [ -z "$PRIMARY_GROUP" ] || [[ "$PRIMARY_GROUP" == "NO" ]]
	then
		PRIMARY_GROUP=$PRIMARY_GROUP1
	fi

	if [ -z "$HOME_DIR" ] || [ "$HOME_DIR" == "LDAP" ] || [ "$HOME_DIR" == "NO" ]
	then
		HOME_DIR=$HOME_DIR1
	fi


	TEST=`echo "$USER $HOME_DIR $PRIMARY_GROUP"` 
	TEST1=`echo "$TEST_USER $HOME_DIR1 $PRIMARY_GROUP1"`


	# weird logic for the tests, needs to be rechecked 
	if [[ "$TEST" == "$TEST1" ]] && [ $DIM_SEC_GRP -eq 0 ]
	then
		echo -e "$TEST1 `echo $SEC_GRP1 | sed 's/ /,/g'` ->> OK"
		linie=$((linie+1))
		continue
	fi



	if [[ "$PRIMARY_GROUP" != "$PRIMARY_GROUP1" ]]
	then
		echo -e "The user $TEST1 `echo $SEC_GRP1 | sed 's/ /,/g'` should have this primary group : $PRIMARY_GROUP ->> NOT_OK"
	fi




	if [[ "$HOME_DIR" != "$HOME_DIR1" ]]
	then
		echo -e "The user $TEST1 `echo $SEC_GRP1 | sed 's/ /,/g'` should have this home directory : $HOME_DIR ->> NOT_OK"
	fi


	if [ $DIM_SEC_GRP -gt 0 ]
	then
		echo -e "The user $TEST1 `echo $SEC_GRP1 | sed 's/ /,/g'` is missing these secondary groups : ${ARRAY_SEC_GRP[*]} ->> NOT_OK"
	fi

	echo "----------------------------------"
	linie=$((linie+1))
done


rm  $INPUT $TEMP $INP
