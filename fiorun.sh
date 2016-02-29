#!/usr/bin/bash
LOGDIR=./log
TESTDIR=$LOGDIR/`date +%Y%m%d%H%M$1`
REMOTEDIR=/tmp
INTERVALTIME=10
SHPSW=hengtian
trap 'abort' INT


declare -A computeNodes
computeNodes=([compute1]="172.16.133.11" \
              [compute2]="172.16.133.12" \
              [compute3]="172.16.133.13" \
              [compute4]="172.16.133.14")

declare -A Nodes
Nodes=([node1-1]="172.16.133.31" \
       [node2-1]="172.16.133.32" \
       [node3-1]="172.16.133.33" \
       [node4-1]="172.16.133.34")


#BLOCKS="1024k" 
BLOCKS="4k 64K 256K 1024K" 
DEPTH="4 32"
RW="rw randrw"

SIZE="200G"
ENGINE="libaio"
DIRECT=1
RUNTIME=300
NUMJOBS="1"
MC=1111

abort()
{
  echo "===========exiting==========="
  
  for k in ${!computeNodes[*]}
  do
    stop_moniter ${computeNodes[${k}]}
  done
  
  for node in ${!Nodes[*]}
  do
    stop_moniter ${Nodes[${node}]}
    sshpass -p ${SHPSW} ssh -o StrictHostKeyChecking=no ${Nodes[${node}]} 'pkill fio'
    #sshpass -p ${SHPSW} ssh ${Nodes[${node}]} 'pkill ping'
  done
  #rmdata
  exit 1
}

init()
{
  for node in ${!computeNodes[*]} ${!Nodes[*]}
  do
    mkdir -p ${TESTDIR}/${node}
  done
}

start_moniter()
{
  echo "=========start moniter $1==========="
  eval "sshpass -p ${SHPSW} ssh $1 'sar -P ALL ${INTERVALTIME} > ${REMOTEDIR}/cpu.log&'"
  eval "sshpass -p ${SHPSW} ssh $1 'sar -dp ${INTERVALTIME} > ${REMOTEDIR}/disk.log&'"
  eval "sshpass -p ${SHPSW} ssh $1 'sar -n DEV ${INTERVALTIME} > ${REMOTEDIR}/network.log&'"  
  eval "sshpass -p ${SHPSW} ssh $1 'sar -r ${INTERVALTIME} > ${REMOTEDIR}/mem.log&'"  
}

stop_moniter()
{
  echo "=========stop moniter=========="
  sshpass -p ${SHPSW} ssh -o StrictHostKeyChecking=no $1 'pkill sar'
}

rmdata()
{
  for key in ${!Nodes[*]}
  do
    sshpass -p ${SHPSW} ssh -o StrictHostKeyChecking=no ${Nodes[${key}]} "rm -f /root/hzbank.*"
  done
}
remotecmd()
{
  echo "=========$1 $2========="
  ret=`sshpass -p ${SHPSW} ssh $1 $2`
  #echo "ret=${ret}"
  #return ${ret}
}

chkprocess()
{
  #set -x
  ret=`eval "sshpass -p ${SHPSW} ssh $1 'ps -ef | grep $2 | grep -v grep|grep -v $2run.sh 2>&1>/dev/null;echo \\$?'"`
  #set +x
  #echo "ret=${ret}"
  echo -e "========`date` check $2 in $1 ret=${ret}======="
  return ${ret}
}

copylog()
{
  sshpass -p ${SHPSW} scp -o StrictHostKeyChecking=no root@${1}:${REMOTEDIR}/cpu.log ${2}/cpu_${3}.log
  sshpass -p ${SHPSW} scp -o StrictHostKeyChecking=no root@${1}:${REMOTEDIR}/disk.log ${2}/disk_${3}.log
  sshpass -p ${SHPSW} scp -o StrictHostKeyChecking=no root@${1}:${REMOTEDIR}/network.log ${2}/network_${3}.log
  sshpass -p ${SHPSW} scp -o StrictHostKeyChecking=no root@${1}:${REMOTEDIR}/mem.log ${2}/mem_${3}.log
}

