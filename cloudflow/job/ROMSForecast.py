import datetime
import os
import sys

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

curdir = os.path.dirname(os.path.abspath(__file__))

from cloudflow.job.Job import Job
from cloudflow.utils import romsUtil as util

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

debug = False


class ROMSForecast(Job):
    """ Implementation of Job class for ROMS Forecasts

    Attributes
    ----------
    jobtype : str
        Always 'romsforecast' for this class.

    configfile : str
        A JSON configuration file containing the required parameters for this class.

    NPROCS : int
        Total number of processors in this cluster.

    OFS : str
        The ocean forecast to run.

    CDATE : str
        The forecast date in format YYYYMMDD

    HH : str
        The forecast cycle in format HH

    COMROT : str
        The base directory to use, e.g. /com/nos

    EXEC : str
        The model executable to run. Only used for ADNOC currently.

    TIME_REF : str
        Templated TIME_REF field value for ROMS ocean.in

    BUCKET : str
        The cloud bucket name for saving results

    BCKTFLDR : str
        The cloud folder name for saving results

    NTIMES : str
        Templated NTIMES field value for ROMS ocean.in

    ININAME : str
        The file to use as a restart file.

    OUTDIR : str
        The full path to the output folder

    OCEANIN : str
        The ocean.in file to use or "AUTO" to use a template

    OCNINTMPL : str
        The ocean.in template to use or "AUTO" to use the default template

    TEMPLPATH : str
        The full path to the templates to use

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

        self.jobtype = 'romsforecast'
        self.configfile = configfile

        self.NPROCS = NPROCS
        self.TEMPLPATH = f"{curdir}/templates"

        if debug:
            print(f"DEBUG: in ROMSForecast init")
            print(f"DEBUG: job file is: {configfile}")

        cfDict = self.readConfig(configfile)
        self.parseConfig(cfDict)
        self.make_oceanin()


    def parseConfig(self, cfDict):
        """ Parses the configuration dictionary to class attributes

        Parameters
        ----------
        cfDict : dict
          Dictionary containing this cluster parameterized settings.
        """

        self.OFS = cfDict['OFS']
        self.CDATE = cfDict['CDATE']
        self.HH = cfDict['HH']
        self.COMROT = cfDict['COMROT']
        self.EXEC = cfDict['EXEC']
        self.TIME_REF = cfDict['TIME_REF']
        self.BUCKET = cfDict['BUCKET']
        self.BCKTFLDR = cfDict['BCKTFLDR']
        self.NTIMES = cfDict['NTIMES']
        self.ININAME = cfDict['ININAME']
        self.OUTDIR = cfDict['OUTDIR']
        self.OCEANIN = cfDict['OCEANIN']
        self.OCNINTMPL = cfDict['OCNINTMPL']

        if self.CDATE == "today":
            today = datetime.date.today().strftime("%Y%m%d")
            self.CDATE = today

        if self.OCNINTMPL == "auto":
            self.OCNINTMPL = f"{self.TEMPLPATH}/{self.OFS}.ocean.in"

        return


    def make_oceanin(self):
        """ Create the ocean.in file from a template"""
        OFS = self.OFS

        # Create the ocean.in file from a template
        if OFS == 'liveocean':
            self.__make_oceanin_lo()
        elif OFS == 'adnoc':
            self.__make_oceanin_adnoc()
        elif OFS in ("cbofs","ciofs","dbofs","gomofs","tbofs"):
            self.__make_oceanin_nosofs()
        else:
            raise Exception(f"{OFS} is not a supported forecast")

        return



    def __make_oceanin_lo(self):
        """ Create the ocean.in file for liveocean forecasts """

        CDATE = self.CDATE
        OFS = self.OFS
        COMROT = self.COMROT

        template = self.OCNINTMPL

        # fdate = f"f{CDATE[0:4]}.{CDATE[4:6]}.{CDATE[6:8]}"
        fdate = util.lo_date(CDATE)
        prevdate = util.ndate(CDATE, -1)
        fprevdate = util.lo_date(prevdate)

        #TODO: Document the multiple options. OUTDIR=auto | /path, OCEANIN=auto | /path/filename
        if self.OUTDIR == "auto":
            self.OUTDIR = f"{COMROT}/{OFS}/{fdate}"

        if not os.path.exists(self.OUTDIR):
            os.makedirs(self.OUTDIR)

        if self.ININAME == "auto":
            self.ININAME = f"/com/liveocean/{fprevdate}/ocean_his_0025.nc"

        DSTART = util.ndays(CDATE, self.TIME_REF)
        # DSTART = days from TIME_REF to start of forecast day larger minus smaller date

        settings = {
            "__NTIMES__": self.NTIMES,
            "__TIME_REF__": self.TIME_REF,
            "__DSTART__": DSTART,
            "__FDATE__": fdate,
            "__ININAME__": self.ININAME
        }

        # Create the ocean.in
        if self.OCEANIN == "auto":
            outfile = f"{self.OUTDIR}/liveocean.in"
            ratio = 0.44444
            # ratio=0.375   # Testing 6 nodes (9x24) crashes, .444 crashes (12x18)
            # ratio=0.5
            # ratio=0.02222
            util.makeOceanin(self.NPROCS, settings, template, outfile, ratio=ratio)
        return



    def __make_oceanin_nosofs(self):
        """ Create the ocean.in file for nosofs forecasts """

        CDATE = self.CDATE
        HH = self.HH
        OFS = self.OFS
        COMROT = self.COMROT
        template = self.OCNINTMPL

        if self.OUTDIR == "auto":
            self.OUTDIR = f"{COMROT}/{OFS}.{CDATE}"

        if not os.path.exists(self.OUTDIR):
            os.makedirs(self.OUTDIR)

        # The restart date is 6 hours prior to CDATE, DSTART is hours since TIME_REF
        prev6hr = util.ndate_hrs(f"{CDATE}{HH}", -6)
        DSTART = util.ndays(prev6hr, self.TIME_REF)
        # Reformat the date
        DSTART = f"{'{:.4f}'.format(float(DSTART))}d0"

        JAN1CURYR = f"{CDATE[0:4]}010100"
        TIDE_START = util.ndays(JAN1CURYR, self.TIME_REF)
        TIDE_START = f"{'{:.4f}'.format(float(TIDE_START))}d0"

        # These are the templated variables to replace via substitution
        settings = {
            "__NTIMES__": self.NTIMES,
            "__TIME_REF__": self.TIME_REF,
            "__CDATE__": self.CDATE,
            "__HH__": self.HH,
            "__DSTART__": DSTART,
            "__TIDE_START__": TIDE_START
        }

        # Create the ocean.in
        # TODO: tweak these configurations for each model.
        # ratio is used to better balance NtileI/NtileJ with the specific grid
        # This can impact performance
        if self.OCEANIN == "auto":
            outfile = f"{self.OUTDIR}/nos.{OFS}.forecast.{CDATE}.t{HH}z.in"
            if OFS == 'dbofs':
                ratio = 0.16
            else:
                ratio = 1.0
            util.makeOceanin(self.NPROCS, settings, template, outfile, ratio=ratio)

        return



    def __make_oceanin_adnoc(self):
        """ Create the ocean.in file for adnoc forecasts """

        CDATE = self.CDATE
        OFS = self.OFS
        COMROT = self.COMROT

        if self.OUTDIR == "auto":
            self.OUTDIR = f"{COMROT}/{OFS}/{CDATE}"

        if not os.path.exists(self.OUTDIR):
            os.makedirs(self.OUTDIR)

        settings = {
            "__NTIMES__": self.NTIMES,
            "__TIME_REF__": self.TIME_REF,
        }

        template = self.OCNINTMPL

        # Create the ocean.in
        if self.OCEANIN == "auto":
            outfile = f"{self.OUTDIR}/ocean.in"
            util.makeOceanin(self.NPROCS, settings, template, outfile)

        return



if __name__ == '__main__':
    pass
