usage () 
{
cat <<EOF
Usage:
	$0 script_portion SERVER

script_portion can be:
	${script_portion}
EOF
}

script_portion=`ls /home/oquat/malex/LINUX_Scripts/ | grep '_script' | tr '\n' ' ' | sed 's/ / | /g' | sed 's/ | $//g' | sed 's/_script//g'`


if [[ "$1" == "" || "$2" == "" ]]
then
	usage
	exit 27
fi

SCRIPT=$1
SERVER=$2


case "$SCRIPT" in
	ora_fileperm)
		USER="oracle"
		;;
	*)
		USER="root"
		;;
esac


scp /home/oquat/malex/LINUX_Scripts/${SCRIPT}_script $SERVER:/var/tmp/${SCRIPT}
ssh -q $SERVER "chmod 777 /var/tmp/$SCRIPT;sudo -u $USER /var/tmp/$SCRIPT; rm /var/tmp/$SCRIPT"
