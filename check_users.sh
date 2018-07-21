#!/bin/bash
GREEN='\033[0;32m' # Escape sequence for Green
RED='\033[0;31m'   # Escape sequence for Red
NC='\033[0m'       # Escape sequence no color
TEMP=/home/oquat/malex/CHK_users/temp.txt
INP=/home/oquat/malex/CHK_users/inp.txt
INPUT=/home/oquat/malex/CHK_users/chk_users.txt
TEMP2=/home/oquat/malex/CHK_users/temp2.txt
GETID=/home/oquat/malex/GET_IDs


if [ -z $1 ] # if there are no arguments, exit code : 27
then
printf "\n\nusage : $0 ID_CRQ\n\n"
exit 27
fi

$GETID/getIDs.pl $1 > $GETID/listaIDs


vi $INP # data from ASIC
sleep 1
cat $INP | tr ',' ' ' | tr '\t' ' ' | tr -s ' ' | sed s/exception://g | sed s/\<//g | sed s/\>//g | sed s/^\ //g > $INPUT # data from ASIC without multiple empty spaces
CNT=`cat $INPUT | wc -l` # the number of lines of the input file


NR_ARGS=`cat $GETID/listaIDs | wc -l` # the number of arguments

for K in `cat $GETID/listaIDs` # going through test IDs
do

DIR="/opt/oquat/qualitycenter/data/raw/$K" # raw; cd TEST_ID
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
echo -n "Press ENTER to continue..."
read TASTA
case $TASTA in
1);;
esac
fi
NR_ARGS=$((NR_ARGS-1))
continue
fi

BEGIN=`cat $DIR/custreq.raw | grep -n begin_cr_user_group | cut -d: -f 1` # the line number of the line where users listing begins
END=`cat $DIR/custreq.raw | grep -n end_cr_user_group | cut -d: -f 1` # the line number of the line where users listing ends
clear

cat $DIR/custreq.raw | grep "Server Name" 
echo 
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


USER=`cat $INPUT | awk NR==$linie'{print $1}'` # the first column of each line represents the user

if [ -z $USER ] # if the line is empty, increase the counter and continue the loop
then
linie=$((linie+1))
continue
fi

TEST_USER=`cat $TEMP | grep -w ^"$USER:" | cut -d: -f 1` # check if the user is on the server

if [ -z $TEST_USER ] # if it is not on the server, then skip to the next line
then
echo -e "The user `cat $INPUT | awk NR==$linie`  does not exist on the server ->> ${RED}NOT_OK${NC}"
linie=$((linie+1))
echo "************************************"
continue
fi


HOME_DIR=`cat $INPUT | awk NR==$linie | cut -d ' ' -f 2 | sed 's/\/$//g'` 
PRIMARY_GROUP=`cat $INPUT | awk NR==$linie | cut -d ' ' -f 3` 

HOME_DIR1=`cat $TEMP | grep -w ^"$TEST_USER:" | cut -d: -f 2 | sed 's/\/$//g'` 
PRIMARY_GROUP1=`cat $TEMP | grep -w ^"$TEST_USER:" | cut -d: -f 3`


NR_CLM=`cat $INPUT | awk NR==$linie | sed 's/,/ /g' | wc -w` # the number of columns

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
echo -e "--Primary group not specified--"
PRIMARY_GROUP=$PRIMARY_GROUP1
fi

if [ -z "$HOME_DIR" ] || [ "$HOME_DIR" == "LDAP" ] || [ "$HOME_DIR" == "NO" ]
then
echo -e "--Home directory not specified--"
HOME_DIR=$HOME_DIR1
fi


TEST=`echo "$USER $HOME_DIR $PRIMARY_GROUP"` 
TEST1=`echo "$TEST_USER $HOME_DIR1 $PRIMARY_GROUP1"`


# weird logic for the tests, needs to be rechecked 
if [[ "$TEST" == "$TEST1" ]] && [ $DIM_SEC_GRP -eq 0 ]
then
echo -e "$TEST1 `echo $SEC_GRP1 | sed 's/ /,/g'` ->> ${GREEN}OK${NC}"
fi



if [[ "$PRIMARY_GROUP" != "$PRIMARY_GROUP1" ]]
then
echo -e "The user $TEST1 `echo $SEC_GRP1 | sed 's/ /,/g'` should have this primary group : $PRIMARY_GROUP ->> ${RED}NOT_OK${NC}"
fi




if [[ "$HOME_DIR" != "$HOME_DIR1" ]]
then
echo -e "The user $TEST1 `echo $SEC_GRP1 | sed 's/ /,/g'` should have this home directory : $HOME_DIR ->> ${RED}NOT_OK${NC}"
fi


if [ $DIM_SEC_GRP -gt 0 ]
then
echo -e "The user $TEST1 `echo $SEC_GRP1 | sed 's/ /,/g'` is missing these secondary groups : ${ARRAY_SEC_GRP[*]} ->> ${RED}NOT_OK${NC}"
fi


echo "************************************"





linie=$((linie+1))
done

echo 
echo 
# after the check is done for an argument, you have to press enter to check the next one
if [ $NR_ARGS -gt 1 ]
then
echo -n "Press ENTER to continue..."
read TASTA
case $TASTA in
1);;
esac
fi
NR_ARGS=$((NR_ARGS-1))
done
