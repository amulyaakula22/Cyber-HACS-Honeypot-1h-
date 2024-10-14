#!/bin/bash
#include <unistd.h>

# parameters (5): container name, external ip, previous attacker duration, log file location, honey conf number 

startTime=$(date)

containerName=$1
externalIP=$2
prefix="16"
hostIP="127.0.0.1"
containerIP=$(sudo lxc-info -iH $containerName)

##check this
port="$(head -n 1 /home/student/$containerName/MITMport.txt)"
# port="12353"

#cp over .download file from container
sudo cp -r /var/lib/lxc/$containerName/rootfs/var/log/.downloads /home/student/$containerName/downloaded
#removes any tail stuff
TAIL_PID=$!

#removes NAT rules
sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination $externalIP --jump DNAT --to-destination $containerIP
sudo iptables --table nat --delete POSTROUTING --source $containerIP --destination 0.0.0.0/0 --jump SNAT --to-source $externalIP

#removes MITM rules
sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination "$externalIP" --protocol tcp --dport 22 --jump DNAT --to-destination "127.0.0.1:$port"
sudo iptables --table nat --delete POSTROUTING --source "127.0.0.1:$port" --destination 0.0.0.0/0 --protocol tcp --dport 22 --jump SNAT --to-source "$externalIP"

#stops container
sudo lxc-stop -n $containerName $4

#kills the MITM for this container
taskNum=`sudo forever list 2>/dev/null | grep container1 | cut -d "]" -f 1 | cut -d ":" -f 2 | cut -d "[" -f 2`
sudo forever stop $taskNum

#get logFileName
./Command_Parsing.sh $logFileName $3 $5

#deletes the container
sudo lxc-destroy -n $containerName

#folder name basied on the current date
folderName=`date "+%m-%d"`

#file name based on time of container creation and container name
fileName=`date "+%H:%M:%S"`

#checks if a folder for the current day already exists
if [ ! -d "/home/student/$containerName/$folderName" ]
then
  mkdir /home/student/$containerName/$folderName
fi

logName=/home/student/$containerName/$folderName/$fileName 
touch $logName

##FIX THIS
export MITMport="$(($MITMport + 1))" 

if [ $MITMport -gt 65535 ]
then 
  export MITMport=$((49152))
fi

port="$MITMport";

##CHECK THIS
echo $port > /home/student/$containerName/MITMport.txt

# creates the container
sudo lxc-create -n $containerName -t download -- -d ubuntu -r focal -a amd64
sudo lxc-start -n $containerName
sleep 10
containerIP=$(sudo lxc-info -iH $containerName)

sudo lxc-attach -n $containerName -- sh -c "sudo apt install openssh-server -y"
sudo lxc-attach -n $containerName -- sh -c "sudo apt-get install curl -y"
sudo lxc-attach -n $containerName -- sh -c "sudo apt-get install wget -y"

# launches the MITM server
sudo sysctl -w net.ipv4.conf.all.route_localnet=1
sudo forever -l $logName -a start "/home/student/HACS101/MITM/mitm.js" -n $containerName -i $containerIP -p "$port" --auto-access --auto-access-fixed 2 --debug

# adds iptables rules for the container to the external IP
sudo ip addr add $externalIP"/16" brd + dev "eth0"
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $externalIP --jump DNAT --to-destination $containerIP
sudo iptables --table nat --insert POSTROUTING --source $containerIP --destination 0.0.0.0/0 --jump SNAT --to-source $externalIP

# adds iptables rules for MITM
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination "$externalIP" --protocol tcp --dport 22 --jump DNAT --to-destination "127.0.0.1:$port"
sudo iptables --table nat --insert POSTROUTING --source "127.0.0.1:$port" --destination 0.0.0.0/0 --protocol tcp --dport 22 --jump SNAT --to-source "$externalIP"

#poison wget
sudo lxc-attach -n $containerName -- mkdir -p "/var/log/.downloads"
sudo lxc-attach -n $containerName -- sh -c "cp '/bin/wget' '/bin/wgetOG'"
sudo lxc-attach -n $containerName -- sh -c "chmod u+x /bin/wgetOG"
sudo lxc-attach -n $containerName -- sh -c "echo 'NOW=$( date '+%F_%H:%M:%S' )' > '/bin/wget'"
sudo lxc-attach -n $containerName -- sh -c "echo 'wgetOG \$@ -O /var/log/.downloads/\$NOW-$containerName -q /dev/null 2>&1' >> '/bin/wget'"
sudo lxc-attach -n $containerName -- sh -c "echo 'wgetOG \$@' >> '/bin/wget'"

#poison curl
sudo lxc-attach -n $containerName -- sh -c "cp '/bin/curl' '/bin/curlOG'"
sudo lxc-attach -n $containerName -- sh -c "chmod u+x /bin/curlOG"
sudo lxc-attach -n $containerName -- sh -c "echo 'NOW=$( date '+%F_%H:%M:%S' )' > '/bin/curl'"
sudo lxc-attach -n $containerName -- sh -c "echo 'curlOG -O /var/log/.downloads/\$NOW-$containerName \$@ -q /dev/null 2>&1' >> '/bin/curl'"
sudo lxc-attach -n $containerName -- sh -c "echo 'wgetOG \$@' >> '/bin/curl'"

#auto-logout users who are inactive on the command line for 2 min
sudo lxc-attach -n $containerName -- sh -c "echo 'export TMOUT=10' >> /etc/bash.bashrc"

#randomly assigns a honey configuration tot he honeypot
randomNum=$((RANDOM % 5 + 1))
honeyFolderName=honeyConfig$randomNum
sudo cp -r /home/student/honey/$honeyFolderName/Cardiology /var/lib/lxc/$containerName/rootfs/home/
sudo cp -r  /home/student/honey/$honeyFolderName/Orthopedics /var/lib/lxc/$containerName/rootfs/home/
sudo cp -r  /home/student/honey/$honeyFolderName/Radiology /var/lib/lxc/$containerName/rootfs/home/
sudo cp -r  /home/student/honey/$honeyFolderName/Pedeatrics /var/lib/lxc/$containerName/rootfs/home/
sudo cp -r  /home/student/honey/$honeyFolderName/Hematology /var/lib/lxc/$containerName/rootfs/home/

sudo iptables --delete INPUT --jump DROP
sudo iptables --delete FORWARD --jump DROP

endTime=$(date)
echo "recycling started at $startTime and ended at $endTime"

#container name and external ip
. ./Data_Collection_Script.sh $1 $2 $logName $randomNum