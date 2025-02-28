import datetime
import os
import sys

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

curdir = os.path.dirname(os.path.abspath(__file__))

from cloudflow.job.Job import Job
from cloudflow.utils import modelUtil as util

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


debug = False


class ADCIRCReanalysis(Job):
    """ Implementation of Job class for ADCIRC Reanalysis (CORA)

    Attributes
    ----------
    jobtype : str
        Always 'adcircforecast' for this class.

    configfile : str

        A JSON configuration file containing the required parameters for this job.
        Usually in job/jobs folder. 

    NPROCS : int
        Total number of processors in this cluster.

    OFS : str
        The ocean forecast to run.

    YYYY : str
        The run date in format YYYY

    BUCKET : str
        The cloud bucket name for saving results

    BCKTFLDR : str
        The cloud folder name for saving results

    OUTDIR : str
        The full path to the output folder

    ProjectName

    ProjectHome

    ADCIRCHome

    GRID

    CONFIGTMPL : str
        The model configuration template file.

    """


    # TODO: make self and cfDict consistent
    def __init__(self, configfile, NPROCS ):
        """ Constructor

        Parameters
        ----------
        configfile : str

        NPROCS : int
            The number of processors to run the job on

        """

        self.jobtype = 'adcircreanalysis'
        self.configfile = configfile

        self.NPROCS = NPROCS

        self.TEMPLPATH = f"{curdir}/templates"

        if debug:
            print(f"DEBUG: in ADCIRCReanalysis init")
            print(f"DEBUG: job file is: {configfile}")

        cfDict = self.readConfig(configfile)
        self.parseConfig(cfDict)

        self.make_config()

        return


    def parseConfig(self, cfDict):
        """ Parses the configuration dictionary to class attributes

        Parameters
        ----------
        cfDict : dict
          Dictionary containing this cluster parameterized settings.
        """

        self.OFS = cfDict['OFS']
        self.YYYY = cfDict['YYYY']
        self.BUCKET = cfDict['BUCKET']
        self.BCKTFLDR = cfDict['BCKTFLDR']
        self.OUTDIR = cfDict['OUTDIR']
        self.ProjectName = cfDict['ProjectName']
        self.ProjectHome = cfDict['ProjectHome']
        self.ADCIRCHome = cfDict['ADCIRCHome']
        self.GRID = cfDict['GRID']
        self.CONFIG = cfDict['CONFIG']
        self.CONFIGTMPL = cfDict['CONFIGTMPL']
        self.contact    = cfDict['contact']
        self.WRITERCORES = cfDict['WRITERCORES']
	
        return

    def make_config(self):

        if self.OFS == 'adcirc-cora':
            self.__make_cora_config()
        else:
            raise Exception(f"I don't know how to create a config for {OFS}")


    def __make_cora_config(self):
        """ Create the config file used by ADCIRC run_storms.sh """
        YYYY = self.YYYY

        print(f'in {__name__}: YYYY : {YYYY}')

        template = self.CONFIGTMPL

        settings = {
           "__ProjectName__": self.ProjectName,
           "__ProjectHome__": self.ProjectHome,
           "__ADCIRCHome__": self.ADCIRCHome,
           "__contact__": self.contact,
           "__GRID__": self.GRID,
           "__NPROCS__": self.NPROCS,
           "__WRITERCORES__": self.WRITERCORES
        }

        # Create the CORA config file
        outfile = self.CONFIG
        util.sedoceanin(template, outfile, settings)

if __name__ == '__main__':
    pass
