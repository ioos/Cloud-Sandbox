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


class ucla_roms(Job):
    """ Implementation of Job class for a simple ROMS model template

    Attributes
    ----------
    jobtype : str
        User defined job type based on model of interest, should always be roms_template

    configfile : str
        A JSON configuration file containing the required parameters for this class.

    RUNCORES : int
        Total number of processors (cores) ucla-roms will use.

    OFS : str
        The model setup type to run

    EXEC : str
        The model executable to run.
    
    MODEL_DIR : str
        The location of the model run directory to execute

    IN_FILE : str
        The ROMS .in input file for a given model configuration
    """


    # TODO: make self and cfDict consistent
    def __init__(self, configfile, NPROCS):
        """ Constructor

        Parameters
        ----------
        configfile : str

        NPROCS : int
            The number of processors requested for the job

        """

        self.configfile = configfile

        self.NPROCS = NPROCS

        if debug:
            print(f"DEBUG: in ROMS Template init")
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

        self.jobtype = cfDict['JOBTYPE']
        self.OFS = cfDict['OFS']
        self.EXEC = cfDict['EXEC']
        self.MODEL_DIR = cfDict['MODEL_DIR']
        self.IN_FILE = cfDict['IN_FILE']
        self.RUNCORES = cfDict['RUNCORES']
        return


if __name__ == '__main__':
    pass
