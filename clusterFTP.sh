#!/bin/bash

labE007="e007"
labE105="e105"
labTeste="teste"
netLab="192.168.56.0/24"

cSSH=2
cPING=1
cDown=0

iSSH=0
iPING=0
iDown=0

uftpBytes="54857600"

fileSSH="$HOME/.ssh/id_rsa.pub"
dirUFTP="/media/compartilhada"

lab="e105"
adminUser="suporte"
USERPASS=" "
netIP=" "
fileHosts=" "
fileMacs=" "

function show_cluster_hosts() {
	sudo nmap -sP $netID/26
}

##
# Color  Variables
##
green='\e[32m'
blue='\e[33m'
clear='\e[0m'
red='\e[31m'
##
# Color Functions
##
ColorGreen(){
	echo -ne $green$1$clear
}
ColorBlue(){
	echo -ne $blue$1$clear
}
ColorRed(){
	echo -ne $red$1$clear
}

function showHostStatus(){
	if ping -c 1 -W 1 "$1" &> /dev/null ; then
		sshState=`echo "$USERPASS" | sshpass -p $USERPASS ssh suporte@$line whoami 2> /dev/null`
		if  [[ $adminUser = $sshState ]]; then
			echo -ne "$(ColorGreen $1) (up-ssh), \c"
			let "iSSH+=1"
		else
			echo -ne "$(ColorGreen $1) (up-ping), \c"
			let "iPING+=1"
		fi
	else
			  echo -ne "$(ColorRed $1) (down), \c"
			  let "iDown+=1"
	fi
}

function zeraCounters() {
	iSSH=0
	iPING=0
	iDown=0
}

function showHostLab(){
	echo -e "Show status from hosts in the $lab lab:\n"
	zeraCounters
	while IFS= read -r line
	do
		showHostStatus $line
	done < "$fileHosts"

	echo -e "\nSummary:\n\t($(ColorGreen up-ping)) - host online, but don't have ssh access by ssh key.\n\t($(ColorGreen up-ssh)) - host online and have ssh access.\n\t($(ColorRed down)) - hosts offline."
	echo -e "\t $(($iSSH+$iPING+$iDown)) - hosts in $fileHosts file;"
	echo -e "\t\t $iDown - hosts offline;"
	echo -e "\t\t $(($iSSH+$iPING)) - hosts online; "
	echo -e "\t\t\t $iSSH - hosts online with SSH access; "
	echo -e "\t\t\t $iPING - hosts online, but without SSH access. "
	zeraCounters
}

function showLab(){
	echo -e "\nYou are configuring the computer lab $(ColorGreen $lab)"
}

function checkFiles(){
	if [ ! -f $1 ]; then
		echo -e "Atention the file $(ColorRed $1) don't exist!!!"
		return 1
	else
		return 0
	fi
}

function installSSHkeyHost(){
	echo -e "Install SSH Key in a specific host..."
	echo -e "Please enter the host IP: e.g. 192.168.0.1"
	read host
	echo "Copying ssh file do host $host"
	echo "$USERPASS" | ssh-copy-id -f suporte@$host
	echo "Copy done..."
}

function installSSHkey(){
	echo -e "Install SSH Key in hosts from the $lab lab - thus you will can access this hosts without password!\n\n>> Atention, make this only in the first access... <<"

	read -p "Do you want continue?(y/N)" yn

	case $yn in
		[yY] ) echo -e "Installing  SSH in the hosts from de $lan lan... wait!"

			if ! checkFiles $fileSSH; then
				echo -e "You are logged with the ``whoami`` user!"
				echo -e "Error: You don't have $fileSSH file, please create it with ssh-keygen command!"
				exit 0
			fi

			while IFS= read -r line
			do
				echo "Copying ssh file do host $line"
				echo "$USERPASS" | ssh-copy-id -f suporte@$line
				#echo "$USERPASS" | sshpass ssh-copy-id -x -s -f suporte@$line
			done < "$fileHosts"
		    echo "Done..."; menu;;
		* ) echo "Okay, cancel intall SSH key!"; menu;;
	esac

}

