#!/bin/bash


usage ()
{
cat << EOF


Usage:
	$0 [OPTION] [SCRIPT] SERVER

Options:
	-r,
		Run a vbs script on the server through BladeLogic. This option requires an argument and it must be the name of the script.
	-x,
		Runs qa_blif with bash -x.


Used without an option:

		Check if the connectivity from Bladelogic to the server is working. You can use -x for debugging purposes.


SCRIPT := { $AVAILABLE_SCRIPTS }

EOF
}


AgentInfo ()
{
if [[ $debug -eq 1 ]]
then
	bash -x $BLIF $SERVER
else
	$BLIF $SERVER
fi

}


RunQA ()
{
SCRIPT_PATH=/home/oquat/malex/VBScripts/${SCRIPT}.vbs
if [[ $debug -eq 1 ]]
then
	bash -x $BLIF $SERVER $SCRIPT_PATH
else
	$BLIF $SERVER $SCRIPT_PATH
fi

}


debug=0
QA_BLIF=`which qa_blif`
AVAILABLE_SCRIPTS=`ls /home/oquat/malex/VBScripts/ | sed 's/\.vbs//g' | tr '\n' ' ' | sed 's/\ / | /g' | sed 's/ | $//g'`


while getopts ":x :h :r:" opt
do
	case $opt in
		h)
			usage
			exit 0
			;;
		r)
			BLIF="$QA_BLIF runQaOnServer"
			SCRIPT=$OPTARG
			choice=2
			;;
		x)
			debug=1
			;;
		\?)
                        printf "Error: -$OPTARG is not a valid option\n"
			usage
                        exit 27
                        ;;
	esac
done

#if [[ $OPTIND -lt 2 ]]
#then
#	usage
#	exit 27
#fi


shift $((OPTIND-1))
SERVER=$1
if [[ "$SERVER" == "" ]]
then
	usage
	exit 27
elif [[ "$BLIF" == "" ]]
then
	BLIF="$QA_BLIF getAgentinfo"
	choice=1
fi


if [[ $choice -eq 1 ]]
then
	AgentInfo
else
	RunQA
fi
