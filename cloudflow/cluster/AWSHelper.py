import json
from typing import Any, Dict
import boto3
from botocore.exceptions import ClientError

""" Defines supported types of instances and the number of cores of each. Currently only certain AWS EC2 types are
    supported.
"""
__copyright__ = "Copyright © 2025 RPS Group. All rights reserved."
__license__ = "BSD 3-Clause"

def getPPN(instance_type, awsTypes: dict ):
    """ Get the number of processors per node for the given instance type.

    Parameters
    ----------
    instance_type : string
    awsTypes : dict - a dictionary of supported types and number of cores

    Returns
    -------
    ppn : int

    Raises
    ------
    Exception if instance_type is not found
    """

    try:
        ppn = awsTypes[instance_type]
    except Exception as e:
        msg = instance_type + ' is not supported'
        raise Exception(msg) from e

    return ppn


def supportsThreadsPerCoreOption(instance_type: str, region: str) -> bool:
    """
    When launching instances, you can override the default vCPU options via the CpuOptions
    parameter. Only instance types that support custom vCPU options will include the
    threads per core option.

    Parameters:
        instance_type (str): The EC2 instance type (e.g., 'c5n.18xlarge').
        region (str): The current AWS region 

    Returns:
        bool: True if the instance type supports custom ThreadsPerCore settings; False otherwise.
    """
    ec2_client = boto3.client('ec2', region)
    
    try:
        response: Dict[str, Any] = ec2_client.describe_instance_types(InstanceTypes=[instance_type])

        # There should be exactly one item in the InstanceTypes list.
        instance_info = response['InstanceTypes'][0]

        #print("instance_info:")
        #print(json.dumps(instance_info, indent=4))

        # Check if the instance type supports CPU customization.
        vcpu_info = instance_info.get('VCpuInfo')
        if not vcpu_info:
            return False

        # "ValidThreadsPerCore"
        validTPC = vcpu_info.get('ValidThreadsPerCore')
        #print(f"validTPC: {json.dumps(validTPC, indent=4)}")
        if not validTPC:
            return False

        return True

    except ClientError as e:
        # Optionally, log or handle the error as needed.
        print(f"Error retrieving details for instance type '{instance_type}': {e}")
        return False



# Done programmatically now
def supportsEFA(instance_type : str, region: str) -> bool:
    """
    Check if the specified EC2 instance type supports Elastic Fabric Adapter (EFA).

    Parameters:
        instance_type (str): The instance type to check (e.g., 'c5n.18xlarge').
        region (str): The current AWS region

    Returns:
        bool: True if EFA is supported; False otherwise.
    """
    ec2_client = boto3.client('ec2', region)

    try:
        response: Dict[str, Any] = ec2_client.describe_instance_types(InstanceTypes=[instance_type])
        
        # Get the first (and only) instance type details
        instance_details = response['InstanceTypes'][0]

        return instance_details.get('NetworkInfo', {}).get('EfaSupported', False)

    except ClientError as e:
        print(f"Error retrieving details for instance type {instance_type}: {e}")
        return False



def maxNetworkCards(instance_type: str, region: str) -> int:
    """
    Retrieve the maximum number of network cards for the specified EC2 instance type.

    Parameters:
        instance_type (str): The EC2 instance type (e.g., 'c5n.18xlarge').
        region (str): 

    Returns:
        int: The maximum number of network cards available for the instance type.
             Returns 0 if the instance type is not found or an error occurs.
    """
    ec2_client = boto3.client('ec2', region)
    
    try:
        response: Dict[str, Any] = ec2_client.describe_instance_types(InstanceTypes=[instance_type])
        # There should be exactly one item in the InstanceTypes list.
        instance_info = response['InstanceTypes'][0]
        
        # Retrieve the MaximumNetworkCards value from the NetworkInfo block.
        network_info = instance_info.get("NetworkInfo", {})
        max_network_cards = network_info.get("MaximumNetworkCards", 0)
        return max_network_cards

    except ClientError as e:
        print(f"Error retrieving details for instance type '{instance_type}': {e}")
        return 0


# Example usage:
if __name__ == "__main__":
   
    region = "us-east-2"
    testTypes = [ 'hpc6a.48xlarge', 'c5n.18xlarge', 'c5a.16xlarge', 'hpc7a.96xlarge' ]

    for instance_type in testTypes:

        if supportsEFA(instance_type, region):
            print(f"{instance_type} supports EFA.")
        else:
            print(f"{instance_type} does not support EFA.")

        if supportsThreadsPerCoreOption(instance_type, region):
            print(f"{instance_type} supports customizing ThreadsPerCore via CpuOptions.")
        else:
            print(f"{instance_type} does NOT support customizing ThreadsPerCore via CpuOptions.")

        print(f"{instance_type} max_network_cards: {maxNetworkCards(instance_type, region)}")
        print("")

# CLI Options
# network-info.efa-info.maximum-efa-interfaces - The maximum number of Elastic Fabric Adapters (EFAs) per instance.
# network-info.efa-supported - Indicates whether the instance type supports Elastic Fabric Adapter (EFA) (true | false).
# network-info.ena-support - Indicates whether Elastic Network Adapter (ENA) is supported or required (required | supported | unsupported).
# network-info.maximum-network-cards - The maximum number of network cards per instance.
# vcpu-info.default-cores - The default number of cores for the instance type.
# vcpu-info.default-threads-per-core - The default number of threads per core for the instance type.
# vcpu-info.default-vcpus - The default number of vCPUs for the instance type.
# vcpu-info.valid-cores - The number of cores that can be configured for the instance type.
# vcpu-info.valid-threads-per-core - The number of threads per core that can be configured for the instance type. For example, "1" or "1,2".
