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

# SECOFS
class SCHISMHindcast(Job):
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

    CDATE : str
        The current rundate format YYYYMMDD

    SDATE : str
        The forecast start date in format YYYYMMDD

    EDATE : str
        The hindcast end date

    HH : str

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
        self.CDATE = cfDict['CDATE']
        self.SDATE = cfDict['SDATE']
        self.EDATE = cfDict['EDATE']
        self.EXEC = cfDict['EXEC']
        self.HH = cfDict['HH']
        self.OUTDIR = cfDict['OUTDIR']
        self.SAVE = cfDict['SAVE']
        self.PTMP = cfDict['PTMP']
        self.WRITERS = cfDict['NSCRIBES']

        return

    def make_oceanin(self):
        print("make_oceanin - not implemented for this model yet")
        return

# TODO: need to parameterize model run options that are used for .nml file
# e.g. 
# ! Starting time
#  start_year = 2017 !int
#  start_month = 12 !int
#  start_day = 1 !int
#  start_hour = 0 !double
#  utc_start = 0 !double

#  rnday = 396. !total run time in days
#  dt = 120. !Time step in sec


if __name__ == '__main__':
    pass
