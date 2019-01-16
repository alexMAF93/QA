#!/bin/bash


usage ()
{
cat<<EOF
	Usage: $0 ITEM
EOF
}


if [[ ! "$1" ]]
then
	usage
	exit 7
fi


ssh -q oquat@uppsala2 "/opt/scripte/icms -l ${1^^}"
