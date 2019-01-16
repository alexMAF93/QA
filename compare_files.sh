#!/bin/bash

for i in `cat test1`
do

grep -qi $i test2 || echo $i
done

