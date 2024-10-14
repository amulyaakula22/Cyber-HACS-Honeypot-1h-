#!/bin/bash

# parameters (4): container name, external ip, where the mitm log is , honey conf number

logName=$1

while [[ $(tail $logName | grep -c "Attacker authenticated and is inside container") -eq 0 ]];
do
sleep 1;
done

entranceTime=$(date "+%s")
echo $entranceTime

#update iptable rules to not let anyone else in **very important** (remove accept, add block)
sudo iptables --insert INPUT --jump DROP
sudo iptables --insert FORWARD --jump DROP

while [[ ($(($(date "+%s") - $entranceTime)) -lt 600) && ($(tail $logName | grep -c "Attacker closed connection") -eq 0) ]];
do
   sleep 1;
done

exitTime=$(date "+%s")

echo $exitTime
duration=$(($exitTime - $entranceTime))
echo $duration

#container name and external ip
. ./Recycling_Script.sh $1 $2 $duration $logName $4