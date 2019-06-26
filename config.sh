LOGDIR=./log
RESULTDIR=$LOGDIR/`date +%Y%m%d%H%M$1`
#RESULTDIR=/home/siqiwu/benchutil/lib/log/test
REMOTEDIR=/tmp
INTERVALTIME=10
SHPSW=hengtian
computeCPU="all"
computeDISK="sda sdb sdc sdd sde sdf"
computeNet="eth4 eth3"
MachineCPU="all"
MachineDISK="vda"
MachineNet="eth0"

declare -A computeNodes
computeNodes=([compute1]="172.16.133.11" \
              [compute2]="172.16.133.12" \
              [compute3]="172.16.133.13" \
              [compute4]="172.16.133.14")

declare -A Machines
Machines=([node1-1]="172.16.133.30" \
          [node2-1]="172.16.133.60" \
          [node3-1]="172.16.133.90" \
          [node4-1]="172.16.133.120")


#BLOCKS="1024k" 
BLOCKS="4K" 
DEPTH="32"
#RW="read write rw randread randwrite randrw"
#RW="read write rw"
RW="randread randwrite randrw"
#RW="read"
SIZE="10G"
ENGINE="libaio"
DIRECT=1
RUNTIME=3600
NUMJOBS="1"
