import json

from cloudflow.job.Job import Job
from cloudflow.job.ROMSForecast import ROMSForecast
from cloudflow.job.Plotting import Plotting
from cloudflow.job.FVCOMForecast import FVCOMForecast
from cloudflow.job.ADCIRCForecast import ADCIRCForecast

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
        elif jobtype == 'fvcomforecast':
            newjob = FVCOMForecast(configfile, NPROCS)
        elif jobtype == 'adcircforecast':
            newjob = ADCIRCForecast(configfile, NPROCS)
        elif (jobtype == 'plotting') or (jobtype == 'plotting_diff'):
            newjob = Plotting(configfile, NPROCS)
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
