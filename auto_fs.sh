#!/bin/bash

usage ()
{

cat << END

Usage: $0 OPTION TESTITEMID

OPTIONS:
-h,
	help
-s,
        for SAN Filesystems
-c
        for NFS_CIFS Filesystems
-l
        for local filesystems

END

}



while getopts ":h :l :s :c" opt
do
	case $opt in
		h)
			usage
			exit 0
			;;
		l)
			QCSCRIPT=/home/oquat/malex/QCScripts/check_fs.qcs
			;;
		
		s)
			QCSCRIPT=/home/oquat/malex/QCScripts/check_san.qcs
			;;
		c)
			QCSCRIPT=/home/oquat/malex/QCScripts/check_cifs.qcs
			;;
		\?)
			printf "Error: -$OPTARG is not a valid option\n"
			exit 27
			;;
	esac
done

if [[ $OPTIND -lt 2 ]]
then
        usage
	exit 0
elif [[ $OPTIND -gt 2 ]]
then
        usage
	exit 0
fi


shift $((OPTIND-1))
CRQ_ID=$1
for i in `/home/oquat/malex/getIDs.pl $CRQ_ID | cut -d'-' -f2`
do
	qcsh $QCSCRIPT --testitemid=$i
	echo
done
