import datetime
import os
import sys
import re 

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

curdir = os.path.dirname(os.path.abspath(__file__))

from cloudflow.job.Job import Job

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


debug = False


class PYTHON_Experiment(Job):
    """ Implementation of Job class for a simple basic model template

    Attributes
    ----------
    MODEL : str
        The model affiliation class to reference for cloudflow

    jobtype : str
        User defined job type based on model of interest

    APP : str
        The model workflow application to run.

    configfile : str
        A JSON configuration file containing the required parameters for this class.

    NPROCS : int
        Total number of processors in this cluster.

    EXEC : str
        The Python executable to run on cloudflow, default is the system Python executable
    
    SCRIPT : str
        The Python script to execute on cloudflow, which is required except for dask implementation

    ARG1 : str
        The first Python argument in a given function needed to run a theoretical script

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
            print(f"DEBUG: in PYTHON Experiment init")
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
        # Script Argument inputs can be inserted here below
        # This first dummy argument is used as a Python
        # dask example
        self.ARG1 = cfDict.get('ARG1',None)

        # Optional to specify your own Python executable,
        # otherwise default to the system Python executable
        self.EXEC = cfDict.get('EXEC','python3')

        self.SCRIPT = cfDict['SCRIPT']

        return


if __name__ == '__main__':
    pass
