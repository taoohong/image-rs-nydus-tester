#/bin/bash

list=$(mount -l | grep -E '/tmp/.tmp*' | awk '{print $1"|"$3"|"$5}') 
for i in $list;do
   info=(`echo $i | tr '|' ' '`)
   umount ${info[1]} 
   echo ${info[0]} "type" ${info[2]} "umount from" ${info[1]} 
done
rm -rf /tmp/.tmp*
echo "all test tmp files deleted!"

