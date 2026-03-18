"""
Various cluster related functions wrapped as Prefect Tasks
"""

# Python dependencies
import glob
import logging
import os
import sys
import time
import socket
import traceback
import subprocess
import pprint
from distributed import Client
from prefect import task
from prefect.cache_policies import NO_CACHE

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

from cloudflow.cluster.Cluster import Cluster
from cloudflow.cluster.ClusterFactory import ClusterFactory

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


curdir = os.path.dirname(os.path.abspath(__file__))

pp = pprint.PrettyPrinter()

log = logging.getLogger('workflow')

#######################################################################


# cluster
@task
def cluster_init(config) -> Cluster:
    """ Create a new Cluster object using the ClusterFactory

    Parameters
    ----------
    config : string

    Returns
    -------
    newcluster : Cluster
        Object returned will be a sub-class of Cluster
    """
    factory = ClusterFactory()
    newcluster = factory.cluster(config)

    return newcluster

#######################################################################


# cluster
@task
def cluster_start(cluster):
    """ Start the cluster

    Parameters
    ----------
    cluster : Cluster

    """
    log.info('Starting ' + str(cluster.nodeCount) + ' instances ...')
    log.info('Waiting for nodes to start ...')
    try:
        cluster.start()
    except Exception as e:
        log.exception('In driver: Exception while creating nodes :' + str(e))
        raise Exception()
    return


#######################################################################


# cluster
@task
def cluster_terminate(cluster):
    """ Terminate the cluster

    Parameters
    ----------
    cluster : Cluster
    """

    responses = cluster.terminate()
    # Just check the state
    log.info('Responses from terminate: ')
    for response in responses:
        pp.pprint(response)

    return


#######################################################################


# cluster
@task
def push_pyEnv(cluster):
    """ Push any local python packages to the newly started cluster and pip3 install them. This is needed when local changes to the plotting
    routines exist. The cluster may not have the updated version.

    Parameters
    ----------
    cluster : Cluster

    Notes
    -----
    Use python3 setup.py sdist to create the distributable source package to upload.

    """

    hosts = cluster.getHosts()

    for host in hosts:

        log.info(f"push_pyEnv host is {host}")

        # Push and install anything in dist folder
        dists = glob.glob(f'{curdir}/../dist/*.tar.gz')
        for dist in dists:
            log.info(f"pushing python dist: {dist}")
            subprocess.run(["scp", dist, f"{host}:~"], stderr=subprocess.STDOUT)

            path, lib = os.path.split(dist)
            log.info(f"push_pyEnv installing module: {lib}")

            subprocess.run(["ssh", host, "pip3", "install", "--upgrade", "--user", lib], stderr=subprocess.STDOUT)
    return


#####################################################################

