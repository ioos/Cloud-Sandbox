""" Class factory for different sub-classes of Cluster """

import json
import logging
import inspect

from prefect.engine import signals

from cloudflow.cluster.AWSCluster  import AWSCluster
from cloudflow.cluster.LocalCluster  import LocalCluster

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"

debug = True

log = logging.getLogger('workflow')

class ClusterFactory:

    def __init__(self):
        """ Constructor """
        log.debug(f"In: {self.__class__.__name__} : {inspect.currentframe().f_code.co_name}")
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

        log.debug(f"In: {self.__class__.__name__} : {inspect.currentframe().f_code.co_name}")

        cfdict = self.readconfig(configfile)

        provider = cfdict['platform']

        if provider == 'AWS':

            log.info(f'Attempting to make a new cluster : {provider}')
            try:
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

        log.debug(f"In: {self.__class__.__name__} : {inspect.currentframe().f_code.co_name}")

        with open(configfile, 'r') as cf:
            cfdict = json.load(cf)

        if debug:
            print(json.dumps(cfdict, indent=4))
            print(str(cfdict))

        return cfdict