parse()
{
  eval "cat $1/$2.log | awk 'BEGIN{\$OFS=\",\"}{if( \$3 == \"$3\"){print \$0}}'>$1/$2_$3.log"  
}

cpuplot()
{
  gnuplot<<EOF
set term png
set output "$1/$2.png"
set ylabel "util(%)"
set grid
set title "Total cpu utilization"
plot '$1/$2.log' u :4 title 'user' w line, \
     '$1/$2.log' u :6 title 'system' w line, \
     '$1/$2.log' u :7 title 'iowait' w line, \
     '$1/$2.log' u :8 title 'steal' w line
EOF
}

disk1plot()
{
  gnuplot<<EOF
set term png
set output "$1/$2_util.png"
set title "disk util and throghput"
set ylabel "util(%)"
set y2label "throghput(512byte/s)"
set y2tics
set grid
plot '$1/$2.log' u :11 title 'Utilazation' w line axis x1y1, \
     '$1/$2.log' u :5 title 'read' w line axis x1y2, \
     '$1/$2.log' u :6 title 'write' w line axis x1y2
EOF
}

disk2plot()
{
  gnuplot<<EOF
set term png
set output "$1/$2_tps.png"
set title "disk tps and waittime"
set ylabel "tps"
set y2label "time(ms)"
set y2tics
set grid
plot '$1/$2.log' u :4 title 'TPS' w line axis x1y1, \
     '$1/$2.log' u :9 title 'await' w line axis x1y2, \
     '$1/$2.log' u :10 title 'svctm' w line axis x1y2
EOF
}

diskplot()
{
  disk1plot $1 $2
  disk2plot $1 $2
}

netplot()
{
  gnuplot<<EOF
set term png
set output "$1/$2.png"
set title "network throghput"
set ylabel "thoughput(kB/s)"
set y2label "packages(pk/s)"
set y2tics
set grid
plot '$1/$2.log' u :6 title 'receive' w line axis x1y1, \
     '$1/$2.log' u :7 title 'send' w line axis x1y1, \
     '$1/$2.log' u :4 title 'receive' w line axis x1y2, \
     '$1/$2.log' u :5 title 'send' w line axis x1y2
EOF
}

memplot()
{
  gnuplot<<EOF
set term png
set output "$1/$2.png"
set title "memory stat"
set ylabel "util(%)"
set y2label "used(KB)"
set y2tics
set grid
plot '$1/$2.log' u :5 title 'util' w line axis x1y1, \
     '$1/$2.log' u :4 title 'used mem' w line axis x1y2, \
     '$1/$2.log' u :7 title 'cached' w line axis x1y2, \
     '$1/$2.log' u :6 title 'bufferd' w line axis x1y2
EOF
}

loop()
{
  for key in ${!computeNodes[*]}
  do
    $1 ${computeNodes[${key}]} "$2"
  done 

  for key in ${!Nodes[*]}
  do
    $1 ${Nodes[${key}]} "$2"
  done
}

#chkprocess 192.168.20.101 ping
#cpuplot $1 $2
#echo "chk=$?"
#parse $1 $2 $3
#for node in ${!computeNodes[*]}
#do
#  echo "$node:${computeNodes[$node]}"
#done

init

