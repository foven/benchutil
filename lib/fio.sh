#!bin/bash
#. benchutil.sh
#. ../config.sh
startFio (){
  sshCmd "fio -directory=/root -direct=${DIRECT} -numjobs=$4 -ioengine=${ENGINE} -size=${SIZE} -lockmem=1 -zero_buffers -time_based -rw=$2 -iodepth=$5 -bs=$3 -runtime=${RUNTIME}  -output=${REMOTEDIR}/result.json -name=hzbank > ${REMOTEDIR}/fio.log 2>&1 &" $1
  [ $? -ne 0 ] && echoRed "Can't start fio on $1\r\n"
}

startAllFio() {
  echoGreen "starting fio.."
  for node in ${!Machines[*]}
  do
    echoGreen "starting fio on ${node}...\r"
    startFio ${Machines[${node}]} $1 $2 $3 $4
  done 
}

stopAllFio() {
  echoGreen "stoping fio...\r\n"
  for node in ${!Machines[*]}
  do
    sshCmdNO "pkill fio" ${Machines[${node}]}
  done
}

checkFioStatus() {
  FIN=1
  for node in ${!Machines[*]}
  do
    chkProcess ${Machines[${node}]} fio
    if [ $? -ne 0 ]
    then 
      if [ $1 -lt ${RUNTIME} ]
      then
        echoRed "${node} is abort\r\n"
      else 
        echoGreen "${node} is finish\r\n"
      fi
    else
      echoGreen "${node} is running...\r\n"
      FIN=0
    fi
  done
  return ${FIN}  
}

getBackLogs(){
  for node in ${!Machines[*]}
  do
    path=${RESULTDIR}/$1/${node}
    mkdir -p path
    cpFile root@${Machines[${node}]}:${REMOTEDIR}/fio.log ${path}/fio_$1.log
    cpFile root@${Machines[${node}]}:${REMOTEDIR}/result.json ${path}/result_$1.log
  done 
}
