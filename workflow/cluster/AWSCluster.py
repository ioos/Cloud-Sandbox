"""

Cluster implementation for AWS EC2 clusters.

"""
import time
import json
import logging

import boto3
from botocore.exceptions import ClientError

import cluster.nodeInfo as nodeInfo
from cluster.Cluster import Cluster

__copyright__ = "Copyright © 2020 RPS Group. All rights reserved."
__license__ = "Proprietary, see LICENSE file."
__email__ = "patrick.tripp@rpsgroup.com"

debug = False

log = logging.getLogger('workflow')
log.setLevel(logging.DEBUG)

# ch = logging.StreamHandler()
# ch.setLevel(logging.DEBUG)
# formatter = logging.Formatter(' %(asctime)s  %(levelname)s - %(module)s.%(funcName)s | %(message)s')
# ch.setFormatter(formatter)
# log.addHandler(ch)

class AWSCluster(Cluster):
    """
    Implementation of the Cluster interface for AWS

    Attributes
    ----------
    platform  : str
      This will always be 'AWS' for this implementation.

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

    sg_ids    : list: str
      Security group ids

    subnet_id : str
      VPC subnet ID to run in

    placement_group : str
      The cluster placement group to use.

    Methods
    -------

    AWSCluster(configfile : str)
      Constructor. Returns a new AWSCluster object initialized with the settings in `configfile`.

    getCoresPN()
      Returns the number of cores per node in this cluster. Assumes a heterogenous cluster.

    getState()
      Returns the cluster state. Not currently used.

    setState(state: str)
      Set the cluster state. Not currently used.

      TODO: Can use a class property instead.

    readConfig(configfile : str)
      Reads a JSON configuration file `configfile` into a dictionary.

    start()
      Start the cluster. This will provision the configured cluster in the cloud.
      Returns a list of AWS Instances. See boto3 documentation.

    terminate()
      Terminate the cluster. Terminate the EC2 instances in this cluster.
      Returns a list of AWS Results. See boto3 documentation.

    getHosts()
      Get the list of hosts in this cluster

    getHostsCSV() :
      Get a comma separated list of hosts in this cluster

    """

    def __init__(self, configfile):
        """ The config file contains the required parameters in JSON

        Parameters
        ----------
        configfile : str
          A JSON configuration file containing the required parameters for this class.

        Returns
        -------
        An initialized instance of AWSCluster
        """

        self.platform = 'AWS'
        self.__configfile = configfile
        self.__state = "none"  # This could be an enumeration of none, running, stopped, error
        self.__instances = []
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

    ''' 
    Function  Definitions
    =====================
    '''

    def getState(self):
        return self.__state

    def setState(self, state):
        self.__state = state
        return self.__state

    ########################################################################

    def readConfig(self, configfile):
        """
        Reads a JSON configuration file `configfile` into a dictionary.

        Parameters
        ----------
        configfile : string
          Should be a full path and filename of a JSON configuration file for this cluster.

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
        return self.PPN

    def start(self):
        ec2 = boto3.resource('ec2', region_name=self.region)

        try:
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

        print('Waiting for nodes to enter running state ...')
        # Make sure the nodes are running before returning

        client = boto3.client('ec2', self.region)
        waiter = client.get_waiter('instance_running')

        for instance in self.__instances:
            waiter.wait(
                InstanceIds=[instance.instance_id],
                WaiterConfig={
                    'Delay': 10,
                    'MaxAttempts': 3 
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
        self.terminateDaskScheduler()

        # Terminate any running dask scheduler
        self.terminateDaskScheduler()

        log.info(f"Terminating instances: {self.__instances}")

        ec2 = boto3.resource('ec2', region_name=self.region)

        responses = []

        for instance in self.__instances:
            response = instance.terminate()['TerminatingInstances']
            responses.append(response)

        return responses

    def getHosts(self):
        hosts = []

        for instance in self.__instances:
            hosts.append(instance.private_dns_name)
        return hosts

    def getHostsCSV(self):
        hosts = ''

        instcnt = len(self.__instances)
        cnt = 0
        for instance in self.__instances:
            cnt += 1
            hostname = instance.private_dns_name
            # no comma on last host
            if cnt == instcnt:
                hosts += hostname
            else:
                hosts += hostname + ','
        return hosts

    ########################################################################


    ########################################################################
    # This is a bit of a hack to satisfy AWS
    def __placementGroup(self):
        group = {}
        if self.nodeType.startswith('c5'):
            group = {'GroupName': self.placement_group}

        return group

    ########################################################################

    ########################################################################
    # Specify an efa enabled network interface if supported by node type
    # Also attaches security groups
    #
    # TODO: refactor Groups
    def __netInterface(self):

        interface = {
            'AssociatePublicIpAddress': True,
            'DeleteOnTermination': True,
            'Description': 'Network adaptor via boto3 api',
            'DeviceIndex': 0,
            'Groups': self.sg_ids,
            'SubnetId': self.subnet_id
        }

        if self.nodeType == 'c5n.18xlarge':
            interface['InterfaceType'] = 'efa'

        return interface

    ########################################################################


if __name__ == '__main__':
    pass
