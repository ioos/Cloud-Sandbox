import datetime
import json
import os
import sys

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

from cloudflow.job.Job import Job
from cloudflow.utils import modelUtil as util

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


debug = True


class Plotting(Job):
    """ Implementation of Job class for plotting jobs

    Attributes
    ----------
    configfile : str
        A JSON configuration file containing the required parameters for this class.

    jobtype : str
        The specific type of plotting job.

    NPROCS : int
        Total number of processors in this cluster.

    OFS : str
        The ocean forecast to run.

    CDATE : str
        The forecast date in format YYYYMMDD

    HH : string
        The forecast cycle in format HH

    BUCKET : str
        The cloud bucket name for saving results

    BCKTFLDR : str
        The cloud folder name for saving results

    INDIR : str
        The full path to the input folder, usually the same as the OUTDIR for the forecast job

    OUTDIR : str
        The full path to the output folder

    VARS : list of str
        The forecast fields to plot

    FSPEC : list
        The regular expression of the filename specifier for list of input files

    VERIFDIR : str
        The full path to the location of the verification dataset
    """

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
        self.HH = cfDict['HH']
        self.INDIR = cfDict['INDIR']
        self.OUTDIR = cfDict['OUTDIR']
        self.VARS = cfDict['VARS']
        self.BUCKET = cfDict['BUCKET']
        self.BCKTFLDR = cfDict['BCKTFLDR']
        self.FSPEC = cfDict['FSPEC']

        # Diff plots require a directory with the files used to compare
        if 'VERIFDIR' in cfDict:
            self.VERIFDIR = cfDict['VERIFDIR']
        else:
            self.VERIFDIR = None


        if self.CDATE == "today":
            today = datetime.date.today().strftime("%Y%m%d")
            self.CDATE = today

        CDATE = self.CDATE


        if self.OFS == "liveocean":
            fdate = f"f{CDATE[0:4]}.{CDATE[4:6]}.{CDATE[6:8]}"
            if self.INDIR == "auto":
                self.INDIR = f"/com/liveocean/{fdate}"
            if self.OUTDIR == "auto":
                self.OUTDIR = f"/com/liveocean/plots/{fdate}"
            if self.VERIFDIR == "auto":
                self.VERIFDIR = f"/com/liveocean-uw/{fdate}"

        elif self.OFS in util.nosofs_models:
            if self.INDIR == "auto":
                self.INDIR = f"/com/nos/{self.OFS}.{self.CDATE}{self.HH}"
            if self.OUTDIR == "auto":
                self.OUTDIR = f"/com/nos/plots/{self.OFS}.{self.CDATE}{self.HH}"
            if self.VERIFDIR == "auto":
                self.VERIFDIR = f"/com/nos-noaa/{self.OFS}.{self.CDATE}"

        elif self.OFS == "adnoc":
            if self.INDIR == "auto":
                self.INDIR = f"/com/adnoc/{self.OFS}.{self.CDATE}"
            if self.OUTDIR == "auto":
                self.OUTDIR = f"/com/adnoc/plots/{self.OFS}.{self.CDATE}"
            if self.VERIFDIR == "auto":
                self.VERIFDIR = f"/com/adnoc-baseline/{self.OFS}.{self.CDATE}"

        else:
            raise Exception(f"{self.OFS} is not a supported forecast")


        return


if __name__ == '__main__':
    pass
