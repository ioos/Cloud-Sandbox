""" Defines supported types of instances and the number of cores of each. Currently only certain AWS EC2 types are
    supported.
"""
__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"



awsTypes = {'c5.large': 1, 'c5.xlarge': 2, 'c5.2xlarge': 4, 'c5.4xlarge': 8, 'c5.9xlarge': 18, 'c5.12xlarge': 24,
            'c5.18xlarge': 36, 'c5.24xlarge': 48, 'c5.metal': 36,
            'c5n.large': 1, 'c5n.xlarge': 2, 'c5n.2xlarge': 4, 'c5n.4xlarge': 8, 'c5n.9xlarge': 18,
            'c5n.18xlarge': 36, 'c5n.24xlarge': 48, 'c5n.metal': 36,
            't3.large': 1, 't3.xlarge': 2, 't3.2xlarge': 4,
            'c5a.2xlarge': 4, 'c5a.4xlarge': 8, 'c5a.24xlarge': 48,
            'hpc6a.48xlarge': 96, 'hpc7a.96xlarge': 192, 'hpc7a.48xlarge': 96, 'c7i.48xlarge': 96, 'r7iz.32xlarge': 64 }

efaTypes = ['c5n.18xlarge', 'hpc6a.48xlarge', 'hpc7a.96xlarge', 'hpc7a.48xlarge']


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

    # awsTypes = {'c5.large': 1, 'c5.xlarge': 2, 'c5.2xlarge': 4, 'c5.4xlarge': 8, 'c5.9xlarge': 18, 'c5.12xlarge': 24,
    #             'c5.18xlarge': 36, 'c5.24xlarge': 48, 'c5.metal': 36, 
    #             'c5n.large': 1, 'c5n.xlarge': 2, 'c5n.2xlarge': 4, 'c5n.4xlarge': 8, 'c5n.9xlarge': 18, 
    #             'c5n.18xlarge': 36, 'c5n.24xlarge': 48, 'c5n.metal': 36,
    #             't3.large': 1, 't3.xlarge': 2, 't3.2xlarge': 4, 
    #             'c5a.2xlarge': 4, 'c5a.4xlarge': 8, 'c5a.24xlarge': 48,
    #             'hpc6a.48xlarge': 96 }

    # efaTypes = ['c5n.18xlarge', 'hpc6a.48xlarge']

    try:
        ppn = awsTypes[instance_type]
    except Exception as e:
        msg = instance_type + ' is not supported in nodeInfo.py'
        raise Exception(msg) from e

    return ppn


if __name__ == '__main__':
    pass
