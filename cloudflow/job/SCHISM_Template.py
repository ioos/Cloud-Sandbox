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


class SCHISM_Template(Job):
    """ Implementation of Job class for SCHISM simulations

    Attributes
    ----------
    jobtype : str
        Job type configuration description for NWM WRF Hydro simulation. Should always be schism_template

    configfile : str
        A JSON configuration file containing the required parameters for this class.

    NPROCS : int
        Total number of processors in this cluster.

    OFS : str
        The schism model to run

    EXEC : str
        The model executable to run.
    
    MODEL_DIR : str
        The location of the SCHISM model run to execute

    NSCRIBES: str
        The number of cpus dedicated to SCHISM I/O procedures
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
            print(f"DEBUG: in SCHISM Template init")
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
        self.NSCRIBES = cfDict['NSCRIBES']

        return


if __name__ == '__main__':
    pass
