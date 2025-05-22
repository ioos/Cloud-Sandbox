#!/usr/bin/env python3
""" Functions to return a pseudo random OFS name.
    Will not return the same as the previous completed forecast."""

import os
import sys
import random

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))
if os.path.abspath('../..') not in sys.path:
    sys.path.append(os.path.abspath('../..'))
if os.path.abspath('../../..') not in sys.path:
    sys.path.append(os.path.abspath('../../..'))

from cloudflow.utils import modelUtil as utils

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


# Pseudocode

# Two functions
# Func 1 - return a random OFS
# Func 2 - return a random OFS that is not equal to the most current completed forecast"

# Other possibles:
# return a random ROMS forecast
# return a random FVCOM forecast

# Func 1
def random_ofs() -> str:
    # Get list of possible ofs from util library
    ofslist = utils.nosofs_models

    # get a random integer between 0 and length of ofslist
    random.seed()
    index = random.randint(0,len(ofslist)-1)
    #print(len(ofslist))
    return ofslist[index]

# Func 2
def newrandom_ofs(COMROT: str = "/com/nos") -> str:

    # get name of most recently completed forecast
    curfile=f"{COMROT}/current.fcst"
    with open(curfile) as cf:
        curfcst = cf.read().rstrip(' \n')
    curofs=curfcst.split(".")[0]

    # run random_ofs in loop until it does not equal curofs
    newofs = random_ofs()
    while (newofs == curofs):
        newofs = random_ofs()

    return newofs

newofs = newrandom_ofs()

# Need to know the first cycle also
cycle = utils.nosofs_cyc0(newofs)

print(f"{newofs} {cycle}")
