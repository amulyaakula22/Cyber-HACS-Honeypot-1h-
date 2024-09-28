#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# This script takes in a container name and an external ip. #
# Copies over the var/log/.downloads folder from the        #
# container and then destroys the container along with      #
# any rules attatched to it. Then it creates a new          #
# container and adds iptable and firewalls rules            #
# along with the original honey                             #  
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

#include <unistd.h>

startTime=$(date)

containerName=$1
externalIP=$2

containerIP=$(sudo lxc-info -iH $containerName)

#cp over .download file from container
sudo cp /var/lib/lxc/$containerName/rootfs/var/log/.downloads /home/student/$containerName/downloaded 
 
#removes any tail stuff
TAIL_PID=$!

#removes NAT rules
sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination $externalIP --jump DNAT --to-destination $containerIP
sudo iptables --table nat --delete POSTROUTING --source $containerIP --destination 0.0.0.0/0 --jump SNAT --to-source $externalIP

#removes MITM rules
sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination "$externalIP" --protocol tcp --dport 22 --jump DNAT --to-destination "$hostIP:$port"
sudo iptables --table nat --delete POSTROUTING --source "$hostIP:$port" --destination 0.0.0.0/0 --protocol tcp --dport 22 --jump SNAT --to-source "$externalIP"

#stops container
sudo lxc-stop -n $containerName

#kills the MITM for this container
taskNum=`sudo forever list | grep $containerName | cut -d "[" -f 2 | cut -d "]" -f 1`
sudo forever stop $taskNum

#deletes the container
sudo lxc-destroy -n $containerName

#folder name based on the current date
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

hostIP="127.0.0.1"
port=$((RANDOM % 500 + 1300))  

# creates the container
sudo lxc-create -n $containerName -t download -- -d ubuntu -r focal -a amd64
sudo lxc-start -n $containerName
sleep 10
containerIP=$(sudo lxc-info -iH $containerName)

# launches the MITM server
sudo sysctl -w net.ipv4.conf.all.route_localnet=1
sudo forever -l $logName -a start "/home/student/MITM/mitm.js" -n $containerName -i $containerIP -p $port --auto-access --auto-access-fixed 2 --debug

# adds iptables rules for the container to the external IP
sudo ip addr add $externalIP/$prefix brd + dev "eth0"
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $externalIP --jump DNAT --to-destination $containerIP
sudo iptables --table nat --insert POSTROUTING --source $containerIP --destination 0.0.0.0/0 --jump SNAT --to-source $externalIP

# adds iptables rules for MITM
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination "$externalIP" --protocol tcp --dport 22 --jump DNAT --to-destination "$hostIP:$port"
sudo iptables --table nat --insert POSTROUTING --source "$hostIP:$port" --destination 0.0.0.0/0 --protocol tcp --dport 22 --jump SNAT --to-source "$externalIP"

sudo lxc-attach -n $containerName -- sh -c "sudo apt install openssh-server"
sudo lxc-attach -n $containerName -- sh -c "sudo apt-get install curl"
sudo lxc-attach -n $containerName -- sh -c "sudo apt-get install wget"

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

#cp command to copy honey
sudo cp -r /home/student/honey/Department1 /var/lib/lxc/$containerName/rootfs/home/
sudo cp -r  /home/student/honey/Department2 /var/lib/lxc/$containerName/rootfs/home/
sudo cp -r  /home/student/honey/Department3 /var/lib/lxc/$containerName/rootfs/home/
sudo cp -r  /home/student/honey/Department4 /var/lib/lxc/$containerName/rootfs/home/
sudo cp -r  /home/student/honey/Department5 /var/lib/lxc/$containerName/rootfs/home/

timerLog=/home/student/$containerName/timer.txt
echo 00:00 > $timerLog

endTime=$(date)

echo "recycling started at $startTime and ended at $endTime"