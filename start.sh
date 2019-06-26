#!/bin/bash

. config.sh
. lib/monitor.sh
. lib/benchutil.sh
. lib/fio.sh
. lib/plot.sh
. lib/parse.sh
 
trap 'abort' INT QUIT


abort() {
  echoRed "Aborting...\r\n"
  stopMoniter
  stopAllFio
  getBackLogs ${prefix}
  cpLogs ${prefix}
  ps -ef |grep SSH.sh |grep -v grep | awk '{print $2}' | xargs kill -9 
  kill -9 $$
  exit
}

getSsh() {
  for node in ${!Machines[*]}
  do
    /usr/bin/time -p sshCmdNO "echo hello" root@${Machines[${node}]} | awk '{if($1 == "real"){print $2;}}'
  done
}

main(){
  init
  for rw in $RW
  do
    for bs in $BLOCKS
    do
      for njobs in $NUMJOBS
      do
        for dep in $DEPTH
        do
          prefix="engine${ENGINE}_rw${rw}_bs${bs}_io${dep}_njob${njobs}"
          echoGreen "${rw} ${bs} ${njobs} ${dep}\r\n"
          cleanMem
          startMoniter
          startAllFio ${rw} ${bs} ${njobs} ${dep}
          ./SSH.sh ${RESULTDIR}/${prefix} &
          TIME=0
          StartTime=`date +%s` 
          while :
          do
            sleep 10
            echoGreen "Time:$TIME\r\n"
            checkFioStatus $TIME
            [ $? -eq 1 ] && break
            ET=`date +%s`
            TIME=`expr ${ET} - ${StartTime}`            
          done
          stopMoniter
          cpLogs  ${prefix}
          plotAll ${prefix}
          getBackLogs ${prefix}         
        done
      done
    done
  done
}

main
