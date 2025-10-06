import json

from cloudflow.job.Job import Job

from cloudflow.job.ROMSForecast import ROMSForecast
from cloudflow.job.ROMSHindcast import ROMSHindcast
from cloudflow.job.ucla_roms import ucla_roms
from cloudflow.job.ROMS_Basic import ROMS_Basic

from cloudflow.job.FVCOMForecast import FVCOMForecast
from cloudflow.job.FVCOM_Hindcast import FVCOM_Hindcast
from cloudflow.job.FVCOM_Experiment import FVCOM_Experiment
from cloudflow.job.FVCOM_Basic import FVCOM_Basic

from cloudflow.job.ADCIRCForecast import ADCIRCForecast
from cloudflow.job.ADCIRCReanalysis import ADCIRCReanalysis
from cloudflow.job.ADCIRC_Basic import ADCIRC_Basic

from cloudflow.job.SCHISM_Hindcast import SCHISM_Hindcast
from cloudflow.job.SCHISM_Basic import SCHISM_Basic

from cloudflow.job.Plotting import Plotting

from cloudflow.job.WRF_Hydro_Basic import WRF_Hydro_Basic

from cloudflow.job.DFLOWFM_Basic import DFLOWFM_Basic

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"

debug = False

# noinspection PyCallingNonCallable
class JobFactory:
    """ Class factory for different Job implementations based on model class """

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
        model = cfdict['MODEL']

        if(model == 'ROMS'):
            if jobtype == 'romsforecast':
                newjob = ROMSForecast(configfile, NPROCS)
            elif jobtype == 'romshindcast':
                newjob = ROMSHindcast(configfile, NPROCS)
            elif jobtype == 'ucla-roms':
                newjob = ucla_roms(configfile, NPROCS)
            elif (jobtype == 'roms_basic'):
                newjob = ROMS_Basic(configfile, NPROCS)
            else:
                raise Exception('Unsupported jobtype')

        if(model == 'FVCOM'):
            if jobtype == 'fvcomforecast':
                newjob = FVCOMForecast(configfile, NPROCS)
            elif jobtype == 'fvcomhindcast':
                newjob = FVCOM_Hindcast(configfile, NPROCS)
            elif (jobtype == 'fvcom_experiment'):
                newjob = FVCOM_Experiment(configfile, NPROCS)
            elif (jobtype == 'fvcom_basic'):
                newjob = FVCOM_Basic(configfile, NPROCS)
            else:
                raise Exception('Unsupported jobtype')

        if(model == 'ADCIRC'):
            elif jobtype == 'adcircforecast':
                newjob = ADCIRCForecast(configfile, NPROCS)
            elif (jobtype == 'adcircreanalysis'):
                newjob = ADCIRCReanalysis(configfile, NPROCS)
            elif (jobtype == 'adcirc_basic'):
                newjob = ADCIRC_Basic(configfile, NPROCS)
            else:
                raise Exception('Unsupported jobtype')

        if(model == 'SCHISM'):
            if (jobtype == 'schism_hindcast'):
                newjob = SCHISM_Hindcast(configfile, NPROCS)
            elif (jobtype == 'schism_basic'):
                newjob = SCHISM_Basic(configfile, NPROCS)
            else:
                raise Exception('Unsupported jobtype')

        if(model == 'DFLOWFM'):
            if (jobtype == 'dflowfm_basic'):
                newjob = DFLOWFM_Basic(configfile, NPROCS)
            else:
                raise Exception('Unsupported jobtype')

        if(model == 'WRF_HYDRO'):
            if (jobtype == 'wrf_hydro_basic'):
                newjob = WRF_Hydro_Basic(configfile, NPROCS)
            else:
                raise Exception('Unsupported jobtype')

        if(model == 'PYTHON'):
            if (jobtype == 'plotting') or (jobtype == 'plotting_diff'):
                newjob = Plotting(configfile, NPROCS)
            else:
                raise Exception('Unsupported jobtype')

    
        else:
            raise Exception('Unsupported MODEL')

        return newjob


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
