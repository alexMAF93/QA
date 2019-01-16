#!/bin/bash


# Defining the variables for the config file that will be checked and 
# the first argument will be the server for which we will check the entries
CONFIG_FILE=/home/oquat/.ssh/config
SERVER=$1


usage() {
cat<<EOF
	Usage: $0 SERVER

	Only one server can be checked at a time. 

EOF
}


if [[ $# -ne 1 ]]
then
	usage
	exit 7
fi


printf "\nOn avooqaax: \n\n"
cat $CONFIG_FILE | grep -iA3 $SERVER || printf "The server $SERVER is not present in $CONFIG_FILE\n\n"


printf "\nOn avooqaar: \n\n"
ssh avooqaar "cat $CONFIG_FILE | grep -iA3 $SERVER || printf \"The server $SERVER is not present in $CONFIG_FILE\n\n\"" 2>/dev/null


printf "\n\nThe entries on both servers should be identical\n\n"
