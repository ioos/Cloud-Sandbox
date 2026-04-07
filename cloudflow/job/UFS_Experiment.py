import datetime
import os
import sys

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

curdir = os.path.dirname(os.path.abspath(__file__))

from cloudflow.job.Job import Job

__copyright__ = "Copyright © 2023 Tetra Tech, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


debug = False


class UFS_Experiment(Job):
    """ Implementation of Job class for UFS runs. Initially this is setup to run the ufs weather app regression test, rt.sh. This is a simple test case to get the UFS workflow running in cloudflow. Future iterations will expand this to run more complex UFS applications and configurations.

    Attributes
    ----------
    MODEL : str
        The model affiliation class to reference for cloudflow

    jobtype : str
        User defined job type, should always be ufs_experiment

    APP : str
        The model workflow application to run.

    configfile : str
        A JSON configuration file containing the required parameters for this job.

    NPROCS : int
        Total number of processors in this cluster.

    EXEC : str
        The model executable to run.

    MODEL_DIR : str
        The location of the model run directory to execute

    IN_FILE : str
        The UFS input file for a given model configuration
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

        self.configfile = configfile

        self.NPROCS = NPROCS

        if debug:
            print(f"DEBUG: in UFS Experiment init")
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

        self.MODEL = cfDict['MODEL']
        self.jobtype = cfDict['JOBTYPE']
        self.APP = cfDict.get('APP', "basic")
        self.EXEC = cfDict['EXEC']
        self.MODEL_DIR = cfDict['MODEL_DIR']
        self.IN_FILE = cfDict['IN_FILE']
        return


if __name__ == '__main__':
    pass
