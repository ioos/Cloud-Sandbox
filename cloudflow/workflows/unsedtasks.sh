#!/bin/bash

flist='
cluster_tasks.py
job_tasks.py
tasks.py
'

for file in $flist
do
  mv $file.bak $file
done


