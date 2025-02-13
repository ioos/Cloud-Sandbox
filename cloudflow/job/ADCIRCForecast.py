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


class ADCIRCForecast(Job):
    """ Implementation of Job class for ADCIRC Forecasts

    Attributes
    ----------
    jobtype : str
        Always 'adcircforecast' for this class.

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

    BUCKET : str
        The cloud bucket name for saving results

    BCKTFLDR : str
        The cloud folder name for saving results

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

        self.jobtype = 'adcircforecast'
        self.configfile = configfile

        self.NPROCS = NPROCS
        self.TEMPLPATH = f"{curdir}/templates"

        if debug:
            print(f"DEBUG: in ADCIRCForecast init")
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
        self.CDATE = cfDict['CDATE']
        self.HH = cfDict['HH']
        self.COMROT = cfDict['COMROT']
        self.EXEC = cfDict['EXEC']
        self.BUCKET = cfDict['BUCKET']
        self.BCKTFLDR = cfDict['BCKTFLDR']
        self.ININAME = cfDict['ININAME']
        self.OUTDIR = cfDict['OUTDIR']
        self.OCEANIN = cfDict['OCEANIN']
        self.OCNINTMPL = cfDict['OCNINTMPL']
	
        if self.CDATE == "today":
            today = datetime.date.today().strftime("%Y%m%d")
            self.CDATE = today
	
        return

if __name__ == '__main__':
    pass
