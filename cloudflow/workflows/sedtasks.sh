#!/bin/bash

flist='
cluster_tasks.py
job_tasks.py
tasks.py
'

for file in $flist
do
  sed -i.bak 's/@task/\#@task/g' $file
done


