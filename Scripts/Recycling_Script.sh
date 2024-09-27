# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# This script takes in a container name and an external ip. #
# Copies over the var/log/.downloads folder from the        #
# container and then destroys the container along with      #
# any rules attatched to it. Then it creates a new          #
# container and adds iptable and firewalls rules            #
# along with the original honey                             #  
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

#!/bin/bash
#include <unistd.h>

startTime=$(date -Iseconds)

containerName=$1
externalIP=$2
containerIP=$(sudo lxc-info -iH $containerName)

#cp over .download file from container 

#removes any tail stuff
TAIL_PID = $!

#removes NAT rules
sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination $externalIP --jump DNAT --to-destination $containerIP
sudo iptables --table nat --delete POSTROUTING --source $containerIP --destination 0.0.0.0/0 --jump SNAT --to-source $externalIP

#removes MITM rules
sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination "$externalIP" --protocol tcp --dport 22 --jump DNAT --to-destination "$hostIP:$port"
sudo iptables --table nat --delete POSTROUTING --source "$hostIP:$port" --destination 0.0.0.0/0 --protocol tcp --dport 22 --jump SNAT --to-source "$externalIP" 

#stops and deletes container
sudo lxc-stop -n $containerName
sudo lxc-destroy -n $containerName

#creates a file to store mitm logs
logName=/home/student/logs/(`date "+%m-%d"`)/(`%H:%M:%S`_$containerName)
touch $logName

hostIP="127.0.0.1"
port=12345  

sudo lxc-create -n $containerName -t download -- -d ubuntu -r focal -a amd64
sudo lxc-start -n $containerName
sleep 10
containerIP=$(sudo lxc-info -iH $containerName)

#starts up MITM server for this honeypot
sudo sysctl -w net.ipv4.conf.all.route_localnet=1
sudo forever -l $logName -a start "$(/home/student/MITM/mitm.js)" -n $containerName -i $containerIP -p $port --auto-access --auto-access-fixed 2 --debug

#added nat rules
sudo ip addr add $externalIP/$prefix brd + dev "eth0"
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $externalIP --jump DNAT --to-destination $containerIP
sudo iptables --table nat --insert POSTROUTING --source $containerIP --destination 0.0.0.0/0 --jump SNAT --to-source $externalIP

#added MITM rules
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination "$externalIP" --protocol tcp --dport 22 --jump DNAT --to-destination "$hostIP:$port"
sudo iptables --table nat --insert POSTROUTING --source "$hostIP:$port" --destination 0.0.0.0/0 --protocol tcp --dport 22 --jump SNAT --to-source "$externalIP" 

#poision wget
sudo lxc-attach -n $containerName -- mkdir -p "/var/log/.downloads"
sudo lxc-attach -n $containerName -- sh -c "cp '/usr/bin/wget' '/usr/bin/wgetOG'"
sudo lxc-attach -n $containerName -- sh -c "chmod u+x /usr/bin/wgetOG"
sudo lxc-attach -n $containerName -- sh -c "echo 'NOW=$( date '+%F_%H:%M:%S' )' > '/usr/bin/wget'"
sudo lxc-attach -n $containerName -- sh -c "echo 'wgetOG \$@ -O /var/log/.downloads/\$NOW-$containerName -q /dev/null 2>&1' >> '/usr/bin/wget'"
sudo lxc-attach -n $containerName -- sh -c "echo 'wgetOG \$@' >> '/usr/bin/wget'"

#poison curl
sudo lxc-attach -n $containerName -- sh -c "cp '/usr/bin/curl' '/usr/bin/curlOG'"
sudo lxc-attach -n $containerName -- sh -c "chmod u+x /usr/bin/curlOG"
sudo lxc-attach -n $containerName -- sh -c "echo 'NOW=$( date '+%F_%H:%M:%S' )' > '/usr/bin/curl'"
sudo lxc-attach -n $containerName -- sh -c "echo 'curlOG -O /var/log/.downloads/\$NOW-$containerName \$@ -q /dev/null 2>&1' >> '/usr/bin/curl'"
sudo lxc-attach -n $containerName -- sh -c "echo 'wgetOG \$@' >> '/usr/bin/curl'"

#cp command to copy honey 
#add firewall rules held inside a file and check for fire wall rules that need to be added

endTime=$(date -Iseconds)

echo "recycling started at $startTime and ended at $endTime"
