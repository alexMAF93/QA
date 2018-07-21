#!/bin/bash
GREEN='\033[0;32m' # Escape sequence for Green
RED='\033[0;31m'   # Escape sequence for Red
NC='\033[0m'       # Escape sequence no color
TEMP=/home/oquat/malex/FS_chk/temp.txt # custreq.raw
TEMP1=/home/oquat/malex/FS_chk/temp1.txt # local fs
TEMP2=/home/oquat/malex/FS_chk/temp2.txt # san fs
TEMP3=/home/oquat/malex/FS_chk/temp3.txt # nfs cifs
INP=/home/oquat/malex/FS_chk/inp.txt # ASIC
INPUT=/home/oquat/malex/FS_chk/chk_fs.txt # ASIC without weird spacing
OUTPUT=/home/oquat/malex/FS_chk/output.txt
GETID=/home/oquat/malex/GET_IDs
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

# checks if there are arguments
if [ -z $1 ]
then
printf "\n\nusage : $0 CRQ_ID\n\n "
exit 27
fi

$GETID/getIDs.pl $1 > $GETID/listaIDs

vi $INP
sleep 1
cat $INP | tr ',' ' ' | tr '\t' ' ' | tr -s ' ' | sed s/exception://g | sed s/^\ //g | sed s/\<//g | sed s/\>//g | sed '/^$/d' | sed 's/$/ /g' | tr ' ' ':' | sort | uniq > $INPUT # replaces empty spaces with ":", deletes the empty lines
CNT=`cat $INPUT | wc -l` # the number of lines = the number of mount points that have to be checked

NR_ARGS=`cat $GETID/listaIDs | wc -l` # the number of arguments

for K in `cat $GETID/listaIDs` # K circles through the arguments
do
>$OUTPUT
DIR="/opt/oquat/qualitycenter/data/raw/$K" # the directory with the raw files
ls -ld "$DIR/manual" 2>/dev/null && DIR="$DIR/manual"

if [ ! -f $DIR/custreq.raw ]
then
echo
echo "ERROR : Cannot access $DIR/custreq.raw"
echo
echo "Please check that the TestItemID $K is correct"
echo
if [ $NR_ARGS -gt 1 ]
then
echo -n "Press ENTER to continue ..."
read CEVA
case $CEVA in
*);;
esac
fi
NR_ARGS=$((NR_ARGS-1))

continue
fi


clear


# gets line number for the lines that have the filesystems between them and appends the filesystems to $TEMP
BEGIN=`cat $DIR/custreq.raw | grep -n begin_cr_local_fs | cut -d: -f 1` # the line number of the line where the local filesystems listing begins
END=`cat $DIR/custreq.raw | grep -n end_cr_local_fs | cut -d: -f 1` # the line number of the line where the local filesystems listing ends
echo "LOCALFS" > $TEMP
cat $DIR/custreq.raw | tail -n +$BEGIN | head -$(($END-$BEGIN+1)) | egrep -v begin_cr_local_fs\|end_cr_local_fs\|"Permissions" | tr -s ' ' ':'| sed s/"\."$//g >> $TEMP 
BEGIN=`cat $DIR/custreq.raw | grep -n begin_cr_san_fs | cut -d: -f 1`
END=`cat $DIR/custreq.raw | grep -n end_cr_san_fs | cut -d: -f 1`
echo "SANFS" >> $TEMP
cat $DIR/custreq.raw | tail -n +$BEGIN | head -$(($END-$BEGIN+1)) | egrep -v begin_cr_san_fs\|end_cr_san_fs\|"Permissions" | tr -s ' ' ':' | sed s/"\."$//g >> $TEMP
BEGIN=`cat $DIR/custreq.raw | grep -n begin_cr_nfs_cifs | cut -d: -f 1`
END=`cat $DIR/custreq.raw | grep -n end_cr_nfs_cifs | cut -d: -f 1`
echo "NFSCIFS" >> $TEMP
cat $DIR/custreq.raw | tail -n +$BEGIN | head -$(($END-$BEGIN+1)) | egrep -v begin_cr_nfs_cifs\|end_cr_nfs_cifs\|"Permissions"\|^"No" | tr -s ' ' ':' | sed s/"\."$//g >> $TEMP



# the line number of the line that is followed by the filesystem
LOCALFS=`cat $TEMP | cut -d: -f 1 | grep -nx "LOCALFS" | cut -d: -f 1` 
SANFS=`cat $TEMP | cut -d: -f 1 | grep -nx "SANFS" | cut -d: -f 1`
NFSCIFS=`cat $TEMP | cut -d: -f 1 | grep -nx "NFSCIFS" | cut -d: -f 1`


