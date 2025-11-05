import json

from cloudflow.job.Job import Job

from cloudflow.job.ROMSForecast import ROMSForecast
from cloudflow.job.ROMSHindcast import ROMSHindcast
from cloudflow.job.ROMS_Experiment import ROMS_Experiment

from cloudflow.job.FVCOMForecast import FVCOMForecast
from cloudflow.job.FVCOM_Hindcast import FVCOM_Hindcast
from cloudflow.job.FVCOM_Experiment import FVCOM_Experiment

from cloudflow.job.ADCIRCForecast import ADCIRCForecast
from cloudflow.job.ADCIRCReanalysis import ADCIRCReanalysis
from cloudflow.job.ADCIRC_Experiment import ADCIRC_Experiment

from cloudflow.job.SCHISM_Hindcast import SCHISM_Hindcast
from cloudflow.job.SCHISM_Experiment import SCHISM_Experiment

from cloudflow.job.PYTHON_Experiment import PYTHON_Experiment
from cloudflow.job.Plotting import Plotting

from cloudflow.job.WRF_Hydro_Experiment import WRF_Hydro_Experiment

from cloudflow.job.DFLOWFM_Experiment import DFLOWFM_Experiment

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

        if model == 'ROMS':
            if jobtype == 'romsforecast':
                newjob = ROMSForecast(configfile, NPROCS)
            elif jobtype == 'romshindcast':
                newjob = ROMSHindcast(configfile, NPROCS)
            elif jobtype == 'roms_experiment':
                newjob = ROMS_Experiment(configfile, NPROCS)
            else:
                raise Exception(f'Unsupported {model} jobtype')

        elif model == 'FVCOM':
            if jobtype == 'fvcomforecast':
                newjob = FVCOMForecast(configfile, NPROCS)
            elif jobtype == 'fvcomhindcast':
                newjob = FVCOM_Hindcast(configfile, NPROCS)
            elif jobtype == 'fvcom_experiment':
                newjob = FVCOM_Experiment(configfile, NPROCS)
            else:
                raise Exception(f'Unsupported {model} jobtype')

        elif model == 'ADCIRC':
            if jobtype == 'adcircforecast':
                newjob = ADCIRCForecast(configfile, NPROCS)
            elif jobtype == 'adcircreanalysis':
                newjob = ADCIRCReanalysis(configfile, NPROCS)
            elif jobtype == 'adcirc_experiment':
                newjob = ADCIRC_Experiment(configfile, NPROCS)
            else:
                raise Exception(f'Unsupported {model} jobtype')

        elif model == 'SCHISM':
            if jobtype == 'schism_hindcast':
                newjob = SCHISM_Hindcast(configfile, NPROCS)
            elif jobtype == 'schism_experiment':
                newjob = SCHISM_Experiment(configfile, NPROCS)
            else:
                raise Exception(f'Unsupported {model} jobtype')

        elif model == 'DFLOWFM':
            if jobtype == 'dflowfm_experiment':
                newjob = DFLOWFM_Experiment(configfile, NPROCS)
            else:
                raise Exception(f'Unsupported {model} jobtype')

        elif model == 'WRF_HYDRO':
            if jobtype == 'wrf_hydro_experiment':
                newjob = WRF_Hydro_Experiment(configfile, NPROCS)
            else:
                raise Exception(f'Unsupported {model} jobtype')

        elif model == 'PYTHON':
            if jobtype == 'python_experiment':
                newjob = PYTHON_Experiment(configfile, NPROCS)
            elif (jobtype == 'plotting') or (jobtype == 'plotting_diff'):
                newjob = Plotting(configfile, NPROCS)
            else:
                raise Exception(f'Unsupported {model} jobtype')

    
        else:
            raise Exception('Unsupported MODEL class')

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
