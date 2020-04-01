#!/usr/bin/env python3

from . import nodeInfo

nodetype = 'c5n.2xlarge'
ppn = nodeInfo.getPPN(nodetype)

print('ppn is: ' + str(ppn))