function wakeuphosts(){
	echo -e "> Wake up hosts from $lab"
	echo -e "Turning on all hosts from lab $lab using wakeonlan...\nThis should take a few minutes..."

	if ! [ -x "$(command -v wakeonlan)" ]; then
		echo "Error: wakeonlan is not installed."
		echo -e "\n\n>> Please turn on by yourself all hosts from $lab lab. <<\n\n"
	else
		echo "$USERPASS" | sudo -S wakeonlan -f $fileMacs
		echo -e "Please $(ColorRed wait) at least 2 minutes..."
	fi

}

function createFileHost(){
	echo -e "\n > Creating IP file automatically - using nmap and MAC file"
	if ! checkFiles $fileMacs; then
			echo -e "\nThe  file $fileMacs don't exists, the you need create it to: \n  * use wakeup on LAN;\n  * to create automatically create $fileHosts.\nThe contents of this file must have one MAC address per line, such as:\n58:57:18:f1:b7:01\n58:57:18:f1:b7:02"
			echo -e "Error: Please create $fileMacs first!\n Bye..."
			exit 0
	fi

	wakeuphosts

	echo -e "Executig nmap to discover hosts IP from $lab based on MAC list from file $fileMacs"
	echo -e "What is the network range in the $lab lab?"
	echo -e "Please enter with de network range, e.g: 172.16.1.0/26"
	read netLab
	echo -e "Executing nmap to discover active hosts on $lab lab. Wait..."
	if ! [ -x "$(command -v nmap)" ]; then
		echo "Error: nmap is not installed."
		echo -e "You need make the IP file $fileHosts manually! This file must have one MAC address per line, such as:\n192.168.0.1\n192.168.0.2\nWithout this file the program will not work correctly."
		exit 0
	fi
	nmap -sP $netLab

	echo -e "Creating the $fileHosts"
	while IFS= read -r line
	do
		hostIP=`cat /proc/net/arp | grep $line | cut -d " " -f 1`
		if [[ ! -z "$hostIP" ]]; then 
			echo "MAC: $line - IP: $hostIP"
			echo $hostIP >> $fileHosts
		fi
	done < "$fileMacs"

	echo -e "$fileHosts is done..."
}

function setLab(){
		lab=$1
		fileHosts="conf/$1_ips.txt"
		fileMacs="conf/$1_macs.txt"
		showLab
		#if ! checkFiles $fileMacs; then
		#	echo -e "\nThe MAC file $fileMacs don't exists, the you need create it to: \n  * use wakeup on LAN;\n  * to create automatically create $fileHosts.\nThe contents of this file must have one MAC address per line, such as:\n58:57:18:f1:b7:01\n58:57:18:f1:b7:02"
		#fi
		if ! checkFiles $fileHosts; then
			echo -e "\nThe IP file $fileHosts don't exists, the you need create it to continue, the contents of this file must have one MAC address per line, such as:\n192.168.0.1\n192.168.0.2\nWithout this file the program will not work correctly."
			
			read -p "Do you want create IP file ?(y/N)" yn

			case $yn in
			[yY] ) echo -e "Creating $fileHosts IP file... wait!"
				createFileHost;
		    	echo "Done..."; menu;;
		* ) echo "Okay, continue without IP file!"; menu;;
	esac

			
		fi
}

function checkUtftpd(){
	echo -e "Checking UFTPD in the hosts from the $lab lab..."
	while IFS= read -r line
	do
		echo -e "\nCheck UFTPD from $line host:"
		pross=`echo "$USERPASS" | sshpass -p $USERPASS ssh suporte@$line sudo -S ps ax | grep uftpd | grep -v grep`
		#echo "out: $pross"
		if [ -z "$pross" ]; then
			echo -ne "$(ColorRed $line) (down-uftp)"
		else
			echo -ne "$(ColorGreen $line) (up-uftp)"
		fi
	done < "$fileHosts"
	#echo -e "\nSummary:\n\t($(ColorGreen up-ping)) - host online, but don't have ssh access by ssh key.\n\t($(ColorGreen up-ssh)) - host online and have ssh access.\n\t($(ColorRed down)) - host offline."
}

