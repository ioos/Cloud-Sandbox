#!/bin/env bash

REPO=~/Cloud-Sandbox

# Get list of Untracked files:

cd $REPO
unlist=`git status | grep / | grep -v "no changes" | grep -v modified | awk '{print $2}'`

# Get list of itracked modified files:
list=`git status | grep / | grep -v "no changes"  | awk '{print $3}'`

manual='/home/centos/savediff.sh /save/nosofs-NCO/jobs/fcstrun.sh'
echo $unlist
echo $list

tar -cvf ~/ndacloud.tar $unlist $list $manual
