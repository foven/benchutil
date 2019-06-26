#!/bin/bash


#Ubuntu=1,centos=2,Others=3
OSversion=3
echoRed (){
  echo -en "\033[0;31;1m${1}\033[0m"
}

echoGreen(){
  echo -en "                              \r"
  echo -en "\033[0;32;1m${1}\033[0m"
}

echoNormal(){
  echo ${1}
}

chkOSversion(){
  cat /etc/issue | grep -i ubuntu > /dev/null 2>&1
  [ $? -eq 0 ] && OSversion=1
  cat /etc/issue | grep -i centos > /dev/null 2>&1
  [ $? -eq 0 ] && OSversion=2
}


chkLocalSoftware() {
  retcode=0
  echoNormal "checking software..."
  ret=`gnuplot -V`
  if [ $? -ne 0 ]
  then
    echo -en 'gnuplot is not install and installing...\r\n'
    if [ ${OSversion} -eq 1 ]
    then
      apt-get install -y -qq gnuplot > /dev/null 2>&1
      if [ $? -ne 0 ] 
      then
        echoRed "gnuplot can't install, use apt-get install gnuplot for more details\r\n"
        retcode=1
      fi
    elif [ ${OSversion} -eq 2 ]
    then
      yum -y install gnuplot > /dev/null 2>&1
      if [$? -ne 0 ] 
      then
        echoRed "gnuplot can't install, use yum install gnuplot for more details\r\n"
        retcode=1
      fi
    else
      echoRed "need install gnuplot manually\r\n"
      retcode=1
    fi
  fi
  echoGreen "gnuplot installed\r\n"
  
  ret=`sshpass -V`
  if [ $? -ne 0 ]
  then 
    echoNormal "installing sshpass"
    chmod a+x ../tools/sshpass
    cp ../tools/sshpass /usr/bin/
    if [ $? -ne 0 ]
    then
      echoRed "sshpass install failed\r\n"
      retcode=1
    else
      echoGreen "sshpass installded\r\n"
    fi
  fi   
}

sshCmd(){
  sshpass -p ${SHPSW} ssh -o StrictHostKeyChecking=no "$2" "$1" 
  return $?
}

sshCmdNO(){
  sshpass -p ${SHPSW} ssh -o StrictHostKeyChecking=no "$2" "$1" > /dev/null 2>&1
  return $?
}

cpFile(){
  sshpass -p ${SHPSW} scp -o StrictHostKeyChecking=no "$1" "$2" 
  return $?
}

distributeFio() {
  echoNormal "Distribute fio to each machine"
  for machine in ${!Machines[*]}
  do
    sshCmd "fio -v > /dev/null" root@${Machines[${machine}]}
    if [ $? -ne 0 ]
    then 
      cpFile ../tools/fio root@${Machines[${machine}]}:/usr/bin
      [ $? -ne 0 ] && echoRed "${Machines[${machine}]} copy failed\r\n"
    fi
  done 
}

chkRemoteSoftware() {
  echoNormal "checking remote softeare..."
  for machine in ${!Machines[*]}
  do
    sshCmd "sar -V > /dev/null" root@${Machines[${machine}]}
    [ $? -ne 0 ] && echoRed "no sysstat in ${Machines[${machine}]}, use yum install sysstat or apt-get install sysstat to install\r\n"  
  done
}

chkRemoteStat() {
  echoNormal "checking remote is live or password is correct..."
  for machine in ${!Machines[*]}
  do
    sshCmdNO "echo hello > /dev/null" root@${Machines[${machine}]}
    case "$?" in
    0 )
      echoGreen "${Machines[${machine}]} is good\r";;
    5 )
      echoRed "password or username is wrong, ${Machines[${machine}]}\r\n" ;;
    255 )
      echoRed "can't connect to ${Machines[${machine}]}\r\n" ;;
    * )
      ;;
    esac
  done
}

init()
{
  mkdir -p ${RESULTDIR}

  for node in ${computeNodes[*]} ${Machines[*]}
  do
    sshCmdNO "export LC_TIME=\"POSIX\"" root@${node}
  done
}

rmdataFile()
{
  for key in ${!Machines[*]}
  do
    sshpass -p ${SHPSW} ssh -o StrictHostKeyChecking=no ${Nodes[${key}]} "rm -f /root/hzbank.*"
  done
}

chkProcess()
{
  ret=`eval "sshpass -p ${SHPSW} ssh $1 'ps -ef | grep $2 | grep -v grep|grep -v $2run.sh 2>&1>/dev/null;echo \\$?'"`
  return ${ret}
}

cleanMem() {
  echoGreen "clear memory\r\n"
  for node in ${computeNodes[*]} ${Machines[*]}
  do
    sshCmdNO "echo 1 > /proc/sys/vm/drop_caches" ${node}
  done
}

#. ../config.sh
#chkRemoteStat
#chkRemoteSoftware
#distributeFioa
#SHPSW=hengtian
#chkProcess 172.16.133.34 fio
