#$/bin/bash 
. config.sh

TIME=0
StartTime=`date +%s`
while :
do
  sleep 10
  for node in ${!Machines[*]}
  do
    path=$1/${node}
    mkdir -p ${path}
    /usr/bin/time -p sshpass -p hengtian ssh ${Machines[${node}]} 'echo hello > /dev/null' 2>&1 | awk '{if($1 == "real"){print $2;}}' >> ${path}/ssh.log
    ping ${Machines[${node}]} -c 1 |grep "time=" |awk '{print $7}' | awk -F'=' '{print $2}' >> ${path}/ping.log
  done
  ET=`date +%s`
  TIME=`expr ${ET} - ${StartTime}`
  [ ${TIME} -gt  ${RUNTIME} ] && break
done 

