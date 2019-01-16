#!/bin/bash


if [[ ! $1 ]]
then
	printf "Error: the script must have an argument\n"
	exit 7
fi


noDS=`ssh ${1^^} "echo noDS"`


if [[ "$noDS" == "noDS" ]]
then
	printf "OK: The Deployment Support period ended.\n"
else
	printf "NOT_OK: The Deployment Support period is still on-going.\n"
fi
