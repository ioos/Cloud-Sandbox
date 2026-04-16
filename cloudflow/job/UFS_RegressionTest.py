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


class UFS_RegressionTest(Job):
    """ Implementation of Job class for UFS runs. Initially this is setup to run the ufs weather app regression test, rt.sh. This is a simple test case to get the UFS workflow running in cloudflow. Future iterations will expand this to run more complex UFS applications and configurations.

    Attributes
    ----------
    MODEL : str
        The model affiliation class to reference for cloudflow

    jobtype : str
        User defined job type, should always be ufs_experiment

    TESTNAME : str
        The UFS rt testname

    NPROCS : int
        Total number of processors in this cluster.

    TODO: fill in py comments
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

        self.jobtype  = cfDict['JOBTYPE']
        # TODO: Add assert on jobtype
        self.MODEL    = cfDict['MODEL']
        self.APP      = cfDict['APP']
        self.TESTNAME = cfDict['TESTNAME']
        self.SAVEDIR  = cfDict['SAVEDIR']
        self.PTMP     = cfDict['PTMP']
        self.DISKNM   = cfDict['DISKNM']
        self.SKIPCOMPILE = cfDict.get('SKIPCOMPILE', 'NO')

        return

    def createRunTemplates(self):
        print(f"STUB: update variables used by rt.sh for decomposition, e.g. I, J PES.")


if __name__ == '__main__':
    pass
