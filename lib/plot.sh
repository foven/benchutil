#!/bin/bash
#. ../config.sh
#. parse.sh
#. benchutil.sh

cpuPlot(){
  path=$1
  filename=$2
  for val in $3
  do
  gnuplot<<EOF
set term png
set output "${path}/${filename}_${val}.png"
set ylabel "util(%)"
set grid
stats '${path}/${filename}_${val}.log' using 3 name 'user' nooutput
stats '${path}/${filename}_${val}.log' using 5 name 'sys' nooutput
stats '${path}/${filename}_${val}.log' using 6 name 'IO' nooutput
stats '${path}/${filename}_${val}.log' using 7 name 'stl' nooutput
xtitle(x,n)=sprintf("%s %.2f\%",x,n)
set title "Total cpu utilization"
plot '${path}/${filename}_${val}.log' u :3 title xtitle("user",user_mean) w line, \
     '${path}/${filename}_${val}.log' u :5 title xtitle("sys",sys_mean) w line, \
     '${path}/${filename}_${val}.log' u :6 title xtitle("iowait",IO_mean) w line, \
     '${path}/${filename}_${val}.log' u :7 title xtitle("steal",stl_mean) w line
EOF
  done
}

diskUtilPlot()
{
  path=$1
  filename=$2
  gnuplot<<EOF
set term png
set output "${path}/${filename}_${3}_util.png"
mtitle(n)=sprintf("%s throughput and util",n)
set title mtitle("${3}")
set ylabel "util(%)"
set y2label "throghput(MB/s)"
set y2tics
set grid
ytitle(x,n)=sprintf("%s %.2f\%",x,n)
xtitle(x,n)=sprintf("%s %.2fMB",x,n)
stats '${path}/${filename}_${3}.log' using 10 name 'utl' nooutput
stats '${path}/${filename}_${3}.log' using 4 name 'read' nooutput
stats '${path}/${filename}_${3}.log' using 5 name 'write' nooutput
plot '${path}/${filename}_${3}.log' u :10 title ytitle("Utilazation",utl_mean) w line axis x1y1, \
     '${path}/${filename}_${3}.log' u :(\$4/2048) title xtitle("read",read_mean/2048) w line axis x1y2, \
     '${path}/${filename}_${3}.log' u :(\$5/2048) title xtitle("write",write_mean/2048) w line axis x1y2
EOF
}

diskTpsPlot()
{
  path=$1
  filename=$2
  gnuplot<<EOF
set term png
set output "${path}/${filename}_${3}_tps.png"
mtitle(n)=sprintf("%s throughput and util",n)
set title mtitle("${3}")
set ylabel "tps"
set y2label "time(ms)"
set y2tics
set grid
stats '${path}/${filename}_${3}.log' using 3 name 'tps' nooutput
xtitle(x,n)=sprintf("%s %.2f",x,n)

plot '${path}/${filename}_${3}.log' u :3 title xtitle("TPS",tps_mean) w line axis x1y1, \
     '${path}/${filename}_${3}.log' u :8 title 'await' w line axis x1y2, \
     '${path}/${filename}_${3}.log' u :9 title 'svctm' w line axis x1y2
EOF
}

diskPlot()
{
  for val in $3
  do
    diskUtilPlot $1 $2 ${val}
    diskTpsPlot $1 $2 ${val}
  done
  
}

netPlot()
{
  path=$1
  filename=$2
  for val in $3
  do
   gnuplot<<EOF
set term png
set output "${path}/${filename}_${val}.png"
set title "network throghput"
set y2label "thoughput(MB/s)"
set ylabel "packages(pk/s)"
set y2tics
set grid
stats '${path}/${filename}_${val}.log' using 5 name 'rcv' nooutput
stats '${path}/${filename}_${val}.log' using 6 name 'snd' nooutput
xtitle(x,n)=sprintf("%s %.2fMB",x,n)

plot '${path}/${filename}_${val}.log' u :3 title 'receive(pck)' w line axis x1y1, \
     '${path}/${filename}_${val}.log' u :4 title 'send(pack)' w line axis x1y1, \
     '${path}/${filename}_${val}.log' u :(\$5/1024) title xtitle("receive(throughput)",rcv_mean/1024) w line axis x1y2, \
     '${path}/${filename}_${val}.log' u :(\$6/1024) title xtitle("send(throughput)",snd_mean/1024) w line axis x1y2
EOF
  done
}


memPlot()
{
  path=$1
  filename=$2
  gnuplot<<EOF
set term png
set output "${path}/${filename}.png"
set title "memory stat"
set ylabel "util(%)"
set y2label "used(GB)"
set y2tics
set grid
plot '${path}/${filename}.log' u :4 title 'util' w line axis x1y1, \
     '${path}/${filename}.log' u :(\$3/1048576) title 'used mem' w line axis x1y2, \
     '${path}/${filename}.log' u :(\$6/1048576) title 'cached' w line axis x1y2, \
     '${path}/${filename}.log' u :(\$5/1048576) title 'bufferd' w line axis x1y2
EOF
}

sshPlot()
{
  path=$1
  filename=$2
  gnuplot<<EOF
set term png
set output "${path}/${filename}.png"
set title "ssh latency"
set ylabel "time(s)"
set grid
stats '${path}/${filename}.log' using 1 name 'ssh' nooutput
xtitle(x,n)=sprintf("%s %.2fs",x,n)
plot '${path}/${filename}.log' u :1 title xtitle("time",ssh_mean) w line axis x1y1
EOF
}

pingPlot()
{
  path=$1
  filename=$2
  gnuplot<<EOF
set term png
set output "${path}/${filename}.png"
set title "ping latency"
set ylabel "time(ms)"
set grid
stats '${path}/${filename}.log' using 1 name 'ssh' nooutput
xtitle(x,n)=sprintf("%s %.2fms",x,n)
plot '${path}/${filename}.log' u :1 title xtitle("time",ssh_mean) w line axis x1y1
EOF
}



plotAll() {
  echoGreen "drawing graphs..."
  for key in ${!computeNodes[*]}
  do
    path=${RESULTDIR}/$1/${key}
    parseAll ${path}/CPU_${1} "${computeCPU}"
    cpuPlot ${path} CPU_${1} "${computeCPU}"
    memPlot ${path} MEM_${1} 
    parseAll ${path}/DISK_${1} "${computeDISK}"
    diskPlot ${path} DISK_${1} "${computeDISK}"
    parseAll ${path}/NET_${1}  "${computeNet}"
    netPlot  ${path} NET_${1}  "${computeNet}"
  done

  for key in ${!Machines[*]}
  do
    path=${RESULTDIR}/$1/${key}
    parseAll ${path}/CPU_${1} "${MachineCPU}"
    cpuPlot ${path} CPU_${1} "${MachineCPU}"
    memPlot ${path} MEM_${1}
    parseAll ${path}/DISK_${1} "${MachineDISK}"
    diskPlot ${path} DISK_${1} "${MachineDISK}"
    parseAll ${path}/NET_${1}  "${MachineNet}"
    netPlot  ${path} NET_${1}  "${MachineNet}"
    sshPlot ${path} ssh
    pingPlot ${path} ping
  done
}

#plotAll test

