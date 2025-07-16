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


class FVCOM_Hindcast(Job):
    """ Implementation of Job class for FVCOM Forecasts

    Attributes
    ----------
    jobtype : str
        Always 'fvcomhindcast' for this class.

    configfile : str
        A JSON configuration file containing the required parameters for this class.

    NPROCS : int
        Total number of processors in this cluster. Determined by cluster config.

    OFS : str
        The ocean forecast to run.

    CDATE : str
        The forecast date in format YYYYMMDD

    HH : str
        The forecast cycle in format HH

    COMROT : str
        The base directory to use, e.g. /com/nos

    SAVEDIR : str
        The directory where the model executable and other relevant static files are 

    PTMP : str
        The base directory for the scratch disk, usually /ptmp

    DATE_REF : str
        Templated DATE_REF field value for FVCOM namelist

    BUCKET : str
        The cloud bucket name for saving results

    BCKTFLDR : str
        The cloud folder name for saving results

    OUTDIR : str
        The full path to the output folder

    INPUTFILE : str
        The input namelist to use

    INTMPL : str
        The input namelist template to use

    TEMPLPATH : str
        The full path to the templates to use

    TODO: Update this documentation

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

        self.jobtype = 'fvcomhindcast'
        self.configfile = configfile

        self.NPROCS = NPROCS
        self.TEMPLPATH = f"{curdir}/templates"

        if debug:
            print(f"DEBUG: in FVCOM_Hindcast init")
            print(f"DEBUG: job file is: {configfile}")

        cfDict = self.readConfig(configfile)
        self.parseConfig(cfDict)

        self.make_fcstin()


    def parseConfig(self, cfDict):
        """ Parses the configuration dictionary to class attributes

        Parameters
        ----------
        cfDict : dict
          Dictionary containing this cluster parameterized settings.
        """

        self.OFS = cfDict['OFS']

        self.SDATE = cfDict['SDATE']
        self.CDATE = self.SDATE
        self.EDATE = cfDict['EDATE']
        
        self.HH = cfDict['HH']
        self.NHOURS = cfDict['NHOURS']
        self.COMROT = cfDict['COMROT']


        # Why do I need this?
        self.SAVEDIR = cfDict['SAVEDIR']


        self.PTMP = cfDict['PTMP']
        self.DATE_REF = cfDict['DATE_REF']
        self.BUCKET = cfDict['BUCKET']
        self.BCKTFLDR = cfDict['BCKTFLDR']
        self.OUTDIR = cfDict['OUTDIR']
        self.INPUTFILE = cfDict['INPUTFILE']
        self.INTMPL = cfDict['INTMPL']  # Input file template
        self.EXEC = cfDict['EXEC']

        if self.INTMPL == "auto":
            self.INTMPL = f"{self.TEMPLPATH}/{self.OFS}.fcst.in"

        # This logic doesnt work for multi run
        #if self.OUTDIR == "auto":
        #    self.OUTDIR = f"{self.COMROT}/{self.OFS}.{self.CDATE}{self.HH}"

        return

    # This function must be defined, multi run workflow depends on it
    def make_oceanin(self):
        self.make_fcstin()



    def make_fcstin(self):
        """ Create the input namelist .in file """

        OFS = self.OFS

        # Create the namelist in file from a template
        if OFS in ('ngofs2', 'sfbofs', 'leofs', 'lmhofs', 'necofs'):
            self.__make_fcstin_nosofs()
        else:
            #raise Exception(f"{OFS} is not a supported forecast")
            warnings.warn(f"Not generating a namelist .in file")

        return


    def __make_fcstin_nosofs(self):
        """ Create the input namelist .in file if INPUTFILE == auto, otherwise use the provided INPUTFILE """

        CDATE = self.CDATE
        HH = self.HH
        OFS = self.OFS
        COMROT = self.COMROT
        NHOURS = self.NHOURS
        template = self.INTMPL

        self.OUTDIR = f"{COMROT}/{OFS}.{CDATE}"

        if not os.path.exists(self.OUTDIR):
            os.makedirs(self.OUTDIR)

        HHMMSS = f"{self.HH}:00:00"
        START_DATE = f"{CDATE[0:4]}-{CDATE[4:6]}-{CDATE[6:8]}"

        CDATEHH = f"{CDATE}{HH}"
        edate = util.ndate_hrs(CDATEHH, int(self.NHOURS))
        END_DATE = f"{edate[0:4]}-{edate[4:6]}-{edate[6:8]}"
        END_HHMMSS = f"{edate[8:10]}:00:00"

        # These are the templated variables to replace via substitution
        settings = {
            "__DATE_REFERENCE__": self.DATE_REF,
            "__END_DATE__": END_DATE,
            "__END_HHMMSS__": END_HHMMSS,
            "__HHMMSS__": HHMMSS,
            "__START_DATE__": START_DATE,
            "__CDATE__": CDATE,
            "__HH__": HH
        }

        # Create the namelist.in file
        if self.INPUTFILE == "auto":
            self.INPUTFILE = f"{self.OUTDIR}/nos.{OFS}.forecast.{CDATE}.t{HH}z.in"
        elif self.INPUTFILE == "":
            raise Exception(f"No namelist input file specified")

        outfile = self.INPUTFILE
        util.sedoceanin(template, outfile, settings)

        return


if __name__ == '__main__':
    pass
