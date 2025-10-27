import datetime
import os
import sys

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

curdir = os.path.dirname(os.path.abspath(__file__))

from cloudflow.job.Job import Job
from cloudflow.utils import modelUtil as util

__copyright__ = "Copyright © 2025 Tetra Tech, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


debug = False


class ROMSHindcast(Job):
    """ Implementation of Job class for ROMS Hindcast

    Attributes
    ----------

    MODEL : str
       The model affiliation class to reference for cloudflow

    jobtype : str
        Always 'romshindcast' for this class.

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
        The forecast cycle in format HH

    COMROT : str
        The base directory to use, e.g. /com/nos

    SAVEDIR : str
        The base directory to use, e.g. /save/ec2-user

    PTMP : str
        The base directory for the scratch disk, usually /ptmp

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

        self.jobtype = 'romshindcast'
        self.configfile = configfile

        self.NPROCS = NPROCS
        self.TEMPLPATH = f"{curdir}/templates"

        if debug:
            print(f"DEBUG: in ROMSHindcast init")
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
        self.APP = cfDict.get('APP', "default")
        self.SDATE = cfDict['SDATE']
        self.CDATE = self.SDATE
        self.EDATE = cfDict['EDATE']
        self.HH = cfDict['HH']
        self.COMROT = cfDict['COMROT']
        self.SAVEDIR = cfDict['SAVEDIR']
        self.PTMP = cfDict['PTMP']
        self.EXEC = cfDict['EXEC']
        self.TIME_REF = cfDict['TIME_REF']
        self.BUCKET = cfDict['BUCKET']
        self.BCKTFLDR = cfDict['BCKTFLDR']
        self.NTIMES = cfDict['NTIMES']
        self.ININAME = cfDict['ININAME']
        self.OUTDIR = cfDict['OUTDIR']
        self.OCEANIN = cfDict['OCEANIN']
        self.OCNINTMPL = cfDict['OCNINTMPL']

        # LiveOcean experiment
        if self.APP == "liveocean":
            if 'EXPNAME' in cfDict:
                self.EXPNAME = cfDict["EXPNAME"]
            else:
                raise Exception(f"EXPNAME (experiment name) missing in {this.configfile}")


        # Coupled models have additional input files 
        if 'CPLINTMPL' in cfDict:
            self.CPLINTMPL = cfDict['CPLINTMPL']
            if self.CPLINTMPL == "auto":
                self.CPLINTMPL = f"{self.TEMPLPATH}/{self.APP}.coupling.in"
        else:
            self.CPLINTMPL = None

        if 'WRFINTMPL' in cfDict:
            self.WRFINTMPL = cfDict['WRFINTMPL']
            if self.WRFINTMPL == "auto":
                self.WRFINTMPL = f"{self.TEMPLPATH}/wrf.namelist.input"
        else:
            self.WRFINTMPL = None

        if self.OCNINTMPL == "auto":
            self.OCNINTMPL = f"{self.TEMPLPATH}/{self.APP}.ocean.in"

        return


    def make_oceanin(self):
        """ Create the ocean.in file from a template"""
        APP = self.APP

        # Create the ocean.in file from a template
        if APP == 'liveocean':
            self.__make_oceanin_lo()
        elif APP == 'adnoc':
            self.__make_oceanin_adnoc()
        elif APP in ("cbofs","ciofs","dbofs","gomofs","tbofs", "eccofs"):
            self.__make_oceanin_nosofs()
        elif APP == 'wrfroms':
            self.__make_oceanin_wrfroms()
        else:
            raise Exception(f"I don't know how to create an ocean.in for {APP}")

        return


    def __make_oceanin_lo(self):
        """ Create the ocean.in file for liveocean forecasts """

        CDATE = self.CDATE
        APP = self.APP
        COMROT = self.COMROT
        PTMP = self.PTMP
        EXPNAME = self.EXPNAME
        OUTDIR = self.OUTDIR

        if int(CDATE) >= 2016010101:
            TRAPSDIR = "trapsF00"
        else:
            TRAPSDIR = "traps00"

        template = self.OCNINTMPL

        fdate = util.lo_date(CDATE)
        prevdate = util.ndate(CDATE, -1)
        fprevdate = util.lo_date(prevdate)

        self.OUTDIR = f"{COMROT}/LO_roms/{EXPNAME}/{fdate}"

        if debug:
            print(f'self.OUTDIR: {self.OUTDIR}')
            print(f'self.COMROT: {self.COMROT}')

        if not os.path.exists(self.OUTDIR):
            os.makedirs(self.OUTDIR)

        self.ININAME = f"{COMROT}/LO_roms/{EXPNAME}/{fprevdate}/ocean_rst.nc"

        DSTART = util.ndays(CDATE, self.TIME_REF)
        # DSTART = days from TIME_REF to start of forecast day
        # ndays returns arg1 - arg2

        settings = {
            "__NTIMES__": self.NTIMES,
            "__TIME_REF__": self.TIME_REF,
            "__DSTART__": DSTART,
            "__FDATE__": fdate,
            "__ININAME__": self.ININAME,
            "__COMROT__": COMROT,
            "__SAVEDIR": self.SAVEDIR,
            "__TRAPSDIR__" : TRAPSDIR
        }

        # Create the ocean.in, decompose NTILEI x NTILEJ
        outfile = f"{self.OUTDIR}/liveocean.in"
        squareness = 0.5
        # squareness=0.375   # Testing 6 nodes (9x24) crashes, .444 crashes (12x18)
        # squareness=0.5
        # squareness=0.02222
        print(f'calling util.makeOceanin')
        util.makeOceanin(self.NPROCS, settings, template, outfile, squareness=squareness)

        return



    def __make_oceanin_nosofs(self):
        """ Create the ocean.in file for nosofs forecasts """

        CDATE = self.CDATE
        HH = self.HH
        APP = self.APP
        COMROT = self.COMROT

        self.OUTDIR = f"{COMROT}/{APP}.{CDATE}"

        if not os.path.exists(self.OUTDIR):
            os.makedirs(self.OUTDIR)

        if debug:
            print(f"DEBUG: self.OUTDIR: {self.OUTDIR}")

        # The restart date is 6 hours prior to CDATE
        # DSTART = days from TIME_REF to start of forecast day
        # ndays returns arg1 - arg2
        prev6hr = util.ndate_hrs(f"{CDATE}{HH}", -6)
        DSTART = util.ndays(prev6hr, self.TIME_REF)
        # Reformat the date
        DSTART = f"{'{:.4f}'.format(float(DSTART))}d0"

        JAN1CURYR = f"{CDATE[0:4]}010100"
        TIDE_START = util.ndays(JAN1CURYR, self.TIME_REF)
        TIDE_START = f"{'{:.4f}'.format(float(TIDE_START))}d0"

        if debug:
            print(f"JAN1CURYR: {JAN1CURYR}, TIME_REF: {self.TIME_REF}")
            print("ndays: ", util.ndays(JAN1CURYR, self.TIME_REF))
            print(f"TIDE_START: {TIDE_START}")

        # These are the templated variables to replace via substitution
        # Note: 
        #    __VARNAME__ will be replaced in the template file if __VARNAME__ is present in the template
        #    otherwise it will use whatever values are hardcoded in the template file
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
        # squareness is used to better balance NtileI/NtileJ with the specific grid
        # This can impact performance

        # squareness of decomposition i,j tiling 
        if APP == 'dbofs':
            squareness = 0.16
        else:
            squareness = 1.0

        if self.OCEANIN == "auto":
            self.OCEANIN = f"{self.OUTDIR}/nos.{APP}.forecast.{CDATE}.t{HH}z.in"
        elif self.OCEANIN == "":
            raise Exception(f"No ocean.in file specified")
            
        util.makeOceanin(self.NPROCS, settings, self.OCNINTMPL, self.OCEANIN, ratio=squareness)



    def __make_oceanin_adnoc(self):
        """ Create the ocean.in file for adnoc forecasts """

        CDATE = self.CDATE
        APP = self.APP
        COMROT = self.COMROT

        if self.OUTDIR == "auto":
            self.OUTDIR = f"{COMROT}/{APP}/{CDATE}"

        if not os.path.exists(self.OUTDIR):
            os.makedirs(self.OUTDIR)

        settings = {
            "__NTIMES__": self.NTIMES,
            "__TIME_REF__": self.TIME_REF
        }

        template = self.OCNINTMPL

        # Create the ocean.in
        if self.OCEANIN == "auto":
            outfile = f"{self.OUTDIR}/ocean.in"
            self.OCEANIN = outfile
            util.makeOceanin(self.NPROCS, settings, template, outfile)
        return



    def __make_oceanin_wrfroms(self):
        """ Create the ocean.in file for wrfroms forecasts """

        CDATE = self.CDATE
        HH = self.HH
        APP = self.APP
        COMROT = self.COMROT

        if self.OUTDIR == "auto":
            self.OUTDIR = f"{COMROT}/{APP}/{CDATE}{HH}"

        if not os.path.exists(self.OUTDIR):
            os.makedirs(self.OUTDIR)

        # TODO - generalize this better, also need to calculate end year, mo, day, etc. 
        # Hardcoded for DT=60
        # TODO Set END DAY, HR, etc.
        DT=60
        self.NHOURS = int(int(self.NTIMES)/DT)

        # TODO: FIX THIS. It does not come out right for wrfroms
        #     DSTART =  2064.25d0                      ! days
        #     TIDE_START =  0.0d0                      ! days
        #     "CDATE": "20110827",
        #     "HH": "06",
        #     "TIME_REF": "20060101.0d0",
        # DSTART is days since TIME_REF
        DSTART = util.ndays(f"{CDATE}{HH}", self.TIME_REF)
        # Reformat the date
        DSTART = f"{'{:.4f}'.format(float(DSTART))}d0"

        JAN1CURYR = f"{CDATE[0:4]}010100"
        TIDE_START = util.ndays(JAN1CURYR, self.TIME_REF)
        TIDE_START = f"{'{:.4f}'.format(float(TIDE_START))}d0"

        # These are the templated variables to replace via substitution
        settings = {
            "__NTIMES__": self.NTIMES,
            "__DSTART__": DSTART,
            "__TIDE_START__": TIDE_START,
            "__TIME_REF__": self.TIME_REF
        }

        template = self.OCNINTMPL

        # Create the ocean.in
        if self.OCEANIN == "auto":
            outfile = f"{self.OUTDIR}/roms_doppio_coupling.in"
            util.makeOceanin(self.NPROCS, settings, template, outfile)
        return


    def __make_couplerin(self):
        """ Create the .in file for coupled wrfroms forecasts """

        #coupling_esmf_atm_sbl.in
        CDATE = self.CDATE
        HH = self.HH
        APP = self.APP
        COMROT = self.COMROT

        if self.OUTDIR == "auto":
            self.OUTDIR = f"{COMROT}/{APP}/{CDATE}{HH}"

        if not os.path.exists(self.OUTDIR):
            os.makedirs(self.OUTDIR)
       
        startdate = CDATE+HH
        startyear = startdate[0:4]
        startmo   = startdate[4:6]
        startdy   = startdate[6:8]
        starthr   = startdate[8:10]
  
        # TODO - generalize this better, also need to calculate end year, mo, day, etc. 
        # Hardcoded for DT=60
        DT=60
        NHOURS = int(int(self.NTIMES)/DT)
        
        stopdate = util.ndate_hrs(f"{CDATE}{HH}", NHOURS)
        stopyear = stopdate[0:4]
        stopmo   = stopdate[4:6]
        stopdy   = stopdate[6:8]
        stophr   = stopdate[8:10]

        # TODO - generalize ReferenceTime also
        settings = {
            "__NPROCS__": self.NPROCS,
            "__STARTYEAR__": startyear,
            "__STARTMO__": startmo,
            "__STARTDY__": startdy,
            "__STARTHR__": starthr,
            "__STOPYEAR__": stopyear,
            "__STOPMO__": stopmo,
            "__STOPDY__": stopdy,
	    "__STOPHR__": stophr
        }

        template = self.CPLINTMPL

        # Create the coupler input file
        outfile = f"{self.OUTDIR}/coupling_esmf_atm_sbl.in"
        util.makeOceanin(self.NPROCS, settings, template, outfile)
        return



    def __make_wrfin(self):
        """ Create the namelist input and output files for coupled wrfroms forecasts """

        CDATE = self.CDATE
        HH = self.HH
        APP = self.APP
        COMROT = self.COMROT


        if self.OUTDIR == "auto":
            self.OUTDIR = f"{COMROT}/{APP}/{CDATE}{HH}"

        if not os.path.exists(self.OUTDIR):
            os.makedirs(self.OUTDIR)

        startdate = CDATE+HH
        startyear = startdate[0:4]
        startmo   = startdate[4:6]
        startdy   = startdate[6:8]
        starthr   = startdate[8:10]

        # TODO - generalize this better, also need to calculate end year, mo, day, etc. 
        # Hardcoded for DT=60
        DT=60
        NHOURS = int(int(self.NTIMES)/DT)

        stopdate = util.ndate_hrs(f"{CDATE}{HH}", NHOURS)
        stopyear = stopdate[0:4]
        stopmo   = stopdate[4:6]
        stopdy   = stopdate[6:8]
        stophr   = stopdate[8:10]

        # TODO - generalize ReferenceTime also
        settings = {
            "__NHOURS__": self.NHOURS,
            "__STARTYEAR__": startyear,
            "__STARTMO__": startmo,
            "__STARTDY__": startdy,
            "__STARTHR__": starthr,
            "__STOPYEAR__": stopyear,
            "__STOPMO__": stopmo,
            "__STOPDY__": stopdy,
            "__STOPHR__": stophr
        }

        template = self.WRFINTMPL
        outfile = f"{self.OUTDIR}/namelist.input"
        util.makeOceanin(self.NPROCS, settings, template, outfile)

        return


if __name__ == '__main__':
    pass
