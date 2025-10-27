import datetime
import os
import sys

from cloudflow.job.Job import Job
from cloudflow.utils import modelUtil as util

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

curdir = os.path.dirname(os.path.abspath(__file__))

from cloudflow.job.Job import Job

__copyright__ = "Copyright © 2025 Tetra Tech, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


debug = False

# SECOFS
class SCHISM_Hindcast(Job):
    """ Implementation of Job class for SCHISM simulations for SECOFS

    Attributes
    ----------

    MODEL : str
       The model affiliation class to reference for cloudflow

    jobtype : str
        Job type configuration description for NWM WRF Hydro simulation. Should always be schism_template

    APP : str
        The model workflow application to run.

    configfile : str
        A JSON configuration file containing the required parameters for this class.

    NPROCS : int
        Total number of processors in this cluster.

    CDATE : str
        The current rundate format YYYYMMDD

    SDATE : str
        The forecast start date in format YYYYMMDD

    EDATE : str
        The hindcast end date

    HH : str

    EXEC : str
        The model executable to run.
    
    COMDIR : str
        The location of the SCHISM model run to execute

    SAVEDIR : str
        The /save directory for this job containing other things needed, e.g. modulefile, scripts, executables, etc.

    PTMP : str
        The scratch disk to use for running the model

    PARMNML_IN   : str

    PARMNML_TMPL : str

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

        self.MODEL = cfDict['MODEL']
        self.jobtype = cfDict['JOBTYPE']
        self.APP = cfDict.get('APP', "default")
        self.CDATE = cfDict['CDATE']
        if 'SDATE' in cfDict: self.SDATE = cfDict['SDATE']
        if 'EDATE' in cfDict: self.EDATE = cfDict['EDATE']
        self.RNDAY = cfDict['RNDAY']
        self.HH = cfDict['HH']
        self.EXEC = cfDict['EXEC']
        self.COMROT = cfDict['COMROT']
        self.OUTDIR = self.COMROT + "/" + self.CDATE
        self.SAVEDIR = cfDict['SAVEDIR']
        self.PTMP = cfDict['PTMP']
        self.NML_IN = cfDict['NML_IN']
        self.NML_TMPL = cfDict['NML_TMPL']
        self.NSCRIBES = cfDict['NSCRIBES']

        return


    # This function must be defined, workflow depends on it
    def make_oceanin(self):
        self.make_parmnml()



    def make_parmnml(self):

        if self.APP == "secofs":
            self.__make_parmnml_secofs()
        else:
            print(f"WARNING: make_parmnml is not implemented for {self.APP}")

        return



    def __make_parmnml_secofs(self):

        if not os.path.exists(self.OUTDIR):
            os.makedirs(self.OUTDIR)

        if self.NML_IN == "auto":

            template = self.NML_TMPL
            
            outfile = self.OUTDIR + "/param.nml"
            start_year = self.CDATE[0:4]
            start_month = self.CDATE[4:6]
            start_day = self.CDATE[6:8]
            start_hour = float(self.HH)

            # TODO: assuming dt is 120 seconds, parameterize it
            # ! nohot_write = must be a multiple of ihfskip if nhot=1
            # ! 1 day == 86400 seconds

            nhot_write = int(float(self.RNDAY) * 720)
            # nhot_write = 720

            settings = {
                "__RNDAY__": self.RNDAY,
                "__START_YEAR__": start_year,
                "__START_MONTH__": str(int(start_month)),
                "__START_DAY__": str(int(start_day)),
                "__START_HOUR__": str(start_hour),
                "__NHOT_WRITE__": str(nhot_write)
            }

            util.sedoceanin(template, outfile, settings)

        return


if __name__ == '__main__':
    pass
