""" Implementation of Job class for FVCOM Forecasts """
import datetime
import os
import sys
import shutil
import warnings

from cloudflow.job.Job import Job
from cloudflow.utils import modelUtil as util

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

curdir = os.path.dirname(os.path.abspath(__file__))
__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"

debug = False

class FVCOM_Experiment(Job):
    """ Bare bones implementation of Job class for FVCOM runs
        This is for a completely manual run setup

    Attributes
    ----------

    MODEL : str
       The model affiliation class to reference for cloudflow

    jobtype : str
        Always 'fvcom' for this class.

    OFS : str
        The ocean forecast system to run. e.g. ngofs2, necofs, etc.

    configfile : str
        A JSON configuration file containing the required parameters for this class.

    NPROCS : int
        Total number of processors in this cluster.

    RUNDIR : str
        The full path to the run folder

    INPUTFILE : str
       path/filename - path and filename expected by the model

    """

    # TODO: make attributes consistent, add initialization here
    def __init__(self, configfile, NPROCS):
        """ Constructor

        Parameters
        ----------
        configfile : str

        NPROCS : int
            The number of processors to run the job on

        """

        self.jobtype = 'fvcomexperiment'
        self.configfile = configfile

        self.NPROCS = NPROCS

        if debug:
            print(f"DEBUG: in FVCOMForecast init")
            print(f"DEBUG: job file is: {configfile}")

        cfDict = self.readConfig(configfile)
        self.parseConfig(cfDict)



    def parseConfig(self, cfDict):
        """ Parses the configuration dictionary to class attributes

        Parameters
        ----------
        cfDict : dict
          Dictionary containing this cluster parameterized settings.
        """

        self.MODEL = cfDict['MODEL']
        self.OFS = cfDict['OFS']
        self.RUNDIR = cfDict['RUNDIR']
        self.SAVEDIR = cfDict['SAVEDIR']
        self.INPUTFILE = cfDict['INPUTFILE']
        self.EXEC = cfDict['EXEC']

        return

if __name__ == '__main__':
    pass
