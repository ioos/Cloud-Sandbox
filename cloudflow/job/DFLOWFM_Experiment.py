import datetime
import os
import sys

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

curdir = os.path.dirname(os.path.abspath(__file__))

from cloudflow.job.Job import Job

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


debug = False


class DFLOWFM_Experiment(Job):
    """ Implementation of Job class for a basic Deltares DFlow-FM model run (model run directory, executable, and executable args if necessary)

    Attributes
    ----------
    MODEL : str
        The model affiliation class to reference for cloudflow

    jobtype : str
        Job type configuration description for a DFlow-FM basic simulation. Should always be dflowfm_basic

    APP : str
        The model workflow application to run.

    configfile : str
        A JSON configuration file containing the required parameters for this class.

    NPROCS : int
        Total number of processors in this cluster.

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

        self.configfile = configfile

        self.NPROCS = NPROCS

        if debug:
            print(f"DEBUG: in DFLOWFM Experiment init")
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

        self.MODEL = cfDict['MODEL']
        self.jobtype = cfDict['JOBTYPE']
        self.APP = cfDict.get('APP', "basic")
        self.EXEC = cfDict['EXEC']
        self.DFLOW_LIB = cfDict['DFLOW_LIB']
        self.MODEL_DIR = cfDict['MODEL_DIR']

        return


if __name__ == '__main__':
    pass
