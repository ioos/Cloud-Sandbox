import datetime
import json
import os
import sys

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

from job.Job import Job
import utils.romsUtil as util

__copyright__ = "Copyright © 2020 RPS Group. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

debug = True



class Plotting(Job):

    def __init__(self, configfile, NPROCS):

        self.jobtype = 'plotting'
        self.configfile = configfile
        self.NPROCS = NPROCS

        self.BUCKET = ''
        self.BCKTFLDR = ''
        self.CDATE = ''
        self.OUTDIR = ''

        with open(configfile, 'r') as cf:
            cfDict = json.load(cf)

        if (debug):
            print(json.dumps(cfDict, indent=4))
            print(str(cfDict))

        self.parseConfig(cfDict)

    ########################################################################

    def parseConfig(self, cfDict):

        self.OFS = cfDict['OFS']
        self.CDATE = cfDict['CDATE']
        self.HH = cfDict['HH']
        self.INDIR = cfDict['INDIR']
        self.OUTDIR = cfDict['OUTDIR']
        self.VARS = cfDict['VARS']
        self.BUCKET = cfDict['BUCKET']
        self.BCKTFLDR = cfDict['BCKTFLDR']
        self.FSPEC = cfDict['FSPEC']

        if self.CDATE == "today":
            today = datetime.date.today().strftime("%Y%m%d")
            self.CDATE = today

        CDATE = self.CDATE

        # TODO: Set up optional specification of BASELINE folder in job json.

        if self.OFS == "liveocean":
            fdate = f"f{CDATE[0:4]}.{CDATE[4:6]}.{CDATE[6:8]}"
            if self.INDIR == "auto":
                self.INDIR = f"/com/liveocean/{fdate}"
            if self.OUTDIR == "auto":
                self.OUTDIR = f"/com/liveocean/plots/{fdate}"
            self.BASELINE = f"/com/liveocean-uw/{fdate}"

        elif self.OFS in util.nosofs_models:
            if self.INDIR == "auto":
                self.INDIR = f"/com/nos/{self.OFS}.{self.CDATE}"
            if self.OUTDIR == "auto":
                self.OUTDIR = f"/com/nos/plots/{self.OFS}.{self.CDATE}"
            self.BASELINE = f"/com/nos-noaa/{self.OFS}.{self.CDATE}"
        elif self.OFS == "adnoc":
            if self.INDIR == "auto":
                self.INDIR = f"/com/adnoc/{self.OFS}.{self.CDATE}"
            if self.OUTDIR == "auto":
                self.OUTDIR = f"/com/adnoc/plots/{self.OFS}.{self.CDATE}" 
            self.BASELINE = f"/com/adnoc-baseline/{self.OFS}.{self.CDATE}"

        else:
            raise Exception(f"{self.OFS} is not a supported forecast")


        return
    ########################################################################


if __name__ == '__main__':
    pass