# Grab the head node ip for the dask scheduler address
def get_head_node_ip():
    """Returns the IP address of the current head node."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

# Check to see if dask port is already in use
def is_port_in_use(port):
    """
    Checks if a port is actually available for binding.

    This is more robust than connect_ex because it detects
    ports in TIME_WAIT or ports held by zombie processes.
    """
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            # We want to know if the OS is truly 
            # done with the port from the last job.
            s.bind(('0.0.0.0', port))
            return False  # Bind succeeded: Port is free
        except OSError:
            return True   # Bind failed: Port is busy

# Find the available dask port on the head node
def find_available_port(start_port=8786, end_port=8796):
    """
    Iterates through the allowed head node range to find a bindable port.
    """
    for port in range(start_port, end_port + 1):
        if not is_port_in_use(port):
            log.info(f"Found available Dask port: {port}")
            return port

    # If we hit the end of the loop, no ports were found
    raise OSError(f"No free ports available in range {start_port}-{end_port}. "
                  "Check for zombie scheduler processes.")

# ssh check for ec2 instances to ensure port 22
# connectivity with the head node for dask scheduler connection
def wait_for_ssh(host, port=22, timeout=300):
    """ Wait for the port to be open and routable """
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            with socket.create_connection((host, port), timeout=5):
                return True
        except (socket.timeout, ConnectionRefusedError, OSError):
            time.sleep(5)
    return False

# Main start dask function
@task
def start_dask(cluster) -> tuple:
    """
    Initializes a Dask Scheduler on the Head Node and deploys workers to 
    remote EC2 instances via SSH.

    Parameters
    ----------
    cluster : Cluster
        An object containing cluster metadata, including:
        - getHostsCSV(): returns comma-separated worker IPs
        - PPN: Processes Per Node (int)
        - nodes: list of node dictionaries
    Returns
    -------
    tuple (cluster, str)
        - cluster: The updated cluster object with process handles attached.
        - address: The 'tcp://IP:PORT' string for the Dask Scheduler.

    Raises
    ------
    RuntimeError
        If the scheduler fails to start or workers fail to register within the timeout.
    """

    # Get AWS Worker IPs from the CSV
    hosts_csv = cluster.getHostsCSV()
    worker_hosts = [h.strip() for h in hosts_csv.split(",") if h.strip()]

    # Identify the Head Node (current machine)
    head_ip = get_head_node_ip()

    # Find available port to use on head node
    # starting from default dask port 8786 until
    # port 8796 (NOS Sandbox specifications)
    # so multiple users can start their own dask schedulers 
    port = find_available_port(8786, 8796)

    # Create dask scheduler address to start 
    # the dask client
    address = f"{head_ip}:{port}"

    # Check dask workers ssh connectivity
    # to ensure they have port 22 access to communicate
    # back to the dask scheduler on the head node
    log.info(f"Checking SSH route to workers: {worker_hosts}")
    for host in worker_hosts:
        if not wait_for_ssh(host, timeout=60): # Reduced timeout for efficiency
             raise RuntimeError(f"Network path to {host} is blocked.")

    log.info(f"Starting Scheduler on Head Node: {address}")

    # Capture the path to the Python binary on the EFS mount
    # that is currently being used to run cloudflow
    current_python = sys.executable
    bin_dir = os.path.dirname(current_python)

    # Define explicit paths to dask binaries in the same
    # Python bin folder currently being used to run cloudflow
    dask_bin = os.path.join(bin_dir, "dask")
    remote_worker_bin = os.path.join(bin_dir, "dask-worker")

    # Start Dask Scheduler locally on the Head Node
    # using specified dask port available for user
    sched_proc = subprocess.Popen(
        [dask_bin, "scheduler", "--host", head_ip, "--port", str(port),"--dashboard-address", "0"],
        stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)

    # Assign dask scheduler process to cluster object
    # to eventually close once job is finished
    cluster.daskscheduler = sched_proc


    # Verify Scheduler is actually running
    # and listening for connections
    time.sleep(3)
    if sched_proc.poll() is not None:
        stderr = sched_proc.stderr.read()
        raise RuntimeError(f"Scheduler died immediately: {stderr}")

    # Initalize dask workers list attribute
    # for cluster object to keep track of
    # dask ssh processes that we will
    # eventually closed once job is finished
    cluster.worker_procs = []

    # Deploy dask workers via SSH
    # ec2-user protocol and assign
    # their process to the dask workers
    # list within the cluster object
    if worker_hosts:
        for host in worker_hosts:
            ssh_cmd = [
                "ssh", "-o", "StrictHostKeyChecking=no",
                f"ec2-user@{host}",
                f"{remote_worker_bin} {head_ip}:{port} " # Phone home between dask worker and scheduler
                f"--nworkers {cluster.PPN} " # Assign number of dask workers based on EC2 instance cores
                f"--nthreads 1 " # Assign single threading for each dask worker
                f"--death-timeout 120 " # Timeout span if ssh protocol fails to complete in allocated time
                f"--name worker-{host}" # Naming of ssh process
            ]

            wp = subprocess.Popen(ssh_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            cluster.worker_procs.append(wp)

            log.info(f"Deployed dask of workers to {host}...")
            time.sleep(10) # 10 second gap between batches

    # Connectivity verification between the dask
    # scheduler and dask workers to ensure all
    # allocated workers can communicate with the client
    log.info("Verifying cluster connectivity...")
    timeout = 250
    start_time = time.time()
    expected_total = len(worker_hosts) * cluster.PPN

    try:
        # Open dask client to verify that it can listen to all dask
        # workers allocated for job, if not then throw exception and
        # terminate for user to further debug
        with Client(address, timeout="60s") as client:
            # client call to wait for all dask workers until allocated timeout span
            client.wait_for_workers(n_workers=expected_total, timeout=timeout)

            # Log to user the number of dask workers registered to the client
            actual_workers = len(client.scheduler_info(n_workers=-1)['workers'])
            log.info(f"SUCCESS: {actual_workers}/{expected_total} workers registered.")

        return cluster, address

    except Exception as e:
        log.error(f"Dask Startup Failed: {e}")
        # Call dask client close function to terminate
        # background processes of dask scheduler and ssh workers
        dask_client_close(cluster)
        raise RuntimeError(f"Cluster failed to reach {expected_total} workers: {e}")

#####################################################################


# Main function to close dask processes
@task(cache_policy=NO_CACHE)
def dask_client_close(cluster):
    """
    Gracefully shuts down the Dask cluster by terminating the local scheduler
    and all remote worker SSH tunnels.

    Parameters
    ----------
    cluster : Cluster
        The cluster object containing:
        - daskscheduler: The subprocess.Popen object for the local scheduler.
        - worker_procs: A list of subprocess.Popen objects for remote SSH workers.

    Returns
    -------
    cluster : Cluster
        The updated cluster object with process handles cleared (None/Empty).

    Notes
    -----
    This function sends a SIGTERM to the scheduler and worker processes.
    If they do not exit within the specified timeout, it escalates to a SIGKILL
    to ensure no 'zombie' processes remain on the Head Node.
    """

    # Terminate the local dask scheduler process
    sched_proc = cluster.daskscheduler
    if sched_proc:
        log.info("Terminating local Dask scheduler...")
        try:
            # Send SIGTERM to gracefully shutdown
            # dask scheduler on head node
            sched_proc.terminate()

            # Ensure dask scheduler is killed to avoid
            # zombie processes on head node
            try:
                sched_proc.wait(timeout=5)
                log.info("Dask scheduler terminated gracefully.")
            except subprocess.TimeoutExpired:
                log.warning("Scheduler didn't stop, forcing kill...")
                sched_proc.kill()

        except Exception as e:
            log.error(f"Error terminating scheduler: {e}")
    else:
        log.warning("No Dask scheduler process found in cluster object.")

    # Terminate all remote dask worker SSH processes
    if hasattr(cluster, 'worker_procs') and cluster.worker_procs:
        log.info(f"Terminating {len(cluster.worker_procs)} remote Dask worker SSH processes...")
        for proc in cluster.worker_procs:
            try:
                # Send SIGTERM to the local SSH process
                # in order to close the remote session
                proc.terminate()
            except Exception as e:
                log.error(f"Error terminating worker process: {e}")

        # Ensure ssh processes are killed to
        # avoid zombie processes on head node
        for proc in cluster.worker_procs:
            try:
                proc.wait(timeout=2)
            except subprocess.TimeoutExpired:
                proc.kill()

        log.info("Remote worker SSH processes signaled to stop.")

    # Cluster state update
    cluster.daskscheduler = None
    cluster.worker_procs = []

    return cluster
