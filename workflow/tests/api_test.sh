#!/bin/sh

# This is a dumb mockup to prototype the API and work out some 
# design ideas.

if [ $# -lt 2 ] ; then
  echo "Usage: $0 submit job1 [job2 [job3]]"
  echo ""
  echo "If more than one job is specified they will run in succession only if the "
  echo "previous job finishes without error."
  exit 1
fi

cmd=$1
job1=$2

job2=""
job3=""
if [ $3 ]; then 
  job2=$3
fi
if [ $4 ]; then
  job3=$4
fi

#echo $cmd $job1 $job2 $job3

case $cmd in
  'submit')
    echo "submit $job1 $job2 $job3"
    workflows/workflow.py $job1 $job2 $job3
  ;;
  *)
    echo "Unknown command"
  ;;
esac
