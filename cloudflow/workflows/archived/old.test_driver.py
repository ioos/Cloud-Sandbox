#!/usr/bin/env python3
import os
import sys

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

from cloudflow.workflows import flows

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


curdir = os.path.dirname(os.path.abspath(__file__))

conf = f'{curdir}/../cluster/configs/ioos.config'

def main():

    jobfile = f'{curdir}/../job/jobs/liveocean.00z.fcst'
    flow = flows.test_flow(conf, jobfile)

    state = flow.run()
    if state.is_successful():
        print("flow worked")
    else:
        print("flow failed")

#####################################################################


if __name__ == '__main__':
    main()
