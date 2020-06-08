#!/bin/bash

make clean
./sedtasks.sh
make github
./unsedtasks.sh
