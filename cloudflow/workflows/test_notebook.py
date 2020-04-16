#!/usr/bin/env python3
import os
import sys

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

from cloudflow.workflows import flows

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

curdir = os.path.dirname(os.path.abspath(__file__))

postconf = f'{curdir}/../cluster/configs/local.config'

def main():

    pyfile = os.path.abspath(sys.argv[1])

    flow = flows.notebook_flow(postconf, pyfile)

    state = flow.run()
    if state.is_successful():
        print("notebook py worked")
    else:
        print("notebook py failed")

#####################################################################


if __name__ == '__main__':
    main()
