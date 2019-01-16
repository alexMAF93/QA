#!/bin/bash


echo "Lista de servere:"
servere=`cat`
for i in $servere
do
echo
echo
echo $i
ssh -q $i "/usr/sbin/prtconf | grep Memory" 2>/dev/null
echo "====================="
ssh -q $i "/usr/sbin/psrinfo -pv | head -1" 2>/dev/null
echo "====================="
echo "The number of CPUs: "
ssh -q $i "/usr/sbin/psrinfo -p | wc -l" 2>/dev/null
echo "====================="
echo
echo

done
