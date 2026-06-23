#!/usr/bin/env bash
set -x 

outputfile=$INFO_FILE

wait_time=30

echo "sleeping for $wait_time seconds to wait for output ..."
sleep $wait_time
 
# terraform output > $outputfile

login_command=$LOGIN_COMMAND
echo "The login command is: $LOGIN_COMMAND"

key=$(echo $login_command | awk '{print $3}')
login=$(echo $login_command | awk '{print $4}' | awk -F\" '{print $1}')
remote_host=$(echo $login_command | awk -F@ '{print $2}' | awk -F\" '{print $1}')

echo "remote_host: $remote_host"
ssh-keyscan -H $remote_host >> ~/.ssh/known_hosts

echo "Copying deployment.info to head node"
echo "++++++++++++++++++++++++++++++++++++"
echo "scp -i $key -p $outputfile ${login}:~/$outputfile"

scp -i $key -p $outputfile ${login}:~/$outputfile

