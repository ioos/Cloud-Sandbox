import datetime
import os
import sys
import shutil

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

curdir = os.path.dirname(os.path.abspath(__file__))

from job.Job import Job
import utils.romsUtil as util

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

debug = False

class FVCOMForecast(Job):

    # TODO: make self and cfDict consistent
    def __init__(self, configfile, NPROCS):

        self.jobtype = 'fvcomforecast'
        self.configfile = configfile

        self.NPROCS = NPROCS
        self.TEMPLPATH = f"{curdir}/templates"

        if debug:
            print(f"DEBUG: in FVCOMForecast init")
            print(f"DEBUG: job file is: {configfile}")

        cfDict = self.readConfig(configfile)

        self.parseConfig(cfDict)
        self.make_fcstin()

        if self.LOCALNEST:
            # nos.ngofs.nestnode.negofs.forecast.20200225.t03z.nc
            PARENTNEST = f"{self.COMROT}/ngofs.{self.CDATE}/nos.ngofs.nestnode.{self.OFS}.forecast.{self.CDATE}.t{self.HH}z.nc"
            LOCALOBC   = f"{self.OUTDIR}/nos.{self.OFS}.obc.{self.CDATE}.t{self.HH}z.nc"
            shutil.copyfile(PARENTNEST, LOCALOBC) 

    ########################################################################
    def parseConfig(self, cfDict):

        self.OFS = cfDict['OFS']
        self.CDATE = cfDict['CDATE']
        self.HH = cfDict['HH']
        self.NHOURS = cfDict['NHOURS']
        self.COMROT = cfDict['COMROT']
        self.DATE_REF = cfDict['DATE_REF']
        self.BUCKET = cfDict['BUCKET']
        self.BCKTFLDR = cfDict['BCKTFLDR']
        self.OUTDIR = cfDict['OUTDIR']
        self.INPUTFILE = cfDict['INPUTFILE']
        self.INTMPL = cfDict['INTMPL']       # Input file template

        # NESTING support
        if self.OFS in ('nwgofs', 'negofs'):
          self.LOCALNEST = cfDict['LOCALNEST'] == "True"   # Correctly evaluates to True or False boolean
        else:
          self.LOCALNEST = None

        if self.CDATE == "today":
            today = datetime.date.today().strftime("%Y%m%d")
            self.CDATE = today

        if self.INTMPL == "auto":
            self.INTMPL = f"{self.TEMPLPATH}/{self.OFS}.fcst.in"

        if self.OUTDIR == "auto":
            self.OUTDIR = f"{self.COMROT}/{self.OFS}.{self.CDATE}"

        return

    ########################################################################

    def make_fcstin(self):

        OFS = self.OFS

        # Create the ocean.in file from a template
        if OFS in ('ngofs', 'negofs', 'nwgofs', 'sfbofs', 'leofs', 'lmhofs'):
            self.__make_fcstin_nosofs()
        else:
            raise Exception(f"{OFS} is not a supported forecast")

        return

    ########################################################################

    def __make_fcstin_nosofs(self):

        CDATE = self.CDATE
        HH = self.HH
        OFS = self.OFS
        COMROT = self.COMROT
        NHOURS = self.NHOURS 
        template = self.INTMPL

        if not os.path.exists(self.OUTDIR):
            os.makedirs(self.OUTDIR)

        HHMMSS = f"{self.HH}:00:00"
        START_DATE = f"{CDATE[0:4]}-{CDATE[4:6]}-{CDATE[6:8]}"

        CDATEHH=f"{CDATE}{HH}"
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

        # Create the ocean.in
        if self.INPUTFILE == "auto":
            outfile = f"{self.OUTDIR}/nos.{OFS}.forecast.{CDATE}.t{HH}z.in"
            util.sedoceanin(template, outfile, settings)

        return

    ########################################################################



if __name__ == '__main__':
    pass
