#!/bin/bash


printf "Add the servers below and press CTRL + D\n\\n\n"
SERVERS=`cat`


for i in $SERVERS
do
# testing the connectivity
	CONN=0
	ssh -q root@$i "echo Connectivity working for $i" && CONN=1
	if [[ $CONN -eq 1 ]]
	then
		printf "Adding the key to ${i}...\n\n"
		ssh -T root@$i<<-"EOF"
			HOME_DIR=`getent passwd oquat | cut -d: -f6`
			SSH_KEY="some ssh key"
			SSH_KEY_DIR="${HOME_DIR}/.ssh"
			KEY_FILE="${SSH_KEY_DIR}/authorized_keys"
			if [[ "$HOME_DIR" ]]
			then
				if [[ -d $SSH_KEY_DIR ]]
				then
					printf "The .ssh directory already exists; moving on...\n"
				else
					printf "The .ssh directory does not exist; creating it...\n"
					mkdir $SSH_KEY_DIR
				fi
				if [[ -f $KEY_FILE ]]
				then
					SSH_KEY_PART=`echo $SSH_KEY | awk '{print $2}'`
					if [[ `grep -c $SSH_KEY_PART $KEY_FILE` -ge 1 ]]
					then
						printf "The key is already present; nothing to do...\n\n"
					else
						printf "Adding the key...\n"
						echo $SSH_KEY >> $KEY_FILE
						printf "Changing the ownership for the file...\n"
						chown -R oquat $SSH_KEY_DIR
					fi
				else
					printf "Creating the authorized_keys file and adding the key...\n"
					echo $SSH_KEY >> $KEY_FILE
					printf "Changing the ownership for the file...\n"
					chown -R oquat $SSH_KEY_DIR
				fi
			else 
				printf "The user oquat is not on the server...\n"
			fi
			
		EOF
	else
		printf "Cannot connect to $i...\n"
	fi
done

