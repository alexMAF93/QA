#!/bin/bash

#1 -- ID
#2 -- NAME
#3 -- CRQ
#4 -- TYPE: FS,CIFS,SAN


FILES="/home/oquat/malex/TESTAREA"
TEMP="${FILES}/FS_chk/temp.txt_${1}_${2}_${4}" # custreq.raw
INPUT="${FILES}/FS_chk/inp.txt_${1}_${2}_${4}" # ASIC without weird spacing



case $4 in
	"FS")
		INP=/opt/oquat/qualitycenter/web/files/"$3"/"$2"_localfs.txt
	;;
	"SAN")
		INP=/opt/oquat/qualitycenter/web/files/"$3"/"$2"_"$4".txt
	;;
	"CIFS")
		INP=/opt/oquat/qualitycenter/web/files/"$3"/"$2"_"$4".txt
	;;
	*)
		INP="WTF"
	;;
esac


if [ ! -s $INP ]
then
	printf "NOT_APPLICABLE: The input file is empty!\n"
	rm $TEMP $INPUT
	exit 7
fi


if [[ "$INP" == "WTF" ]]
then
	printf "\nOption not recognised\n"
	exit 1
fi


if [ -f /opt/oquat/qualitycenter/data/raw/$1/custreq.raw ]
then
	grep begin_cr_user_group /opt/oquat/qualitycenter/data/raw/$1/custreq.raw 2>&1 >/dev/null && DIR="/opt/oquat/qualitycenter/data/raw/$1/"
fi
if [ -f /opt/oquat/qualitycenter/data/raw/$1/manual/custreq.raw ]
then
	grep begin_cr_user_group /opt/oquat/qualitycenter/data/raw/$1/manual/custreq.raw 2>&1 >/dev/null && DIR="/opt/oquat/qualitycenter/data/raw/$1/manual/"
fi


if [[ "$DIR"  == "" ]]
then
	echo
	echo "ERROR : custreq.raw --- corrupt file"
	echo
	rm $TEMP $INPUT
	exit 7
fi


SIZE_OF_INP=`ls -l $INP | awk '{print $5}' || echo 0`
if [ $SIZE_OF_INP -eq 0 ]
then
	echo "NOT_APPLICABLE"
	rm $TEMP $INPUT
	exit 27
fi


cat $INP | sed 's/^\ //g' | sed '/^$/d' | tr -s ' ' | tr ' ' ':' > $INPUT




#### Functions

# Converts the permissions into octal mode
function PERMSS() {
TEST=$1
PERM=0
for i in 9 6 3
do
u1=${TEST:$i:1}
if [[ "$u1" == "x" ]] || [[ "$u1" == "t" ]] || [[ "$u1" == "s" ]]
then
u1=1
else
u1=0
fi

u2=${TEST:$((i-1)):1}
if [[ "$u2" == "w" ]]
then
u2=2
else
u2=0
fi

u3=${TEST:$((i-2)):1}
if [[ "$u3" == "r" ]]
then
u3=4
else
u3=0
fi

if [ $i -eq 9 ]
then
PERM1=$((u1+u2+u3))
fi

if [ $i -eq 6 ]
then
PERM1=$((PERM1+10*u1+10*u2+10*u3))
fi

if [ $i -eq 3 ]
then
PERM1=$((PERM1+100*u1+100*u2+100*u3))
fi
done
echo $PERM1
}

# Checks if the size of the partitions varies with more than 10% 
function SIZES() {
	DIM=$1
	DIM_ASIC1=$(echo "scale=2; 100*$DIM" | bc)
	DIM_ASIC=`echo $DIM_ASIC1 | cut -d '.' -f 1`
	VAR=$2
	var1=$(echo "scale=2; 100*$VAR" | bc)
	var=`echo $var1 | cut -d '.' -f 1`
	if [ $var -ge $((DIM_ASIC-DIM_ASIC/10)) ] && [ $var -le $((DIM_ASIC+DIM_ASIC/10)) ] 
	then
		echo "OK"
	else
		echo "NOT_OK"
	fi
}

