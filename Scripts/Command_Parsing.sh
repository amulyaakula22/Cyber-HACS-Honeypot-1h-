#!/bin/bash

# parameters (3): log file location, duration, honey conf number

logFileName=$1
duration=$2
attackerIP=
hash=""

if [ $3 -eq 1 ]
then 
    hash="MD5"

elif [$3 -eq 2 ]
then 
    hash="SHA1"

elif [$3 -eq 2 ]
then 
    hash="SHA256"

elif [$3 -eq 2 ]
then 
    hash="SHA3"

else
    hash="Plain"
fi

if [ ! -d "/home/student/Data/hash/$attackerIP" ]
then
  mkdir "/home/student/Data/hash/$attackerIP"
fi

touch "/home/student/Data/hash/$attackerIp/$logFileName"
commandFile="/home/student/Data/hash/$attackerIp/$logFileName"

cat $logFileName | grep "line from reader" | cut -d ':' -f4 > $commandFile

numCommands=$(cat $logFileName | grep -c "line from reader")

echo "Duration: $duration" >> $commandFile
echo "Attacker IP: $attackerIP" >> $commandFile
echo "Number of Commands: $numCommands" >> $commandFile