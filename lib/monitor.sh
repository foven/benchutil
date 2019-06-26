#!/bin/bash
#. benchutil.sh
#. ../config.sh

startMoniter() {
  echoNormal "starting moniter..."
  for node in ${computeNodes[*]} ${Machines[*]}
  do
    cpuMoniter ${node}
    diskMoniter ${node}
    memMoniter ${node}
    networkMoniter ${node}
    echoGreen "${node} started\r"
  done
  echoGreen "\r\n"
}

stopMoniter() {
  echoNormal "stoping moniter.."
  for node in ${computeNodes[*]} ${Machines[*]}
  do
    sshCmdNO "pkill sar" ${node}
    echoGreen "${node} stoped\r"
  done
  echoGreen "\r\n"
}

cpuMoniter() {
  sshCmdNO "export LC_TIME=\"POSIX\";sar -P ALL ${INTERVALTIME} > ${REMOTEDIR}/cpu.log&" $1
}

diskMoniter() {
  sshCmdNO "export LC_TIME=\"POSIX\";sar -dp ${INTERVALTIME} > ${REMOTEDIR}/disk.log&" $1
}

memMoniter(){
  sshCmdNO "export LC_TIME=\"POSIX\";sar -r ${INTERVALTIME} > ${REMOTEDIR}/mem.log&" $1
}

networkMoniter(){
  sshCmdNO "export LC_TIME=\"POSIX\";sar -n DEV ${INTERVALTIME} > ${REMOTEDIR}/network.log&" $1
}

cpLogs(){
  echoNormal "copy back logs"
  for node in ${!computeNodes[*]} 
  do
    path=${RESULTDIR}/$1/${node}
    mkdir -p ${path}
    cpFile root@${computeNodes[${node}]}:${REMOTEDIR}/cpu.log ${path}/CPU_$1.log
    cpFile root@${computeNodes[${node}]}:${REMOTEDIR}/disk.log ${path}/DISK_$1.log
    cpFile root@${computeNodes[${node}]}:${REMOTEDIR}/mem.log ${path}/MEM_$1.log
    cpFile root@${computeNodes[${node}]}:${REMOTEDIR}/network.log ${path}/NET_$1.log
    echoGreen "${node} success\r"
  done

  for node in  ${!Machines[*]}
  do
    path=${RESULTDIR}/$1/${node}
    mkdir -p ${path}
    cpFile root@${Machines[${node}]}:${REMOTEDIR}/cpu.log ${path}/CPU_$1.log
    cpFile root@${Machines[${node}]}:${REMOTEDIR}/disk.log ${path}/DISK_$1.log
    cpFile root@${Machines[${node}]}:${REMOTEDIR}/mem.log ${path}/MEM_$1.log
    cpFile root@${Machines[${node}]}:${REMOTEDIR}/network.log ${path}/NET_$1.log
    echoGreen "${node} success\r"
  done
  echoGreen "\r\n"
  
}
#echo ${computeNodes[@]}
#echo ${!computeNodes[@]}
#init
#startMoniter
#sleep 600
#stopMoniter
#cpLogs test

