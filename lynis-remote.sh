#!/bin/bash


while getopts s:u:p: option
do
case "${option}"
in
s) server=${OPTARG};;
u) username=${OPTARG};;
p) password=${OPTARG};;
esac
done


if test -z "$server" 
then
      read -p 'Server: ' server
fi
if test -z "$username" 
then
      read -p 'Username: ' username
fi
if test -z "$password" 
then
      read -sp 'Password: ' password
fi


echo "*************SERVER" $server USERNAME $username PASSWORD $password


echo "* Step 1: Create tarball"
# mkdir -p ./files && cd .. && tar czf ./lynis/files/lynis-remote.tar.gz --exclude=files/lynis-remote.tar.gz ./lynis && cd lynis

echo "* Step 2: Copy tarball to target 172.21.41.41"
sshpass -p $password scp -o "StrictHostKeyChecking no" -q ./files/lynis-remote.tar.gz $username@$server:~/tmp-lynis-remote.tgz

echo "* Step 3: Execute audit command"
sshpass -p $password  ssh $username@$server "mkdir -p ~/tmp-lynis && cd ~/tmp-lynis && tar xzf ../tmp-lynis-remote.tgz && rm ../tmp-lynis-remote.tgz && cd lynis && ./lynis audit system"

echo "* Step 4: Clean up directory"
sshpass -p $password  ssh $username@$server "rm -rf ~/tmp-lynis"

echo "* Step 5: Retrieve log and report"
sshpass -p $password  scp -q $username@$server:/tmp/lynis.log ./files/$server-lynis.log
sshpass -p $password  scp -q $username@$server:/tmp/lynis-report.dat ./files/$server-lynis-report.dat

echo "* Step 6: Clean up tmp files (when using non-privileged account)"
sshpass -p $password  ssh $username@$server "rm /tmp/lynis.log /tmp/lynis-report.dat"

echo "* Step 7: Convert report to HTML"
lynis-report-converter/lynis-report-converter.pl -i files/$server-lynis-report.dat -o files/$server-lynis-report.html 

