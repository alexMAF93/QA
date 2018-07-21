#!/bin/bash


GETID='/home/oquat/malex/GET_IDs/get_nameID_offline.pl'
RAW='/opt/oquat/qualitycenter/data/raw'


usage ()
{
cat <<END
Usage: $0 OPTION CRQ_ID

OPTIONS:
-u,
	Retrieve the list of users
-g,
	Retrieve the list of groups (only for Windows Servers)
-f,
	Retrieve the filesystems
-s,
	Retrieve the specifications
-h,
	help
END
}


extract_data ()
{
case $CHOICE in
	users)
		case $TYPE in
			bladelogic)
				PATTERN="win_net_administrator"
				;;
			custreq)
				PATTERN="cr_user_group"
				;;
		esac
				
		BEGIN=`cat $REQ_FILE | grep -n begin_${PATTERN} | cut -d':' -f1`
		END=`cat $REQ_FILE | grep -n end_${PATTERN} | cut -d':' -f1`
		cat $REQ_FILE | tail -n +$BEGIN | head -n $(( END - BEGIN + 1 )) | grep -v $PATTERN
		;;
	groups)
		case $TYPE in
			bladelogic)
				PATTERN="win_net_localgroup"
				;;
			custreq)
				printf "Error: Not available for linux\n"
				exit 7
				;;
		esac
		BEGIN=`cat $REQ_FILE | grep -n begin_${PATTERN} | cut -d':' -f1`
                END=`cat $REQ_FILE | grep -n end_${PATTERN} | cut -d':' -f1`
                cat $REQ_FILE | tail -n +$BEGIN | head -n $(( END - BEGIN + 1 )) | grep -v $PATTERN
		;;
	filesystems)
		case $TYPE in
                        bladelogic)
				linux=0
                                ;;
                        custreq)
				linux=1
                                ;;
                esac
		
		if [[ $linux -eq 0 ]]
		then
                        PATTERN="win_Win32_LogicalDisk"
                	BEGIN=`cat $REQ_FILE | grep -n begin_${PATTERN} | cut -d':' -f1`
                	END=`cat $REQ_FILE | grep -n end_${PATTERN} | cut -d':' -f1`
                	for i in `cat $REQ_FILE | tail -n +$BEGIN | head -n $(( END - BEGIN + 1 )) | egrep -v $PATTERN\|"^Caption"`
			do
				PARTITION=`echo $i | cut -d":" -f 1`
				SIZE_B=`echo $i | cut -d"," -f 4`
				SIZE_GB=$(( SIZE_B / 1073741824 ))
				printf "%5s %6s\n" "$PARTITION" "$SIZE_GB"
			done 
		elif [[ $linux -eq 1 ]]
		then
			for PATTERN in "cr_local_fs" "cr_san_fs" "cr_nfs_cifs"
			do
				printf "%s\n" "${PATTERN//_/ }"
				BEGIN=`cat $REQ_FILE | grep -n begin_${PATTERN} | cut -d':' -f1`
                        	END=`cat $REQ_FILE | grep -n end_${PATTERN} | cut -d':' -f1`
				cat $REQ_FILE | tail -n +$BEGIN | head -n $(( END - BEGIN + 1 )) | egrep -v $PATTERN\|"Permissions$"
				printf "\n"
			done
		fi
		;;
	specs)
		cat $WHOAMI_FILE | egrep OS_TYPE\|OS_VERSION\|VIRTUAL_PROP\|IDM_GROUP
		printf "PHYS_MEM_KB         : %s GB\n" "$(( `cat $WHOAMI_FILE | grep PHYS_MEM_KB | cut -d':' -f2` / 1048576 ))"
		cat $WHOAMI_FILE | egrep ALLOC_CPUS\|ALLOC_CORES\|IP_ADDRESS
		
		;;
esac

	
}


while getopts ":u :g :f :s :h" opt
do

	case $opt in
		u) 
			CHOICE="users"
			;;
		g) 
			CHOICE="groups"
			;;
		f) 
			CHOICE="filesystems"
			;;
		s) 
			CHOICE="specs"
			;;
		h) 
			usage
			exit 0
			;;
		\?) 
			printf "Error: Unknown option: -$OPTARG\n"
			usage
			exit 0
			;;
	esac
done


if [[ $OPTIND -eq 1 ]]
then
	printf "Error: The script cannot be called without an option.\n"
	printf "Please use $0 -h for help\n"
	exit 27
fi

shift $(( OPTIND - 1 ))
CRQ_ID=$1

if [[ ! $CRQ_ID ]]
then
	printf "Error: The script must be called using the CRQ ID\n"
        printf "Please use $0 -h for help\n"
        exit 7
fi


for i in `$GETID $CRQ_ID`
do
	SERVER=`echo $i | cut -d':' -f 1`
	ITEM_ID=`echo $i | cut -d':' -f 2`
	TIER2_ID=`echo $i | cut -d':' -f 3`

	case $TIER2_ID in
		87|1063|13|14|15)
				TYPE="bladelogic"
				;;
		22|23|24|78|100)
				TYPE="custreq"
				;;
	esac
	
	if [[ ! -s $RAW/$ITEM_ID/manual/whoami.raw || ! -s $RAW/$ITEM_ID/manual/${TYPE}.raw ]]
	then
		printf "Error: The raw files do not exist for $SERVER.\n"
		exit 7
	else
		REQ_FILE=$RAW/$ITEM_ID/manual/${TYPE}.raw
		WHOAMI_FILE=$RAW/$ITEM_ID/manual/whoami.raw
	fi	
	printf "\n%s for %20s\n" "`tr '[:lower:]' '[:upper:]' <<< ${CHOICE:0:1}`${CHOICE:1}" "$SERVER"
	extract_data
done
