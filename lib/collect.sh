#!/usr/bin/bash
declare -A num

doSomeThing() {
  
  declare -A sum
  for dir in `ls $1`
  do
    arr=(${dir/-/ /})
    nodename=${arr[0]}
    [ ${nodename%%[[:digit:]]} = "compute" ] && continue
    ((num[${nodename}]=${num[${nodename}]}+1))
    result=`eval "cat $1/$dir/result* | perl -ne 'print \\$1 if /$2.*$3=([[:digit:]]*\.?[[:digit:]]*[KMG]?B?)/;'"`
    #echo ${result}
    unit=`echo ${result} | grep -Po "[KMG]?B"`
    [ ! ${sum[${nodename}]}  ] && sum[${nodename}]=0
    
    case $unit in
      "KB")
         #echo ${result%%.*}
         sum[${nodename}]=`bc <<< ${result%%K*}+${sum[${nodename}]}`
         ;;
      "B")
        sum[${nodename}]=`bc <<<${result%%[[:alpha:]]*}/1024+${sum[${nodename}]}`
        ;;
      "MB")
        sum[${nodename}]=`bc <<<${result%%M*}*1024+${sum[${nodename}]}`
        ;;
      "GB")
        sum[${nodename}]=`bc <<<${result%%G*}*1024*1024+${sum[${nodename}]}`
        ;;
      *)
        ((sum[${nodename}]=${result}+${sum[${nodename}]}))
        ;;
    esac
   #echo ${sum[${nodename}]}
  done

  #((sum[${nodename}]=$sum[${nodename}]/1024))
  for key in ${!sum[*]}
  do 
    final="${final} ${key} ${sum[${key}]}"
  done
  echo $final
  
}

summary() {
  case $2 in
  "rw")
    readspd=`doSomeThing $1 read bw`
    writespd=`doSomeThing $1 write bw`
    ;;
  "randrw")
    readspd=`doSomeThing $1 read iops`
    writespd=`doSomeThing $1 write iops`
    ;;
  "read")
    readspd=`doSomeThing $1 read bw`
    ;;
  "write")
    writespd=`doSomeThing $1 write bw`
    ;;
  "randread")
    readspd=`doSomeThing $1 read iops`
    ;;
  "randwrite")
    writespd=`doSomeThing $1 write iops`
    ;;
  *)
    ;;
  esac

  echo read:${readspd}
  echo write:${writespd}
}


summary $1 $2

#doSomeThing $1 read iops
