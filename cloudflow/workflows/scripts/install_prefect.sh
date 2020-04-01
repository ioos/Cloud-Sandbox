#!/bin/bash

. /usr/share/Modules/init/bash

module load gcc
pip3 install "prefect[aws]"
