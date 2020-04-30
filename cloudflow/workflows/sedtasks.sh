#!/bin/bash
# Python autodoc does not work with annotated @task functions. Temporarily remove those annotations before
# generating the documentation.
flist='
cluster_tasks.py
job_tasks.py
tasks.py
'

for file in $flist
do
  sed -i.bak 's/@task/\#@task/g' $file
done


