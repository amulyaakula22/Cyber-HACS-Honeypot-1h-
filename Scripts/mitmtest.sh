#!/bin/bash
#include <unistd.h>


externalIP="172.30.250.135"
port="12351"
containerName="container1"

logName=/home/student/logName
# touch $logName

# creates the container
sudo lxc-create -n $containerName -t download -- -d ubuntu -r focal -a amd64 && sudo lxc-start -n $containerName
sleep 10
containerIP=$(sudo lxc-info -iH container1)

sudo lxc-attach -n $containerName -- sh -c "sudo apt install openssh-server -y"

# launches the MITM server
sudo sysctl -w net.ipv4.conf.all.route_localnet=1
sudo forever -l /home/student/logFile -a start "/home/student/HACS101/MITM/mitm.js" -n $containerName -i $containerIP -p $port --auto-access --auto-access-fixed 1 --debug

# adds iptables rules for the container to the external IP
sudo ip addr add $externalIP"/16" brd + dev "eth0"
sudo iptables --table nat --insert PREROUTING --source "0.0.0.0/0" --destination $externalIP --jump DNAT --to-destination $containerIP
sudo iptables --table nat --insert POSTROUTING --source $containerIP --destination "0.0.0.0/0" --jump SNAT --to-source $externalIP

# adds iptables rules for MITM
sudo iptables --table nat --insert PREROUTING --source "0.0.0.0/0" --destination $externalIP --protocol tcp --dport 22 --jump DNAT --to-destination "127.0.0.1:"$port
sudo iptables --table nat --insert POSTROUTING --source "127.0.0.1:"$port --destination "0.0.0.0/0" --protocol tcp --dport 22 --jump SNAT --to-source $externalIP


sudo lxc-attach -n $containerName -- sh -c "echo 'export TMOUT=20' >> /etc/bash.bashrc"