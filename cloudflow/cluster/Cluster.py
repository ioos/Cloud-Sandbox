"""
Abstract base class for a compute cluster. A cluster can also be a single machine.
This class needs to be implemented and extended for specific cloud providers.
"""
from abc import ABC, abstractmethod
from subprocess import Popen

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

class Cluster(ABC):
    """Abstract base class for cloud clusters. It defines a generic interface to implement

    Attributes
    ----------
    daskscheduler : Popen
        a reference to the Dask scheduler process started on the cluster

    daskworker : Popen
        a reference to the Dask worker process started on the cluster

    configfile : str
        A JSON configuration file containing the required parameters for this class.

    platform  : str
        The type of platform or provider

    Methods
    -------
    terminateDaskScheduler()
      Cleanup/kill the dask-scheduler process

    setDaskWorker(proc: Popen)
      Save the Popen process for dask-worker

    terminateDaskWorker()
      Cleanup/kill the dask-worker process

    Abstract Methods
    ----------------
    getCoresPN()
      Get the number of cores per node in this cluster. Assumes a heterogenous cluster.

    getState()
      Get the cluster state.

    setState()
      Set the cluster state.

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
        """ Constructor """

        self.daskscheduler = None
        self.daskworker = None

        self.configfile = None
        self.platform = None


    def setDaskScheduler(self, proc: Popen):
        """ Save the Popen process for dask-scheduler

        Parameters
        ----------
        proc: Popen
            The dask-scheduler process

        Returns
        -------
        proc : Popen
            The dask-scheduler process
        """

        self.daskscheduler = proc
        return proc


    def terminateDaskScheduler(self):
        """ Kills the dask-scheduler process if it hasn't terminated yet. """
        if self.daskscheduler is not None:
            poll = self.daskscheduler.poll()
            if poll is None:
                self.daskscheduler.kill()
        return


    def setDaskWorker(self, proc: Popen):
        """ Save the Popen process for dask-worker

        Parameters
        ----------
        proc: Popen
            The dask-worker process

        Returns
        -------
        proc : Popen
            The dask-worker process
        """

        self.daskworker = proc
        return proc


    def terminateDaskWorker(self):
        """ Kills the dask-worker process if it hasn't terminated yet. """
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
    def parseConfig(self, cfDict : dict):
        pass

    @abstractmethod
    def start(self):
        pass

    @abstractmethod
    def terminate(self):
        pass

    @abstractmethod
    def getHosts(self):
        pass

    @abstractmethod
    def getHostsCSV(self):
        pass


if __name__ == '__main__':
    pass
