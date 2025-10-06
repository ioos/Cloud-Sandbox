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


class SCHISM_Basic(Job):
    """ Implementation of Job class for a basic SCHISM model run (model run directory, executable, and executable args if necessary)

    Attributes
    ----------
    MODEL : str
        The model affiliation class to reference for cloudflow

    jobtype : str
        Job type configuration description for a SCHISM basic simulation. Should always be schism_basic

    configfile : str
        A JSON configuration file containing the required parameters for this class.

    NPROCS : int
        Total number of processors in this cluster.

    EXEC : str
        The model executable to run.
    
    MODEL_DIR : str
        The location of the SCHISM model run to execute

    NSCRIBES: str
        The number of cpus dedicated to SCHISM I/O procedures, which is a function of user specified output fields for out2d_1.nc file
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
            print(f"DEBUG: in SCHISM Basic init")
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
        self.EXEC = cfDict['EXEC']
        self.MODEL_DIR = cfDict['MODEL_DIR']
        self.NSCRIBES = cfDict['NSCRIBES']

        return


if __name__ == '__main__':
    pass
