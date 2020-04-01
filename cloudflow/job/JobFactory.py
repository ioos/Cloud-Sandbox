import json

from .Job import Job
from .ROMSForecast import ROMSForecast
from .Plotting import Plotting
from .FVCOMForecast import FVCOMForecast

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

debug = True


# noinspection PyCallingNonCallable
class JobFactory:

    def __init__(self):
        return


    def job(self, configfile: str, NPROCS: int) -> Job:

        newjob = None

        cfdict = self.readconfig(configfile)
        jobtype = cfdict['JOBTYPE']

        if jobtype == 'romsforecast':
            newjob = ROMSForecast(configfile, NPROCS)
        elif jobtype == 'fvcomforecast':
            newjob = FVCOMForecast(configfile, NPROCS)
        elif (jobtype == 'plotting') or (jobtype == 'plotting_diff'):
            newjob = Plotting(configfile, NPROCS)
        else:
            raise Exception('Unsupported jobtype')

        return newjob


    def readconfig(self,configfile):

        with open(configfile, 'r') as cf:
            cfdict = json.load(cf)

        if debug:
            print(json.dumps(cfdict, indent=4))
            print(str(cfdict))

        return cfdict