function startUtftpd(){
	echo -e "Starting UFTPD, It's used to copy files in a multicast mode... (more fast)"
	echo -e "Starting the copying process..."
	echo -e "The default utfp destination directory is $dirUFTP"
	read -p "Do you want to change the default utfp destination directory?(y/N)" yn
	case $yn in
		[yY] ) echo "What's the directory that will be the destination of copy, in the hosts from the $lab cluster?"
				read dirUFTP ;;
		* ) echo "Okay, use default uftp directory!";;
	esac

	#echo -e "What's the directory that will be the destination of copy, in the hosts from the $lab cluster?"
	#echo -e "Enter with the directory destination name:"

	while IFS= read -r line
	do
		echo "Start UFTPD in the $line host..."
		#echo "$USERPASS" | ssh suporte@$line sudo -S /etc/init.d/uftp restart
		echo "$USERPASS" | sshpass -p $USERPASS ssh suporte@$line sudo -S /etc/init.d/uftp stop
		#echo "$USERPASS" | ssh suporte@$line sudo -S uftpd -D $dirUFTP -B $uftpBytes

		if echo "$USERPASS" | sshpass -p $USERPASS ssh suporte@$line sudo -S ls $dirUFTP ; then
			echo "$USERPASS" | sshpass -p $USERPASS ssh suporte@$line sudo -S /usr/bin/uftpd -d -L /var/log/uftp.log -D $dirUFTP -t &
		else
			echo -e "Directory $dirUFTP don't exist... creating..."
			if echo "$USERPASS" | sshpass -p $USERPASS ssh suporte@$line sudo -S mkdir -p $dirUFTP ; then
				echo "$USERPASS" | sshpass -p $USERPASS ssh suporte@$line sudo -S chown -R suporte $dirUFTP
				echo "$USERPASS" | sshpass -p $USERPASS ssh suporte@$line sudo -S /usr/bin/uftpd -d -L /var/log/uftp.log -D $dirUFTP -t &
			else
				echo "Fail to init uftpd in $line..."
			fi
		fi


	done < "$fileHosts"

	verifyFileCluster $dirUFTP

	checkUtftpd
}

function stopUtftpd(){
	echo -e "Stop UFTPD, It's used to copy files in a multicast mode..."
	read -p "Do you want stop the uftp on the hosts form the cluster?(y/N)" yn
	case $yn in
		[yY] ) echo "What's the directory that will be the destination of copy, in the hosts from the $lab cluster?"
			while IFS= read -r line
			do
				echo "Stop UFTPD in the $line host..."
				echo "$USERPASS" | sshpass -p $USERPASS ssh suporte@$line sudo -S /etc/init.d/uftp stop
			done < "$fileHosts"
			menuFile;;
		* ) echo "Okay, go to file menu!"; menuFile;;
	esac

	echo -e "Stop UFTPD finished"

	checkUtftpd

}

function shutdownAllHosts(){
	echo -e "Shutdown all hosts from the $lab lab... (except this host)"

	read -p "Do you really want continue and shutdown all hosts?(y/N)" yn

	case $yn in
		[yY] ) while IFS= read -r line
				do
					echo "$line"
					echo "$USERPASS" | sshpass -p $USERPASS ssh suporte@$line sudo -S poweroff
				done < "$fileHosts"
				echo -e "Done... waint a time and check if hosts is down!"; menu;;
		* ) echo "Okay, cancel shutdown all hosts!"; menu;;
	esac
}