#### 


if [ -z $1 ]
then
	echo
	echo "Usage : ./fs_check.sh_individual TEST_ITEM_ID1 ..."
	echo
	exit 27
fi




CNT=`cat $INPUT | wc -l` # the number of lines = the number of mount points that have to be checked
if [ $CNT -eq 0 ]
then
        printf "NOT_APPLICABLE"
	rm $TEMP $INPUT
        exit 0
fi

if [[ `cat $INPUT | wc -l` -eq 1 && `cat $INPUT | cut -d: -f1` == "N/A" ]]
then
	printf "NOT_APPLICABLE"
	rm $TEMP $INPUT
	exit 0
fi


# gets line number for the lines that have the filesystems between them and appends the filesystems to $TEMP
BEGIN=`cat $DIR/custreq.raw | grep -n begin_cr_local_fs | cut -d: -f 1 | head -1` # the line number of the line where the local filesystems listing begins
END=`cat $DIR/custreq.raw | grep -n end_cr_local_fs | cut -d: -f 1 | head -1` # the line number of the line where the local filesystems listing ends
echo "LOCALFS" > $TEMP
cat $DIR/custreq.raw | tail -n +$BEGIN | head -$(($END-$BEGIN+1)) | egrep -v begin_cr_local_fs\|end_cr_local_fs\|"Permissions" | tr -s ' ' ':'| sed s/"\."$//g >> $TEMP 
BEGIN=`cat $DIR/custreq.raw | grep -n begin_cr_san_fs | cut -d: -f 1 | head -1`
END=`cat $DIR/custreq.raw | grep -n end_cr_san_fs | cut -d: -f 1 | head -1`
echo "SANFS" >> $TEMP
cat $DIR/custreq.raw | tail -n +$BEGIN | head -$(($END-$BEGIN+1)) | egrep -v begin_cr_san_fs\|end_cr_san_fs\|"Permissions" | tr -s ' ' ':' | sed s/"\."$//g >> $TEMP
BEGIN=`cat $DIR/custreq.raw | grep -n begin_cr_nfs_cifs | cut -d: -f 1 | head -1`
END=`cat $DIR/custreq.raw | grep -n end_cr_nfs_cifs | cut -d: -f 1 | head -1`
echo "NFSCIFS" >> $TEMP
cat $DIR/custreq.raw | tail -n +$BEGIN | head -$(($END-$BEGIN+1)) | egrep -v begin_cr_nfs_cifs\|end_cr_nfs_cifs\|"Permissions"\|^"No" | tr -s ' ' ':' | sed s/"\."$//g >> $TEMP


# the line number of the line that is followed by the filesystem
LOCALFS=`cat $TEMP | cut -d: -f 1 | grep -nx "LOCALFS" | cut -d: -f 1` 
SANFS=`cat $TEMP | cut -d: -f 1 | grep -nx "SANFS" | cut -d: -f 1`
NFSCIFS=`cat $TEMP | cut -d: -f 1 | grep -nx "NFSCIFS" | cut -d: -f 1`


# the first line represents the first mount point that must be verified
linie=1


