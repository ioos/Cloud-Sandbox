"""
Abstract base class for a compute cluster. A cluster can also be a single machine.
This class needs to be implemented and extended for specific cloud providers.
"""
from abc import ABC, abstractmethod
from subprocess import Popen

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


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
        """Get the number of cores per node in this cluster. Assumes a heterogenous cluster."""
        pass

    @abstractmethod
    def getState(self):
        """Get the cluster state."""
        pass

    @abstractmethod
    def setState(self):
        """ Set the cluster state."""
        pass

    @abstractmethod
    def readConfig(self):
        """ Read the cluster configuration."""
        pass

    @abstractmethod
    def parseConfig(self, cfDict : dict):
        """ Parse the cluster configuration. This might contain parameters that are required by
        specific cloud providers.

        Parameters
        ----------
        cfDict : dict
          Dictionary containing this cluster parameterized settings. 
        """
        pass

    @abstractmethod
    def start(self):
        """ Start the cluster."""
        pass

    @abstractmethod
    def terminate(self):
        """Terminate the cluster."""
        pass

    @abstractmethod
    def getHosts(self):
        """ Get the list of hosts in this cluster."""
        pass

    @abstractmethod
    def getHostsCSV(self):
        """ Get a comma separated list of hosts in this cluster."""
        pass


if __name__ == '__main__':
    pass
