#!/bin/bash

CONS=/home/oquat/malex/DECOM/conserver.cf.sh
VCENT=/home/oquat/malex/DECOM/adminconsole.sh


if [[ "$1" == "" ]]
then
	printf "\n\n\tusage: $0 CRQ_ID\n"
	exit 27
else
	$CONS $1
	printf "\n\n"
	$VCENT $1
fi
