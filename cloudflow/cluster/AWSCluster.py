"""
Cluster implementation for AWS EC2 clusters.
"""

import time
import json
import logging
import math
import inspect

from pathlib import Path

import boto3
from botocore.exceptions import ClientError

from haikunator import Haikunator

# from cloudflow.cluster import AWSHelper
from cloudflow.cluster import AWSHelper
from cloudflow.cluster.Cluster import Cluster

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"

debug = False

log = logging.getLogger('workflow')

homedir = Path.home()
timelog = logging.getLogger('qops_timing')
timelog.setLevel(logging.INFO)
timelog.propagate = False

fh = logging.FileHandler(f"{homedir}/cluster_runtime.log")
formatter = logging.Formatter(' %(asctime)s  %(levelname)s | %(message)s')
fh.setFormatter(formatter)

# To avoid duplicate entries, only have one handler
if not timelog.hasHandlers():
    timelog.addHandler(fh)

#####  Includes recommended or tested types only  !!!!!!!
#      Should be number of physical CPU cores, not vCPUs,
#          Graviton and AMD CPUs do not support SMT (simultaneous multi-threading)
""" Defines supported types of instances and the number of cores of each. Currently only certain AWS EC2 types are
    supported.
"""
awsTypes = {
            'c5.large': 1,      'c5.xlarge': 2, 'c5.2xlarge': 4, 'c5.4xlarge': 8, 'c5.9xlarge': 18,
            'c5.12xlarge': 24,  'c5.18xlarge': 36, 'c5.24xlarge': 48, 'c5.metal': 36,

            'c5a.large': 1, 'c5a.xlarge': 2, 'c5a.2xlarge': 4, 'c5a.4xlarge': 8, 'c5a.24xlarge': 48,

            'c5n.large': 1,     'c5n.xlarge': 2, 'c5n.2xlarge': 4, 'c5n.4xlarge': 8, 'c5n.9xlarge': 18,
            'c5n.18xlarge': 36, 'c5n.24xlarge': 48, 'c5n.metal': 36,

            'c7i.48xlarge': 96,

            'hpc6a.48xlarge': 96,

            'hpc6id.32xlarge': 64,

            'hpc7a.48xlarge': 96,

            'hpc7a.96xlarge': 192,

            'r7iz.32xlarge': 64,

            # The below are in vCPUs not CPU cores
            'x2idn.24xlarge': 96, 'x2idn.32xlarge': 128 }


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

    vm_retry_delay : int
        The number of seconds that a user wants to wait to allow AWS resources to be freed up before attempting to grab ec2 resources

    vm_max_retries : int
        The number of retries a user wants to attempt on waiting for AWS resources to be available

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

        log.debug(f"In: {self.__class__.__name__} : {inspect.currentframe().f_code.co_name}")

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
        self.vm_retry_delay = 300
        self.vm_max_retries = 5
        self.tags = []
        self.image_id = ''
        self.key_name = ''
        self.sg_ids = []
        self.subnet_id = ''
        self.placement_group = ''

        cfDict = self.readConfig(configfile)
        self.parseConfig(cfDict)

        self.PPN = AWSHelper.getPPN(self.nodeType, awsTypes)
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

    def memorable_tags(self, tags : list):

        log.debug(f"In: {self.__class__.__name__} : {inspect.currentframe().f_code.co_name}")

        haikumaker = Haikunator()

        # Return a random two words, example: "shiny-wave"
        haiku = haikumaker.haikunate(token_length=0)
        suffix=f"-{haiku}"

        if not any(tag["Key"] == "Name" for tag in tags):
            raise ValueError("No 'Name' tag found")

        for tag in tags:
            if tag["Key"] == "Name":
                tag["Value"] = tag["Value"] + suffix
                print("\n***************************************************************")
                print(f"Your cluster name: {tag['Value']}")
                print("***************************************************************\n")
                log.info(f"Your cluster Name: {tag['Value']}")

        return tags


    ########################################################################
    """ Implemented abstract methods """
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

        log.debug(f"In: {self.__class__.__name__} : {inspect.currentframe().f_code.co_name}")

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

        log.debug(f"In: {self.__class__.__name__} : {inspect.currentframe().f_code.co_name}")

        self.platform = cfDict['platform']
        self.region = cfDict['region']
        self.nodeType = cfDict['nodeType']
        self.nodeCount = cfDict['nodeCount']

        try:
            self.vm_retry_delay = cfDict['vm_retry_delay']
        except KeyError:
            print(f'Cluster configuration variable vm_retyr_delay was not specified by user. Defaulting to value of {self.vm_retry_delay} seconds.')

        try:
            self.vm_max_retries = cfDict['vm_max_retries']
        except KeyError:
            print(f'Cluster configuration variable vm_max_retries was not specified by user. Defaulting to value of {self.vm_max_retries} number of retries.')


        # Hacky way to force unique Name tags
        print("running memorable_tags")
        self.tags = self.memorable_tags(cfDict['tags'])
        self.image_id = cfDict['image_id']
        self.key_name = cfDict['key_name']
        self.sg_ids = cfDict['sg_ids']
        self.subnet_id = cfDict['subnet_id']
        self.placement_group = cfDict['placement_group']

        self.tags.append({ "Key": "ApprovedSubnet", "Value": f"{self.subnet_id}" })
        print(f"self.tags: {self.tags}")
        return

    ########################################################################


    def getCoresPN(self):
        """ Get the number of cores per node in this cluster.

        Returns
        -------
        self.PPN : int
            the number of cores per node in this cluster. Assumes a heterogenous cluster. """

        return self.PPN


    # TODO: use gp3 volume instead of default gp2
    def start(self):
        """ Provision the configured cluster in the cloud.

        Returns
        -------
        self.__instances : list of EC2.Intance
            the list of Instances started. See boto3 documentation.
        """

        log.debug(f"In: {self.__class__.__name__} : {inspect.currentframe().f_code.co_name}")

        ec2 = boto3.resource('ec2', region_name=self.region)

        # Programmatically determine these options
        max_network_cards = AWSHelper.maxNetworkCards(self.nodeType, self.region)
        log.debug(f"max_network_cards: {max_network_cards}")

        smt_supported = AWSHelper.supportsThreadsPerCoreOption(self.nodeType, self.region)
        log.debug(f"smt_supported: {smt_supported}")
        # hpc6a and hpc7a and some others do not support the CpuOptions={ 'ThreadsPerCore': option }

        try:
          if self.nodeType in ['x2idn.24xlarge', 'x2idn.32xlarge']:
          # EFA supported:           NO                  YES
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
                NetworkInterfaces=self.__netInterfaces(count = 1)
              )

          elif not smt_supported: # Does NOT support CpuOptions ThreadsPerCore option
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
                NetworkInterfaces=self.__netInterfaces(count = max_network_cards)
              )

          else:  # supports the ThreadsPerCore option and setting it to 1
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
                NetworkInterfaces=self.__netInterfaces(count = max_network_cards),
                CpuOptions={
                    'CoreCount': self.PPN,
                    'ThreadsPerCore': 1
                }
              )
        except ClientError as e:
            if e.response['Error']['Code'] == 'InsufficientInstanceCapacity':

                 print(f"AWS Insufficent Instance Capacity has been detected, Will attempt to wait {self.vm_retry_delay} seconds at the start. A 10% exponential backoff on the delay time will be implemented over each retry interval. Cloudflow will retry {self.vm_max_retries} times over to see if we can obtain the user requested AWS resources.")
                 retries = 0

                 while retries < self.vm_max_retries:
                     try:
                         if self.nodeType in ['x2idn.24xlarge', 'x2idn.32xlarge']:
                             # EFA supported:           NO                  YES
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
                               NetworkInterfaces=self.__netInterfaces(count = 1)
                             )

                         elif not smt_supported: # Does NOT support CpuOptions ThreadsPerCore option
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
                               NetworkInterfaces=self.__netInterfaces(count = max_network_cards)
                             )

                         else:  # supports the ThreadsPerCore option and setting it to 1
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
                               NetworkInterfaces=self.__netInterfaces(count = max_network_cards),
                               CpuOptions={
                                   'CoreCount': self.PPN,
                                   'ThreadsPerCore': 1
                               }
                             )

                         
                         break  
                     except ClientError as e:
                         if e.response['Error']['Code'] == 'InsufficientInstanceCapacity':
                             retries += 1
                             if(retries == self.vm_max_retries):
                                 print(f"Insufficient capacity. Number of retries ({self.vm_max_retries}) has been reached. Cloudflow will now shutdown due to lack of AWS resources requested by user.")
                                 raise Exception() from e
                             else:
                                 # Implement an 10% exponential backoff of the time delay starting from the user specified endpoint
                                 if(retries>1):
                                     self.vm_retry_delay = int(self.vm_retry_delay * math.exp(0.10 * self.vm_max_retries))
                                     print(f"Insufficient capacity. Retrying in {self.vm_retry_delay} seconds... (Attempt {retries}/{self.vm_max_retries})")
                                     time.sleep(self.vm_retry_delay)
                                 else:
                                     print(f"Insufficient capacity. Retrying in {self.vm_retry_delay} seconds... (Attempt {retries}/{self.vm_max_retries})")
                                     time.sleep(self.vm_retry_delay)
                         else:
                             # Re-raise the exception if it's not a capacity issue
                             log.exception('ClientError exception in createCluster' + str(e))
                             raise Exception() from e
            else:
                log.exception('ClientError exception in createCluster' + str(e))
                raise Exception() from e


        print('AWS resources have been allocated for cloudflow job. Waiting for nodes to enter running state ...')
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

        # Wait a little more. sshd can be slow to start "Connection refused" error
        # "System is booting up. Unprivileged users are not permitted to log in yet. Please come back later.
        sleeptime=150
        log.info(f"Waiting an additional {sleeptime} seconds for nodes to fully initialize ...")
        time.sleep(sleeptime)

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
            self.terminate()
            raise Exception('Nodes did not start within time limit... terminating them...')

        self.__start_time = time.time()

        return self.__instances



    def terminate(self):
        """ Shutdown and remove the EC2 Instances in this cluster.
            Also terminates any associated Dask Worker and Scheduler processes.

        Returns
        -------
        responses : list of dict
            a list of the responses from EC2.Instance.terminate(). See boto3 documentation.
        """

        log.debug(f"In: {self.__class__.__name__} : {inspect.currentframe().f_code.co_name}")

        self.terminateDaskWorker()

        # Terminate any running dask scheduler
        self.terminateDaskScheduler()

        log.info(f"Terminating instances: {self.__instances}")


        responses = []

        try:
            ec2 = boto3.resource('ec2', region_name=self.region)

            for instance in self.__instances:
                response = instance.terminate()['TerminatingInstances']
                responses.append(response)

            end_time = time.time()
            elapsed = end_time - self.__start_time
            mins = math.ceil(elapsed / 60.0)
            hrs = mins / 60.0
            nodetype = self.nodeType
            nodecnt = self.nodeCount

            nametag = next((item["Value"] for item in self.tags if item["Key"] == "Name"), "No nametag")
            print(f"timelog: {nametag}: {mins} minutes - {nodecnt} x {nodetype}")
            timelog.info(f"{nametag}: {mins} minutes - {nodecnt} x {nodetype}")

        except Exception as e:
            log.exception('ERROR!!!!!!  Exception while trying to terminate compute nodes!!!!\n \
                           MANUALLY VERIFY INSTANCES ARE TERMINATED !!!!!!!!!!!!!!!!!!!!!!!!' + str(e))
            raise Exception() from e

        return responses


    def getHosts(self):
        """ Get the list of hosts in this cluster

        Returns
        -------
        hosts : list of str
            list of private dns names
        """
        hosts = []
        log.debug(f"In: {self.__class__.__name__} : {inspect.currentframe().f_code.co_name}")

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
        """ most current generation instance types support placement groups now """

        group = {'GroupName': self.placement_group}

        return group



    def __netInterfaces(self, count=1):
        """ Specify an efa enabled network interface if supported by node type.
            Also attaches security groups """

        # Some newer types require 2 network devices for EFA 
        if count > 2 or count == 0:
            raise Exception(f"__netInterfaces: not expecting {count} network cards")

        efa_supported = AWSHelper.supportsEFA(self.nodeType, self.region)

        interfaces = []

        for idx in range(count):
        
            interface = {
              'AssociatePublicIpAddress': False,
              'DeleteOnTermination': True,
              'Description': 'Sandbox node network adaptor via cloudflow boto3 api',
              'DeviceIndex': idx,
              'NetworkCardIndex': idx,
              'Groups': self.sg_ids,
              'SubnetId': self.subnet_id
            }

            # otherwise will use default
            if efa_supported:
                interface['InterfaceType'] = 'efa'

            interfaces.append(interface)

        log.debug(f"net.interfaces: {json.dumps(interfaces, indent=4)}")

        return interfaces

    ########################################################################


if __name__ == '__main__':
    pass
