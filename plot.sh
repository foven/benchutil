#!/bin/bash

. config4p.sh
. lib/plot.sh
. lib/parse.sh


#  for key in ${!Machines[*]}
#  do
#    memPlot ${RESULTDIR}/${key}/enginelibaio_rwwrite_bs256K_io32_njob1 MEM_enginelibaio_rwwrite_bs256K_io32_njob1
#  done
plotAll enginelibaio_rwread_bs4K_io32_njob1
