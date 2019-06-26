#!/bin/bash
#. ../config.sh
#a="vda"

parseAll() {
  for val in $2
  do
    parse $1 ${val}
  done
}

parse(){
  file=$1
  eval "cat ${file}.log | awk 'BEGIN{\$OFS=\",\"}{if( \$2 == \"$2\"){print \$0}}'>${file}_${2}.log"
}
#echo $a
#parseAll /home/siqiwu/benchutil/lib/log/test/node1-1/test/DISK_test "${a}"
#p 1 2 3 4 5 6