function copyFileMcast(){
	echo -e "Copy a file using multicast to the cluster of $lab lab."
	echo -e "Please enter with the file that will be copy to all hosts from the $lab cluster:"
	echo -e "Type the absolute file path:"
	read fileFrom
	if ! checkFiles $fileFrom; then
			echo -e "Error: $fileFrom file dont exists!\n"
			menu
	fi


	if ! [ -x "$(command -v uftp)" ]; then
		echo "Error: uftp is not installed."
		echo -e "\n>>You must install uftp before running this...<<\n"
		exit 0
	fi

	echo -e "Copy $fileFrom to all hosts from the $lab cluster, using multicast... wait!"
	echo -e "The copy can take many minutes... about 15 minutes per Gigabyte!"
	uftp -R $uftpBytes -Y none $fileFrom
	echo -e "Copy process finished..."

	verifyFileCluster $dirUFTP/$file

}

# $1 - fileName $2 - host
function verifyFileHost(){
echo -e "\nFinding file $1 in the $(ColorBlue $2) host:"
		if echo "$USERPASS" | sshpass -p $USERPASS ssh suporte@$2 sudo -S ls $1 ; then
			echo -e "File $(ColorGreen found)..."
		else
			echo -e "File $(ColorRed missed)..."
		fi
}

# $1 - fileName
function verifyFileCluster(){
	echo "Verifing $1 File "
	while IFS= read -r line
	do
		verifyFileHost $1 $line
	done < "$fileHosts"

}

function verifyFileCluster_read(){
	echo -e "Verify if exist a file in all hosts from cluster of the $lab lab."
	echo -e "Enter with the file name:"
	read fileName
	verifyFileCluster $fileName
}

function executeSudoCommandCluster(){
	ok=0
	fail=0
	echo -e "Execute a command with $(ColorRed sudo) in all hosts from the cluster of the $lab lab."
	echo -e "Type the commando to be executed:"
	read command
	while IFS= read -r line
	do
		echo -e "\nExecuting command $command in the $(ColorBlue $line) host:"
		if echo "$USERPASS" | sshpass -p $USERPASS ssh suporte@$line sudo -S $command ; then
			let "ok+=1"
			echo -e "Command executed with $(ColorGreen success) - total hosts: $ok."
		else
			let "fail+=1"
			echo -e "Command $(ColorRed fail) - total hosts: $fail"
		fi
	done < "$fileHosts"
	echo -e "Total hosts: $(($ok+$fail)):\n\t$ok - execute command with success;\n\t$fail - fail in execute the command."

}

# terminar de fazer a execução de comandos em um host especifico - perguntar se quer executar o mesmo comando em outro host...
# tbm daria para ver os computadores que não tem ssh ou uftp e pedir se quer instalar neles... 
function executeSudoCommandClusterInAHost(){
	echo -e "Execute a command with $(ColorRed sudo) in a specific host from the cluster of the $lab lab."
	echo -e "Enter the host IP: e.g 192.168.0.1"
	read host
	echo -e "Type the commando to be executed:"
	read command
	
		echo -e "\nExecuting command $command in the $(ColorBlue $line) host:"
		if echo "$USERPASS" | sshpass -p $USERPASS ssh suporte@$host sudo -S $command ; then
			echo -e "Command executed with $(ColorGreen success)."
		else
			echo -e "Command $(ColorRed fail)."
		fi
}

function executeCommandCluster(){
	ok=0
	fail=0
	echo -e "Execute a command with $adminUser user in all hosts from the cluster of the $lab lab."
	echo -e "Type the commando to be executed:"
	read command
	while IFS= read -r line
	do
		echo -e "\nExecuting command $command in the $(ColorBlue $line) host:"
		if echo "$USERPASS" | sshpass -p $USERPASS ssh suporte@$line $command ; then
			let "ok+=1"
			echo -e "Command executed with $(ColorGreen success) - total hosts: $ok."
		else
			let "fail+=1"
			echo -e "Command $(ColorRed fail) - total hosts: $fail"
		fi
	done < "$fileHosts"
	echo -e "Total hosts: $(($ok+$fail)):\n\t$ok - execute command with success;\n\t$fail - fail in execute the command."

}

