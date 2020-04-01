"""

Abstract base class for a compute cluster. A cluster can also be a single machine.
This class needs to be implemented and extended for specific cloud providers.

"""
from abc import ABC, abstractmethod
from subprocess import Popen
import time
__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

'''
Parameters
----------
var : type
  Desc

Returns
-------
var : type
  Desc

Raises
------
excep
  Desc

Notes
-----
'''


class Cluster(ABC):
    """
    Abstract base class for cloud clusters. It defines a generic interface to implement

    Attributes
    ----------
    daskscheduler - a reference to the Dask scheduler process started on the cluster
    daskworker    - a reference to the Dask worker process started on the cluster

    Methods
    -------
    setDaskScheduler(proc: Popen)
      Save the Popen process for dask-scheduler

    terminateDaskScheduler()
      Cleanup/kill the dask-scheduler process

    setDaskWorker(proc: Popen)
      Save the Popen process for dask-worker

    terminateDaskWorker()
      Cleanup/kill the dask-worker process

    Abstract Methods
    ----------------
    TODO: Can use class properties for some of these instead.

    getCoresPN()
      Get the number of cores per node in this cluster. Assumes a heterogenous cluster.

    getState()
      Get the cluster state.

    setState()
      Set the cluster state.
      TODO: Can use a class property instead.

    readConfig()
      Read the cluster configuration.

    parseConfig()
      Parse the cluster configuration. This might contain parameters that are required by
      specific cloud providers.

    start()
      Start the cluster.

    terminate()
      Terminate the cluster.

    getHosts()
      Get the list of hosts in this cluster

    getHostsCSV() :
      Get a comma separated list of hosts in this cluster

    """
    # TODO: Put Dask stuff in its own class
    def __init__(self):
        """"""
        self.daskscheduler = None
        self.daskworker = None

        self.configfile = None
        self.platform = None

    def setDaskScheduler(self, proc: Popen):
        """"""
        self.daskscheduler = proc
        return proc

    def terminateDaskScheduler(self):
        """ If process hasn't terminated yet, terminate it. """
        if self.daskscheduler is not None:
            poll = self.daskscheduler.poll()
            if poll is None:
                self.daskscheduler.kill()
        return

    def setDaskWorker(self, proc: Popen):
        self.daskworker = proc
        return proc

    def terminateDaskWorker(self):
        """ If process hasn't terminated yet, terminate it. """
        if self.daskworker is not None:
            poll = self.daskworker.poll()

            if poll is None:
                self.daskworker.kill()
        return

    """ 
    Abstract Function Definitions
    ==============================
    """

    @abstractmethod
    def getCoresPN(self) -> int:
        pass

    @abstractmethod
    def getState(self):
        pass

    @abstractmethod
    def setState(self):
        pass

    @abstractmethod
    def readConfig(self):
        pass

    @abstractmethod
    def parseConfig(self):
        pass

    @abstractmethod
    def start(self):
        pass

    @abstractmethod
    def terminate(self):
        pass

    ''' get the list of hostnames or IPs in this cluster  '''

    @abstractmethod
    def getHosts(self):
        pass

    ''' get a comma separated list of hosts in this cluster '''

    @abstractmethod
    def getHostsCSV(self):
        pass


if __name__ == '__main__':
    pass
