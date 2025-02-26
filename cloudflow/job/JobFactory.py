import json

from cloudflow.job.Job import Job
from cloudflow.job.ROMSForecast import ROMSForecast
from cloudflow.job.ROMSHindcast import ROMSHindcast
from cloudflow.job.Plotting import Plotting
from cloudflow.job.FVCOMForecast import FVCOMForecast
from cloudflow.job.ADCIRCForecast import ADCIRCForecast
from cloudflow.job.ADCIRCReanalysis import ADCIRCReanalysis
from cloudflow.job.NWMv3_WRF_Hydro_Template import NWMv3_WRF_Hydro_Template
from cloudflow.job.DFLOWFM_Template import DFLOWFM_Template
from cloudflow.job.SCHISM_Template import SCHISM_Template
from cloudflow.job.ADCIRC_Template import ADCIRC_Template
from cloudflow.job.ROMS_Template import ROMS_Template
from cloudflow.job.FVCOM_Template import FVCOM_Template

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


debug = True

# noinspection PyCallingNonCallable
class JobFactory:
    """ Class factory for different Job implementations """

    def __init__(self):
        return

    def job(self, configfile: str, NPROCS: int) -> Job:
        """ Create a new specific type of Job instance

        Parameters
        ----------
        configfile : str

        NPROCS : int
            The number of processors to run the job on

        Returns
        -------
        newjob : Job

        """

        newjob = None

        cfdict = self.readconfig(configfile)
        jobtype = cfdict['JOBTYPE']

        if jobtype == 'romsforecast':
            newjob = ROMSForecast(configfile, NPROCS)
        if jobtype == 'romshindcast':
            newjob = ROMSHindcast(configfile, NPROCS)
        elif jobtype == 'fvcomforecast':
            newjob = FVCOMForecast(configfile, NPROCS)
        elif jobtype == 'adcircforecast':
            newjob = ADCIRCForecast(configfile, NPROCS)
        elif (jobtype == 'plotting') or (jobtype == 'plotting_diff'):
            newjob = Plotting(configfile, NPROCS)
        elif (jobtype == 'adcircreanalysis'):
            newjob = ADCIRCReanalysis(configfile, NPROCS)
        elif (jobtype == 'dflowfm_template'):
            newjob = DFLOWFM_Template(configfile, NPROCS)
        elif (jobtype == 'schism_template'):
            newjob = SCHISM_Template(configfile, NPROCS)
        elif (jobtype == 'nwmv3_wrf_hydro_template'):
            newjob = NWMv3_WRF_Hydro_Template(configfile, NPROCS)
        elif (jobtype == 'adcirc_template'):
            newjob = ADCIRC_Template(configfile, NPROCS)
        elif (jobtype == 'roms_template'):
            newjob = ROMS_Template(configfile, NPROCS)
        elif (jobtype == 'fvcom_template'):
            newjob = FVCOM_Template(configfile, NPROCS)
        else:
            raise Exception('Unsupported jobtype')

        return newjob


    # TODO: this is so frequently used, don't need multiple definitions of it
    def readconfig(self,configfile):
        """ Reads a JSON configuration file into a dictionary.

        Parameters
        ----------
        configfile : str
          Full path and filename of a JSON configuration file for this cluster.

        Returns
        -------
        cfDict : dict
          Dictionary containing this cluster parameterized settings.
        """

        with open(configfile, 'r') as cf:
            cfDict = json.load(cf)

        if debug:
            print(json.dumps(cfDict, indent=4))
            print(str(cfDict))

        return cfDict
