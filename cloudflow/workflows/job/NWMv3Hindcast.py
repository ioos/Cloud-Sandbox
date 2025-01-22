import datetime
import os
import sys

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

curdir = os.path.dirname(os.path.abspath(__file__))

from job.Job import Job
from utils import romsUtil as util

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


debug = False


class NWMv3Hindcast(Job):
    """ Implementation of Job class for ROMS Hindcast

    Attributes
    ----------
    jobtype : str
        Always 'schismhindcast' for this class.

    configfile : str
        A JSON configuration file containing the required parameters for this class.

    NPROCS : int
        Total number of processors in this cluster.

    OFS : str
        The ocean forecast to run

    SDATE : str
        The hindcast start date in format YYYYMMDDHH

    EDATE : str
        The hindcast end date in format YYYYMMDDHH

    HH : str
        The hourly forecast cycle the hindcast simulation is starting in format HH

    COMROT : str
        The base directory to use, e.g. /com/ec2-user

    SAVE : str
        The base directory to use, e.g. /save/ec2-user

    PTMP : str
        The base directory for the scratch disk, usually /ptmp

    EXEC : str
        The model executable to run.
    
    MODEL_DIR : str
        The location of the NWMv3 model run to execute

    BUCKET : str
        The cloud bucket name for saving results

    BCKTFLDR : str
        The cloud folder name for saving results

    OUTDIR : str
        The full path to the output folder

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

        self.jobtype = 'nwmv3hindcast'
        self.configfile = configfile

        self.NPROCS = NPROCS
        self.TEMPLPATH = f"{curdir}/templates"

        if debug:
            print(f"DEBUG: in NWMv3Hindcast init")
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
        self.SDATE = cfDict['SDATE']
        self.EDATE = cfDict['EDATE']
        self.HH = cfDict['HH']
        self.COMROT = cfDict['COMROT']
        self.SAVE = cfDict['SAVE']
        self.PTMP = cfDict['PTMP']
        self.EXEC = cfDict['EXEC']
        self.MODEL_DIR = cfDict['MODEL_DIR']
        self.BUCKET = cfDict['BUCKET']
        self.BCKTFLDR = cfDict['BCKTFLDR']
        self.OUTDIR = cfDict['OUTDIR']

        return


if __name__ == '__main__':
    pass
