""" Defines supported types of instances and the number of cores of each. Currently only certain AWS EC2 types are
    supported.
"""
__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"



def getPPN(instance_type):
    """ Get the number of processors per node for the given instance type.

    Parameters
    ----------
    instance_type : string

    Returns
    -------
    ppn : int

    Raises
    ------
    Exception if instance_type is not found
    """

    awsTypes = {'c5.large': 1, 'c5.xlarge': 2, 'c5.2xlarge': 4, 'c5.4xlarge': 8, 'c5.9xlarge': 18, 'c5.18xlarge': 36, 'c5.24xlarge': 48, 'c5.metal': 36,
                'c5n.large': 1, 'c5n.xlarge': 2, 'c5n.2xlarge': 4, 'c5n.4xlarge': 8, 'c5n.9xlarge': 18, 'c5n.18xlarge': 36, 'c5n.24xlarge': 48, 'c5n.metal': 36,
                't3.large': 1, 't3.xlarge': 2, 't3.2xlarge': 4}

    try:
        ppn = awsTypes[instance_type]
    except Exception as e:
        msg = instance_type + ' is not supported in nodeInfo.py'
        raise Exception(msg) from e

    return ppn


if __name__ == '__main__':
    pass
