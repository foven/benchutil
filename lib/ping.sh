#!/bin/bash


isusing ()
{
  #0 is used 1 is unused
  ping $1 -c 3 -i 3 > /dev/null 2>&1
  return $?
}


for n in `seq 1 255`;
do
  isusing 172.16.133.${n}
  [ $? -ne 0 ] && echo "172.16.133.${n} is unused"
done
