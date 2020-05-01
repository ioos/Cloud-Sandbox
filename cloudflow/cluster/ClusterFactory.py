""" Class factory for different sub-classes of Cluster """

import json
import logging

from prefect.engine import signals

from cloudflow.cluster.AWSCluster  import AWSCluster
from cloudflow.cluster.LocalCluster  import LocalCluster

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

debug = True

log = logging.getLogger('workflow')
log.setLevel(logging.DEBUG)

class ClusterFactory:

    def __init__(self):
        """ Constructor """
        return


    def cluster(self,configfile):
        """ Creates a new Cluster object

        Parameters
        ----------
        configfile : string
            Full path and filename of a JSON configuration file for this cluster.

        Returns
        -------
        newcluster : Cluster
            Returns a new instance of a Cluster implementation.
        """

        cfdict = self.readconfig(configfile)

        provider = cfdict['platform']

        if provider == 'AWS':

            try:
                print('Attempting to make a newcluster :', provider)
                newcluster = AWSCluster(configfile)
            except Exception as e:
                log.exception('Could not create cluster: ' + str(e))
                raise signals.FAIL()
        elif provider == 'Local':
            newcluster = LocalCluster(configfile)

        log.info(f"Created new {provider} cluster")
        return newcluster



    def readconfig(self,configfile):
        """ Reads the configuration file

        Parameters
        ----------
        configfile : string
            Full path and filename of a JSON configuration file for this cluster.

        Returns
        -------
        cfdict : dict
            Dictionary representation of JSON configfile
        """

        with open(configfile, 'r') as cf:
            cfdict = json.load(cf)

        if debug:
            print(json.dumps(cfdict, indent=4))
            print(str(cfdict))

        return cfdict