# these are the files where the different types of file systems will be separated
echo " == Local Filesystems == " > $TEMP1
echo >> $TEMP1

echo > $TEMP2
echo " == SAN Filesystems == " >> $TEMP2
echo >> $TEMP2

echo > $TEMP3
echo " == NFSCIFS == " >> $TEMP3
echo >> $TEMP3

# the first line represents the first mount point that must be verified
linie=1



while [ $linie -le $CNT ]
do

PROC=$((100*linie/CNT))
echo -ne "$PROC % completed "\\r


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

# the number of the line where the mount point from the ASIC is in the file with data from custreq.raw
LINIE=`cat $TEMP | cut -d: -f 1 | grep -nx "$M_P" | cut -d: -f 1 | head -1`


# if the mount point does not exists, the counter increases and the loop continues
if [ -z $LINIE ]
then
OUTPUT=/home/oquat/malex/FS_chk/output.txt
echo -e "The mount point $M_P $SIZE $OWNER:$GROUP $PERMS should exist on the server ->> ${RED} NOT_OK ${NC}" >> $OUTPUT
linie=$((linie+1))
continue
fi

# decides what kind of FS is verified
if [ $LINIE -gt $LOCALFS ] && [ $LINIE -lt $SANFS ]
then
OUTPUT=$TEMP1
fi

if [ $LINIE -gt $SANFS ] && [ $LINIE -lt $NFSCIFS ]
then
OUTPUT=$TEMP2
fi

if [ $LINIE -gt $NFSCIFS ]
then
OUTPUT=$TEMP3
fi


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
echo "  -- size not specified --" >> $OUTPUT
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
echo " -- owner not specified --"  >> $OUTPUT
fi


# if the group is not required
if [[ "$GROUP" == "NO" ]] || [ -z $GROUP ]
then
GROUP=$GROUP1
echo "  -- group not specified --"  >> $OUTPUT
fi


# if the permissions are not required
if [[ "$PERMS" == "NO" ]] || [ -z $PERMS ]
then
PERMS=$PERMS1
echo "  -- permissions not specified --"  >> $OUTPUT
fi


# the line from the ASIC
TEST=`echo $M_P $SIZE $OWNER $GROUP $PERMS`
# the line from custreq.raw
TEST1=`echo $M_P1 $SIZE1 $OWNER1 $GROUP1 $PERMS1`


# if everything is OK 
if [[ "$TEST" == "$TEST1" ]]
then
echo -e "$TEST ->> ${GREEN} OK ${NC}"  >> $OUTPUT
fi


#if it is not OK
if [[ ! "$SIZE" == "$SIZE1" ]]
then
echo -e "The filesystem $TEST1 should have a size of $SIZE GB ->> ${RED} NOT_OK ${NC}"  >> $OUTPUT
fi

if [[ ! "$OWNER" == "$OWNER1" ]]
then
echo -e "The filesystem $TEST1 should have this owner : $OWNER ->> ${RED} NOT_OK ${NC}"  >> $OUTPUT
fi

if [[ ! "$GROUP" == "$GROUP1" ]]
then
echo -e "The filesystem $TEST1 should have this group : $GROUP ->> ${RED} NOT_OK ${NC}"  >> $OUTPUT
fi

if [[ ! "$PERMS" == "$PERMS1" ]]
then
echo -e "The filesystem $TEST1 should have these permissions : $PERMS ->> ${RED} NOT_OK ${NC}"  >> $OUTPUT
fi


echo "*******************************************"  >> $OUTPUT


# next line that has to be checked
linie=$((linie+1))
done


# checks if the files with different filesystems are empty
if [ `cat $TEMP1 | wc -l` -le 2 ]
then 
echo "N/A" >> $TEMP1
fi

if [ `cat $TEMP2 | wc -l` -le 3 ]
then 
echo "N/A" >> $TEMP2
fi

if [ `cat $TEMP3 | wc -l` -le 3 ]
then 
echo "N/A" >> $TEMP3
fi

cat $DIR/custreq.raw | grep "Server Name" 
echo
echo
cat /home/oquat/malex/FS_chk/output.txt | sort | uniq
echo "*******************************************"  
echo
cat $TEMP1 
cat $TEMP2 
cat $TEMP3 
echo
echo
> /home/oquat/malex/FS_chk/output.txt

# if multiple test IDs are specified, prints a message after checking each one, except for the last one
if [ $NR_ARGS -gt 1 ]
then
echo -n "Press ENTER to continue ..."
read CEVA
case $CEVA in
*);;
esac
fi
NR_ARGS=$((NR_ARGS-1))
done

