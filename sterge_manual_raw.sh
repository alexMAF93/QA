#!/bin/bash

LISTA=`/home/oquat/malex/offlineQA_IDs.pl $1`

for i in $LISTA
do

if [[ $i -gt 2707 ]]

then

echo $i
rm -rv /opt/oquat/qualitycenter/data/raw/$i/manual 
echo


fi


done
