#!/bin/bash
#set -x
#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"


#. /usr/share/Modules/init/sh
#module use -a /usrx/modulefiles
#module load produtil
#module load gcc

if [ $# -lt 4 ] ; then
  echo "Usage: $0 YYYYMMDDHH YYYYMMDDHH MODEL_DIR COMDIR "
  exit 1
fi

SDATE=$1
EDATE=$2
MODEL_DIR=$3
COMDIR=$4