function downGDrive(){
	echo -e "Download a file from a Google Drive - it can be helpful"

	# $1 - gID - id of Google Drive File
	# $2 - gFile - name of file
	eco="/bin/echo -e"
	$eco "\nThis program download a file from Google Drive, then you need pass ID from google URL and any name to the downloaded file.\n"
	$eco "Example:\n\thttps://drive.google.com/file/d/1-qxMW1D6pPXtaMWVOCA0gw7xqzcc-3YJ/view?usp=sharing"
	$eco "\tIn the previus URL, the ID is: 1-qxMW1D6pPXtaMWVOCA0gw7xqzcc-3YJ"
	$eco "An example will be Google Drive ID: 1-qxMW1D6pPXtaMWVOCA0gw7xqzcc-3YJ\n Name of destination file:\n example.txt\n"

	echo -e "Please enter with the Google Drive ID from google URL:"
	read gID

	echo -e "Please, now enter with the name of destination file:"
	read gFile

	URL="https://docs.google.com/uc?export=download&id=$gID"
	$eco "else"
	wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate $URL -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$gID" -O $gFile && rm -rf /tmp/cookies.txt

	$eco "Finished... file is in: $(pwd)/$gFile"

}

function selectLab(){
 echo -ne "
  Select the lab:
  $(ColorGreen '1)') e007
  $(ColorGreen '2)') e105
  $(ColorGreen '3)') teste
  $(ColorGreen '0)') Exit
  $(ColorBlue 'Choose an option:') "
  read a
  case $a in
	        1) setLab $labE007 ; menu ;;
	        2) setLab $labE105 ; menu ;;
	        3) setLab $labTeste; menu ;;
		0) exit 0 ;;
		*) echo -e $red"Wrong option, please select a valid option!"$clear;;
  esac
}

function setPassword(){
	echo -e "Please enter with the $(ColorRed $adminUser) password"
	read -s USERPASS
}

function setUserAdmin(){
	echo -e "The current user, that will be used to access all hosts from the cluster is: \n\t$(ColorRed $adminUser)\n. This user must have $(ColorGreen sudo) permissions!"
	read -p "Do you really want continue and change the user?(y/N)" yn
	case $yn in
		[yY] ) 	echo -e "Please enter with new user:"
				read adminUser
				setPassword
				echo -e "Done... waint a time and check if hosts is down!"; menu;;
		* ) echo "Okay, cancel shutdown all hosts!"; menu;;
	esac
}

function menuConf(){
echo -e "$(ColorGreen Configure) script!"
echo -ne "
Configure/change:
$(ColorGreen '1)') Lab/cluster (current is $(ColorGreen $lab));
$(ColorGreen '2)') Sudo user/admin (current is $(ColorGreen $adminUser));
$(ColorGreen '3)') Password from $(ColorRed $adminUser);
$(ColorGreen '4)') Install SSH key in the cluster hosts - just for first access
$(ColorGreen '5)') Install SSH Key in a specific host;
$(ColorGreen '0)') Exit
$(ColorBlue 'Choose an option:') "
        read a
        case $a in
	        1) selectLab ; menuConf ;;
	        2) setUserAdmin ; menuConf ;;
	        3) setPassword ; menuConf ;;
			4) installSSHkey ; menuConf ;;
			5) installSSHkeyHost; menuConf ;;
		0) menu ;;
		*) echo -e $red"Wrong option, please select a valid option!"$clear;;
        esac
}

