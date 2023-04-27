"""
Cluster implementation for the local machine.
"""
import json
import os
from subprocess import Popen

from cloudflow.cluster.Cluster import Cluster

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


debug = False

class LocalCluster(Cluster):
    """
    Implementation of the Cluster interface for the local machine.

    Attributes
    ----------
    platform  : str
        This will always be 'Local' for this implementation.

    nodeType  : str
        The uname operating system for this machine.

    nodeCount : int
        Number of instances in this cluster.

    PPN       : int
        Number of processors (physical cores) per node.

    daskscheduler : Popen
        a reference to the Dask scheduler process started on the cluster

    daskworker : Popen
        a reference to the Dask worker process started on the cluster
    """

    def __init__(self, configfile):
        """ Constructor """

        self.daskscheduler: Popen = None
        self.daskworker: Popen = None

        self.__configfile = configfile

        self.__state = "none"  # This could be an enumeration of none, running, stopped, error
        self.platform = 'Local'
        self.nodeType = os.uname().sysname

        cfDict = self.readConfig(configfile)

        # TODO: Move this to parse
        self.PPN = cfDict['PPN']
        self.nodeCount = cfDict['nodeCount']

        # self.PPN = os.cpu_count()
        # self.PPN = len(os.sched_getaffinity(0))  # Not supported or implemented on some platforms


    def getState(self):
        return self.__state


    def setState(self, state):
        self.__state = state
        return self.__state


    def readConfig(self, configfile):
        with open(configfile, 'r') as cf:
            cfDict = json.load(cf)

        if (debug):
            print(json.dumps(cfDict, indent=4))
            print(str(cfDict))

        self.parseConfig(cfDict)

        return cfDict


    def parseConfig(self, cfDict):
        self.platform = cfDict['platform']
        return


    def getCoresPN(self):
        return self.PPN


    def start(self):
        return


    def terminate(self):
        self.terminateDaskWorker()
        self.terminateDaskScheduler()
        return ["LocalCluster"]


    def getHosts(self):
        return ['127.0.0.1']


    def getHostsCSV(self):
        return '127.0.0.1'


if __name__ == '__main__':
    pass