for rw in $RW
do
  for bs in $BLOCKS
  do
    for njobs in $NUMJOBS
    do
      for dep in $DEPTH
      do

        for node in 1
        do
          prefix="engine${ENGINE}_rw${rw}_bs${bs}_io${dep}_njob${njobs}"
          echo "clear mem"
	  loop remotecmd "echo 1 > /proc/sys/vm/drop_caches"

	  echo "start monitor"
	  loop start_moniter
	
	  echo "=============run fio============"
	  for key in ${!Nodes[*]}
	  do
	    set -x
	    #sshpass -p ${SHPSW} ssh ${Nodes[${key}]} 'ping 192.168.10.1 > /dev/null & '
	    eval "sshpass -p ${SHPSW} ssh -o StrictHostKeyChecking=no ${Nodes[${key}]} 'fio -directory=/benchmark -direct=${DIRECT} -numjobs=${njobs} -ioengine=${ENGINE} -size=${SIZE} -lockmem=1 -zero_buffers -time_based -rw=$rw -iodepth=${dep} -bs=${bs} -runtime=${RUNTIME}  -output=${REMOTEDIR}/result.json -name=hzbank > ${REMOTEDIR}/fio.log 2>&1 &'"

	    set +x
	  done

          Time=0
          ST=`date +%s`
          while :
          do
          echo "time:${Time}"
	  FIN=${MC}
	  I=0
            for node in ${!Nodes[*]}
            do
	      chkprocess ${Nodes[${node}]} fio
	      if [ $? != 0 ]
              then
	        x=$[10**${I}]
		#echo ${x}
		FIN=`expr ${FIN} - ${x}`
                #echo ${FIN}
	      fi
              I=`expr ${I} + 1`
            done
	    if [ ${FIN} == 0 ]
            then
	      break
	    fi
            sleep ${INTERVALTIME}
            ET=`date +%s`
            Time=`expr ${ET} - ${ST}`
          done          
          loop stop_moniter

	  echo "==============copy back==========="
	  for key in ${!computeNodes[*]}
	  do
            mkdir -p ${TESTDIR}/${key}/${prefix}
	        copylog ${computeNodes[${key}]} $TESTDIR/${key}/${prefix} ${prefix}
            parse ${TESTDIR}/${key}/${prefix} network_${prefix} eth4
            netplot ${TESTDIR}/${key}/${prefix} network_${prefix}_eth4
            parse ${TESTDIR}/${key}/${prefix} cpu_${prefix} all
            cpuplot ${TESTDIR}/${key}/${prefix} cpu_${prefix}_all
            parse ${TESTDIR}/${key}/${prefix} disk_${prefix} sda
            diskplot ${TESTDIR}/${key}/${prefix} disk_${prefix}_sda
          parse ${TESTDIR}/${key}/${prefix} disk_${prefix} sdb
            diskplot ${TESTDIR}/${key}/${prefix} disk_${prefix}_sdb
            parse ${TESTDIR}/${key}/${prefix} disk_${prefix} sdc
            diskplot ${TESTDIR}/${key}/${prefix} disk_${prefix}_sdc
            parse ${TESTDIR}/${key}/${prefix} disk_${prefix} sdd
            diskplot ${TESTDIR}/${key}/${prefix} disk_${prefix}_sdd
             parse ${TESTDIR}/${key}/${prefix} disk_${prefix} sde
            diskplot ${TESTDIR}/${key}/${prefix} disk_${prefix}_sde
            parse ${TESTDIR}/${key}/${prefix} disk_${prefix} sdf
            diskplot ${TESTDIR}/${key}/${prefix} disk_${prefix}_sdf
            memplot ${TESTDIR}/${key}/${prefix} mem_${prefix}            
	  done
        
          for key in ${!Nodes[*]}
	  do
            mkdir -p ${TESTDIR}/${key}/${prefix}
	        copylog ${Nodes[${key}]} $TESTDIR/${key}/${prefix} ${prefix}
            parse ${TESTDIR}/${key}/${prefix} cpu_${prefix} all
            cpuplot ${TESTDIR}/${key}/${prefix} cpu_${prefix}_all
            parse ${TESTDIR}/${key}/${prefix} disk_${prefix} vda
            diskplot ${TESTDIR}/${key}/${prefix} disk_${prefix}_vda
            memplot ${TESTDIR}/${key}/${prefix} mem_${prefix}
	    #set -x
            sshpass -p ${SHPSW} scp -o StrictHostKeyChecking=no root@${Nodes[${key}]}:${REMOTEDIR}/fio.log ${TESTDIR}/${key}/${prefix}/fio_${prefix}.log
            sshpass -p ${SHPSW} scp -o StrictHostKeyChecking=no root@${Nodes[${key}]}:${REMOTEDIR}/result.json ${TESTDIR}/${key}/${prefix}/result_${prefix}.json
            #set +x
	  done 

        done
      done
    done
  done
done

#rmdata