function menu0(){
	echo -e "Welcome to $(ColorGreen ClusterFTP) script, you need enter with the admin password for user $(ColorRed $adminUser)!"
	setPassword
	echo -e "If you want change default user ou password to use on the cluster, go to the $(ColorBlue Configuration) menu..."
	echo -e "\n>> Attention, the others hosts in the lab, must have the $adminUser user with the same password used here... <<\n"
	selectLab
}

function menuFile(){
	echo -e "$(ColorGreen File) menu..."
	echo -ne "
	Select an option:
	$(ColorGreen '1)') Copy a file using multicast on the cluster;
	$(ColorGreen '2)') Verify if a file exists in the cluster hosts;
	$(ColorGreen '3)') Download a file from Google Drive to this host only;
	$(ColorGreen '4)') Start UFTPD;
	$(ColorGreen '5)') Stop UFTPD;
	$(ColorGreen '6)') Show and check uftp in cluster;
	$(ColorGreen '0)') Exit
	$(ColorBlue 'Choose an option:') "
	read a
    case $a in
	        1) copyFileMcast ; menuFile ;;
			2) verifyFileCluster_read ; menuFile ;;
			3) downGDrive ; menuFile ;;
			4) startUtftpd ; menuFile ;;
			5) stopUtftpd ; menuFile ;;
			6) checkUtftpd ; menuFile ;;
		0) menu ;;
		*) echo -e $red"Wrong option, please select a valid option!"$clear;;
    esac

}

function executeCommand(){
 echo -e "Execute $(ColorGreen command) on the hosts from the $(ColorRed $lab) cluster ..."
 echo -ne "
 Select an option:
 $(ColorGreen '1)') Execute a command with $adminUser in cluster hosts;
 $(ColorGreen '2)') Execute a command with $(ColorRed sudo) in cluster hosts;
 $(ColorGreen '0)') Exit
 $(ColorBlue 'Choose an option:') "
 read a
 case $a in
       1) executeCommandCluster ; executeCommand ;;
       2) executeSudoCommandCluster; executeCommand ;;
	0) menu ;;
	*) echo -e $red"Wrong option, please select a valid option!"$clear;;
 esac
}

function menuOnOff(){
	echo -e "Turn $(ColorGreen on/off) hosts from $(ColorRed $lab) cluster..."
	echo -ne "
	Select an option:
	$(ColorGreen '1)') Wakeup all hosts from the cluster;
	$(ColorGreen '2)') Shutdown all hosts from the cluster;
	$(ColorGreen '0)') Exit
	$(ColorBlue 'Choose an option:') "
        read a
        case $a in
	        1) wakeuphosts ; menuOnOff ;;
	        2) shutdownAllHosts; menuOnOff ;;
		0) menu ;;
		*) echo -e $red"Wrong option, please select a valid option!"$clear;;
        esac

}


function menu(){
#showHostLab
echo -ne "
Script to copy files using multicast, please select an option:
$(ColorGreen '1)') Show and check hosts in cluster;
$(ColorGreen '2)') Copy files on the cluster;
$(ColorGreen '3)') Execute commands in cluster;
$(ColorGreen '4)') Configuration;
$(ColorGreen '5)') Turn on/off hosts in the cluster;
$(ColorGreen '0)') Exit.
$(ColorBlue 'Choose an option:') "
        read a
        case $a in
	        1) showHostLab ; menu ;;
	        2) menuFile ; menu ;;
	        3) executeCommand ; menu ;;
	        4) menuConf; menu ;;
	        5) menuOnOff ; menu ;;
		0) exit 0 ;;
		*) echo -e $red"Wrong option, please select a valid option!"$clear; menu;;
        esac
}


# start - check for dependences
if ! [ -x "$(command -v sshpass)" ]; then
	echo "Error: sshpass is not installed."
	echo -e "Please install sshpass - apt install sshpass"
	exit 0
fi
if ! [ -x "$(command -v wakeonlan)" ]; then
	echo "Error: wakeonlan is not installed."
	echo -e "Please install sshpass - apt install wakeonlan"
	exit 0
fi
#
menu0

