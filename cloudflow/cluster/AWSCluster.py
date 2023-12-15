"""
Cluster implementation for AWS EC2 clusters.
"""

import time
import json
import logging
import math
from pathlib import Path

import boto3
from botocore.exceptions import ClientError

from cloudflow.cluster import nodeInfo
from cloudflow.cluster.Cluster import Cluster

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


debug = False

log = logging.getLogger('workflow')
log.setLevel(logging.DEBUG)

homedir = Path.home()
timelog = logging.getLogger('qops_timing')
timelog.setLevel(logging.DEBUG)
timelog.propagate = False

fh = logging.FileHandler(f"{homedir}/qops_forecast.log")
fh.setLevel(logging.DEBUG)
formatter = logging.Formatter(' %(asctime)s  %(levelname)s | %(message)s')
fh.setFormatter(formatter)

# To avoid duplicate entries, only have one handler
# This log might have a handler in one of their higher level scripts
# This didn't work - still got duplicates, even when also added in main caller
if not timelog.hasHandlers():
    timelog.addHandler(fh)


class AWSCluster(Cluster):
    """
    Implementation of the Cluster interface for AWS

    Attributes
    ----------
    platform  : str
        The cloud provider. This will always be 'AWS' for this implementation.

    nodeType  : str
        EC2 instance type.

    nodeCount : int
        Number of instances in this cluster.

    NPROCS    : int
        Total number of processors in this cluster.

    PPN       : int
        Number of processors (physical cores) per node.

    tags      : list of dictionary/s of str
        Specific tags to attach to the resources provisioned.

    image_id  : str
        AWS EC2 AMI - Amazon Machine Image

    key_name  : str
         Private key used for SSH access to the instance. This should be configured when creating the AMI.

    sg_ids    : list of str
        Security group ids

    subnet_id : str
        VPC subnet ID to run in

    placement_group : str
        The cluster placement group to use.

    daskscheduler : Popen
        a reference to the Dask scheduler process started on the cluster

    daskworker : Popen
        a reference to the Dask worker process started on the cluster
    """

    def __init__(self, configfile):
        """ Constructor

        Parameters
        ----------
        configfile : str
          A JSON configuration file containing the required parameters for this class.

        Returns
        -------
        AWSCluster
            An initialized instance of this class.
        """

        self.platform = 'AWS'
        self.__configfile = configfile
        self.__state = None  # This could be an enumeration of none, running, stopped, error
        self.__instances = []
        self.__start_time = time.time()
        self.region = ""
        self.nodeType = ''
        self.nodeCount = 0
        self.NPROCS = 0
        self.PPN = 0
        self.tags = []
        self.image_id = ''
        self.key_name = ''
        self.sg_ids = []
        self.subnet_id = ''
        self.placement_group = ''

        cfDict = self.readConfig(configfile)
        self.parseConfig(cfDict)

        self.PPN = nodeInfo.getPPN(self.nodeType)
        self.NPROCS = self.nodeCount * self.PPN

        self.daskscheduler = None
        self.daskworker = None

        log.info(f"nodeCount: {self.nodeCount}  PPN: {self.PPN}")


    def getState(self):
        """ Returns the cluster state. Not currently used. """
        return self.__state

    def setState(self, state):
        """ Set the cluster state. Not currently used."""
        self.__state = state
        return self.__state

    ########################################################################

    def readConfig(self, configfile):
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

        if (debug):
            print(json.dumps(cfDict, indent=4))
            print(str(cfDict))

        # Single responsibility says I should only read it here
        return cfDict

    ########################################################################

    def parseConfig(self, cfDict):
        """ Parses the configuration dictionary to class attributes

        Parameters
        ----------
        cfDict : dict
          Dictionary containing this cluster parameterized settings.

        """
        self.platform = cfDict['platform']
        self.region = cfDict['region']
        self.nodeType = cfDict['nodeType']
        self.nodeCount = cfDict['nodeCount']
        self.tags = cfDict['tags']
        self.image_id = cfDict['image_id']
        self.key_name = cfDict['key_name']
        self.sg_ids = cfDict['sg_ids']
        self.subnet_id = cfDict['subnet_id']
        self.placement_group = cfDict['placement_group']

        return

    ########################################################################

    """ Implemented abstract methods """

    def getCoresPN(self):
        """ Get the number of cores per node in this cluster.

        Returns
        -------
        self.PPN : int
            the number of cores per node in this cluster. Assumes a heterogenous cluster. """

        return self.PPN


    def start(self):
        """ Provision the configured cluster in the cloud.

        Returns
        -------
        self.__instances : list of EC2.Intance
            the list of Instances started. See boto3 documentation.
        """
        ec2 = boto3.resource('ec2', region_name=self.region)

        try:

            if self.nodeType == 'hpc6a.48xlarge':

              self.__instances = ec2.create_instances(
                ImageId=self.image_id,
                InstanceType=self.nodeType,
                KeyName=self.key_name,
                MinCount=self.nodeCount,
                MaxCount=self.nodeCount,
                TagSpecifications=[
                    {
                        'ResourceType': 'instance',
                        'Tags': self.tags
                    }
                ],
                Placement=self.__placementGroup(),
                NetworkInterfaces=[self.__netInterface()]
                #CpuOptions={
                #    'CoreCount': self.PPN,
                #    'ThreadsPerCore': 1
                #}
              )
            else:
              self.__instances = ec2.create_instances(
                ImageId=self.image_id,
                InstanceType=self.nodeType,
                KeyName=self.key_name,
                MinCount=self.nodeCount,
                MaxCount=self.nodeCount,
                TagSpecifications=[
                    {   
                        'ResourceType': 'instance',
                        'Tags': self.tags
                    }
                ],
                Placement=self.__placementGroup(),
                NetworkInterfaces=[self.__netInterface()],
                CpuOptions={
                    'CoreCount': self.PPN,
                    'ThreadsPerCore': 1
                }
              )
        except ClientError as e:
            log.exception('ClientError exception in createCluster' + str(e))
            raise Exception() from e

        self.__start_time = time.time()

        print('Waiting for nodes to enter running state ...')
        # Make sure the nodes are running before returning

        client = boto3.client('ec2', self.region)
        waiter = client.get_waiter('instance_running')

        for instance in self.__instances:
            waiter.wait(
                InstanceIds=[instance.instance_id],
                WaiterConfig={
                    'Delay': 10,
                    'MaxAttempts': 6
                }
            )

        # Wait a little more. sshd is sometimes slow to come up
        time.sleep(90)
        # Assume the nodes are ready, set to False if not
        ready = True

        # if any instance is not running, ready=False
        inum = 1
        for instance in self.__instances:
            state = ec2.Instance(instance.instance_id).state['Name']
            print('instance ' + str(inum) + ' : ' + state)
            if state != 'running':
                ready = False
            inum += 1

        if not (ready):
            self.__terminateCluster()
            raise Exception('Nodes did not start within time limit... terminating them...')

        return self.__instances



    def terminate(self):
        """ Shutdown and remove the EC2 Instances in this cluster.
            Also terminates any associated Dask Worker and Scheduler processes.

        Returns
        -------
        responses : list of dict
            a list of the responses from EC2.Instance.terminate(). See boto3 documentation.
        """
        self.terminateDaskWorker()

        # Terminate any running dask scheduler
        self.terminateDaskScheduler()

        log.info(f"Terminating instances: {self.__instances}")

        ec2 = boto3.resource('ec2', region_name=self.region)

        responses = []

        for instance in self.__instances:
            response = instance.terminate()['TerminatingInstances']
            responses.append(response)

        end_time = time.time()
        elapsed = end_time - self.__start_time
        mins = math.ceil(elapsed / 60.0)
        hrs = mins / 60.0
        nodetype = self.nodeType
        nodecnt = self.nodeCount
        timelog.info(f"Cluster Run Time: {mins} minutes - {nodecnt} x {nodetype}")

        return responses


    def getHosts(self):
        """ Get the list of hosts in this cluster

        Returns
        -------
        hosts : list of str
            list of private dns names
        """
        hosts = []

        for instance in self.__instances:
            # hosts.append(instance.private_dns_name)
            hosts.append(instance.private_ip_address)
        return hosts


    def getHostsCSV(self):
        """ Get a comma separated list of hosts in this cluster

        Returns
        -------
        hosts : str
            a comma separated list of private dns names
        """

        hosts = ''

        instcnt = len(self.__instances)
        cnt = 0
        for instance in self.__instances:
            cnt += 1
            hostname = instance.private_ip_address
            # no comma on last host
            if cnt == instcnt:
                hosts += hostname
            else:
                hosts += hostname + ','
        return hosts



    def __placementGroup(self):
        """ This is a bit of a hack to satisfy AWS. Only c5 and c5n type of instances support placement group """

        group = {}
        if self.nodeType.startswith('c5'):
            group = {'GroupName': self.placement_group}

        return group


    ########################################################################

    #

    def __netInterface(self):
        """ Specify an efa enabled network interface if supported by node type.
            Also attaches security groups """

        interface = {
            'AssociatePublicIpAddress': True,
            'DeleteOnTermination': True,
            'Description': 'Network adaptor via boto3 api',
            'DeviceIndex': 0,
            'Groups': self.sg_ids,
            'SubnetId': self.subnet_id
        }

        # if self.nodeType == 'c5n.18xlarge':
        if self.nodeType in nodeInfo.efaTypes:
            interface['InterfaceType'] = 'efa'

        return interface

    ########################################################################


if __name__ == '__main__':
    pass