while [ $linie -le $CNT ]
do
	#unset some variables
		unset SIZE
		unset OWNER
		unset GROUP
		unset PERMS
		unset SIZE1
		unset OWNER1
		unset GROUP1
		unset PERMISS1
		
		
	# on each line this is the meaning of the entries : mount point, size of the partition, owner, group, permissions
	NR_LITERE=`cat $INPUT | awk NR==$linie | cut -d: -f 1 | wc -c`


	if [ $NR_LITERE -eq 2 ]
	then 
		M_P=`cat $INPUT | awk NR==$linie | cut -d: -f 1`
	else 
		M_P=`cat $INPUT | awk NR==$linie | cut -d: -f 1 | sed "s/\/$//g"` 
	fi


	SIZE=`cat $INPUT | awk NR==$linie | cut -d: -f 2 | sed s/G//g` 
	OWNER=`cat $INPUT | awk NR==$linie | cut -d: -f 3` 
	GROUP=`cat $INPUT | awk NR==$linie | cut -d: -f 4` 
	PERMS=`cat $INPUT | awk NR==$linie | cut -d: -f 5` 
	if [[ "${PERMS:0:1}" == "d" ]]
	then
		PERMS=`PERMSS $PERMS`
	fi


	# the number of the line where the mount point from the ASIC is in the file with data from custreq.raw
	LINIE=`cat $TEMP | cut -d: -f 1 | grep -nx "$M_P" | cut -d: -f 1 | head -1`


	# if the mount point does not exists, the counter increases and the loop continues

	if [ -z $LINIE ]
	then
		echo -e "The mount point $M_P $SIZE $OWNER $GROUP $PERMS should exist on the server ->> NOT_OK" | sed "s/\bno\b//g"
		linie=$((linie+1))
	continue
	fi


	#Data on the server
	M_P1=`cat $TEMP | awk NR==$LINIE | cut -d: -f 1`
	SIZE1=`cat $TEMP | awk NR==$LINIE | cut -d: -f 2`
	OWNER1=`cat $TEMP | awk NR==$LINIE | cut -d: -f 3`
	GROUP1=`cat $TEMP | awk NR==$LINIE | cut -d: -f 4`
	PERMISS1=`cat $TEMP | awk NR==$LINIE | cut -d: -f 5`
	PERMS1=`PERMSS $PERMISS1`


	# if the size is not required
	if [[ "$SIZE" == "NO" ]] || [ -z $SIZE ]
	then
		SIZE=$SIZE1
	fi

	# checks if the sizes match
	RESULT=`SIZES $SIZE $SIZE1`


	if [[ "$RESULT" == "OK" ]]
	then
		SIZE1=$SIZE
	fi


	# if the owner is not required
	if [[ "$OWNER" == "NO" ]] || [ -z $OWNER ]
	then
		OWNER=$OWNER1
	fi


	# if the group is not required
	if [[ "$GROUP" == "NO" ]] || [ -z $GROUP ]
	then
		GROUP=$GROUP1
	fi


	# if the permissions are not required
	if [[ "$PERMS" == "NO" ]] || [ -z $PERMS ]
	then
		PERMS=$PERMS1
	fi



	# the line from the ASIC
	TEST=`echo $M_P $SIZE $OWNER $GROUP $PERMS`
	# the line from custreq.raw
	TEST1=`echo $M_P1 $SIZE1 $OWNER1 $GROUP1 $PERMS1`

	
	# if everything is OK 
	if [[ "$TEST" == "$TEST1" ]]
	then
		echo -e "$TEST ->> OK" 
		linie=$((linie+1))
		continue
	else
	#if it is not OK
		if [[ ! "$SIZE" == "$SIZE1" ]]
		then
			echo -e "The filesystem $TEST1 should have a size of $SIZE GB ->> NOT_OK"
		fi

		if [[ ! "$OWNER" == "$OWNER1" ]]
		then
			echo -e "The filesystem $TEST1 should have this owner : $OWNER ->> NOT_OK"
		fi

		if [[ ! "$GROUP" == "$GROUP1" ]]
		then
			echo -e "The filesystem $TEST1 should have this group : $GROUP ->> NOT_OK"
		fi

		if [[ ! "$PERMS" == "$PERMS1" ]]
		then
			echo -e "The filesystem $TEST1 should have these permissions : $PERMS ->> NOT_OK"
		fi
	fi

	# next line that has to be checked
	linie=$((linie+1))
	echo "----------------------------------"
done

rm $TEMP $INPUT $INP
