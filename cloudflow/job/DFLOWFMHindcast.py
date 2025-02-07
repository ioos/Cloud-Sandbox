import datetime
import os
import sys

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

curdir = os.path.dirname(os.path.abspath(__file__))

from cloudflow.job.Job import Job
from cloudflow.utils import romsUtil as util

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


debug = False


class DFLOWFMHindcast(Job):
    """ Implementation of Job class for DFlowFM model runs

    Attributes
    ----------
    jobtype : str
        Always 'dflowfmhindcast' for this class.

    configfile : str
        A JSON configuration file containing the required parameters for this class.

    NPROCS : int
        Total number of processors in this cluster.

    OFS : str
        The DFlowFM model to run

    EXEC : str
        The model executable to run.

    DFLOW_LIB : str
        The pathway to the DFlowFM compiled library suite for executable to link with.
    
    MODEL_DIR : str
        The location of the DFlowFM model run directory to execute
    """


    # TODO: make self and cfDict consistent
    def __init__(self, configfile, NPROCS):
        """ Constructor

        Parameters
        ----------
        configfile : str

        NPROCS : int
            The number of processors to run the job on

        """

        self.jobtype = 'dflowfmhindcast'
        self.configfile = configfile

        self.NPROCS = NPROCS

        if debug:
            print(f"DEBUG: in DFLOWFM init")
            print(f"DEBUG: job file is: {configfile}")

        cfDict = self.readConfig(configfile)
        self.parseConfig(cfDict)

        return


    def parseConfig(self, cfDict):
        """ Parses the configuration dictionary to class attributes

        Parameters
        ----------
        cfDict : dict
          Dictionary containing this cluster parameterized settings.
        """
        
        self.OFS = cfDict['OFS']
        self.EXEC = cfDict['EXEC']
        self.DFLOW_LIB = cfDict['DFLOW_LIB']
        self.MODEL_DIR = cfDict['MODEL_DIR']

        return


if __name__ == '__main__':
    pass
