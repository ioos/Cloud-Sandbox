# Cloudflow Python Execution Instructions

A guide for staging, configuring, and executing Python workflows (Serial/Basic, MPI-enabled, and Dask-scalable) on an `ioos/Cloud-Sandbox` head node using Cloudflow and Prefect.

---

## 1. Prerequisites & Environment Setup

Stage your Python scripts to S3 and set up your workspace on the shared EFS volume (`/save`) before executing Python jobs on the head node.

### Stage Python Scripts to S3
From your local machine:
```bash
aws s3 cp /pathway/to/your/Python/script.py s3://ioos-transfers/script.py --recursive
```

### Workspace Preparation
On the Cloud-Sandbox head node:
```bash
cd /save
mkdir -p jason.ducker && cd jason.ducker

# Pull staged scripts from S3
aws s3 cp s3://ioos-transfers/script.py ./script.py --recursive

# Clone the repository
git clone [https://github.com/ioos/Cloud-Sandbox.git](https://github.com/ioos/Cloud-Sandbox.git)
cd Cloud-Sandbox/cloudflow/
```

> **Note:** If you do not have a compatible Python environment installed, follow the **Python Miniforge3 Installation** guide on the main [Cloud-Sandbox Repository](https://github.com/ioos/Cloud-Sandbox.git).

---

## 2. Prefect Workflow Server Setup

All Cloudflow execution modes require an active local Prefect server. **Python Miniforge3 Installation** will install the proper `cloudflow` environment to start a Prefect server if one is already not available. 

```bash
# Check if Prefect server is available
if curl -s --connect-timeout 2 [http://127.0.0.1:4200/api/health](http://127.0.0.1:4200/api/health) > /dev/null; then
    echo "Prefect server is RUNNING and available."
else
    echo "No active Prefect server detected."
fi
```

If no server is detected, start and configure it:
```bash
/save/jason.ducker/miniforge3/envs/cloudflow/bin/prefect server start --background
/save/jason.ducker/miniforge3/envs/cloudflow/bin/prefect config set PREFECT_API_URL=[http://127.0.0.1:4200/api](http://127.0.0.1:4200/api)
```

---

## 3. Python Execution Modes

Cloudflow supports three primary Python execution modes on Cloud-Sandbox:

* **[Serial / Basic Mode](https://github.com/jduckerOWP/Cloud-Sandbox_OWP/blob/main/cloudflow/CLOUDFLOW_PYTHON_MODEL_EXECUTION_INSTRUCTIONS.md#mode-a-basic-python-execution-serial--concurrent)**: Single-node serial script execution or node-level concurrency.
* **[MPI-Enabled Mode (`mpi4py`)](https://github.com/jduckerOWP/Cloud-Sandbox_OWP/blob/main/cloudflow/CLOUDFLOW_PYTHON_MODEL_EXECUTION_INSTRUCTIONS.md#mode-b-mpi-enabled-python-execution-mpi4py)**: Multi-node distributed memory execution using `mpiexec`.
* **[Dask Distributed Mode](https://github.com/jduckerOWP/Cloud-Sandbox_OWP/blob/main/cloudflow/CLOUDFLOW_PYTHON_MODEL_EXECUTION_INSTRUCTIONS.md#mode-c-dask-distributed-execution)**: Dynamic task/data parallelism across scalable worker clusters.
  * **[Method 1: Dask Data Parallelism (`client.map`)](https://github.com/jduckerOWP/Cloud-Sandbox_OWP/blob/main/cloudflow/CLOUDFLOW_PYTHON_MODEL_EXECUTION_INSTRUCTIONS.md#method-1-data-parallelism-clientmap)**: Applying a function across iterable datasets across workers.
  * **[Method 2: Dask Task Parallelism (`client.submit`)](https://github.com/jduckerOWP/Cloud-Sandbox_OWP/blob/main/cloudflow/CLOUDFLOW_PYTHON_MODEL_EXECUTION_INSTRUCTIONS.md#method-2-task-parallelism-clientsubmit)**: Submitting dedicated computations directly to the cluster.

---

### Mode A: Basic Python Execution (Serial / Concurrent)

Single-node execution utilizing one EC2 instance for serial execution or node-level concurrency (e.g., `multiprocessing`).

#### Step 1: Bind Python Cloudflow Executable
```bash
sed -i 's|#!/usr/bin/env -S python3 -u|#!/usr/bin/env /save/jason.ducker/miniforge3/envs/cloudflow/bin/python|' workflows/workflow_main.py
```

#### Step 2: Configure Job Specification
Edit `../job.configs/MODEL_EXPERIMENTS/python.experiment`:
```json
{
  "MODEL"   : "PYTHON",
  "JOBTYPE" : "python_experiment",
  "APP"     : "basic",
  "EXEC"    : "/save/jason.ducker/miniforge3/envs/special_env/bin/python",
  "SCRIPT"  : "./workflows/python_examples.py"
}
```
* **`MODEL`**: The Cloud-Sandbox model class (`PYTHON`).
* **`JOBTYPE`**: Job category for the model class (`python_experiment`).
* **`APP`**: Application execution mode (`basic` for a single-node Python run).
* **`EXEC`**: Absolute pathway to the specific Python executable containing required script dependencies. This can be a separate environment from the Cloudflow launch environment[cite: 4].
* **`SCRIPT`**: Path to your target Python script harbored on the head node's EFS volume.

> **Note:** If you would like to add dynamic arguments to utilize for your Python script, then please refer to [Section 4: Integrating Custom Arguments into Cloudflow](https://github.com/jduckerOWP/Cloud-Sandbox_OWP/blob/main/cloudflow/CLOUDFLOW_PYTHON_MODEL_EXECUTION_INSTRUCTIONS.md#4-integrating-custom-arguments-into-cloudflow) for instructions on integrating those arguments within cloudflow.

#### Step 3: Configure Cluster Infrastructure
Edit `../cluster.configs/Experiments/python.ioos` (**Note:** `nodeCount` must strictly be `1` for Basic mode):
```json
{
  "platform"        : "AWS",
  "region"          : "us-east-2",
  "nodeType"        : "c5.4xlarge",
  "nodeCount"       : 1,
  "vm_retry_delay"  : 300,
  "vm_max_retries"  : 5,
  "tags"            : [
                        { "Key": "Name", "Value": "Python" },
                        { "Key": "Project", "Value": "Model_Experiment" }
                      ],
  "image_id"        : "ami-0cbf4e2a2768a602b",
  "key_name"        : "rsa_sandbox_key",
  "sg_ids"          : ["sg-05c044182398b2a27", "sg-0e5148638d9196f69", "sg-06ca6bc5d4b377dad"],
  "subnet_id"       : "subnet-00075cfbfcbc8f2cf",
  "placement_group" : "ioos_cloud_sandbox_Terraform_Placement_Group",
  "table_name"      : "IOOS-Sandbox-Compute-Nodes"
}
```
* **`platform`**: Target cloud provider (`AWS`).
* **`region`**: AWS region hosting Sandbox resources (`us-east-2`).
* **`nodeType`**: Requested AWS EC2 instance type (e.g., `c5.4xlarge`).
* **`nodeCount`**: Number of EC2 compute nodes allocated (**Note:** Basic mode allows strictly `1` node).
* **`vm_retry_delay`**: Delay in seconds between resource allocation queries (`300`).
* **`vm_max_retries`**: Maximum query retries for AWS resource requests (`5`).
* **`tags`**: Resource tags assigned for Prefect job ID tracking.
* **`image_id`**: AMI ID matching the head node and mounted EFS volume (`ami-0cbf4e2a2768a602b`).
* **`key_name`**: SSH key pair name configured for the AWS account (`rsa_sandbox_key`).
* **`sg_ids`**: Security group IDs for network traffic control.
* **`subnet_id`**: AWS account subnet identifier.
* **`placement_group`**: Target data center placement group.
* **`table_name`**: AWS DynamoDB table tracking job specifications (`IOOS-Sandbox-Compute-Nodes`).

---

> **Important:** Ensure `image_id` matches the exact AMI associated with your running head node so compute nodes mount identical environments. If you're still having issues launching the job, you may need to include an extra security group id for the EFS volume mounted on the head node your'e on. Besides that, you only need to worry about changing `nodeType`, `nodeCount`, and `tags` if desired. 

---
#### Step 4: Submit and Monitor Job
```bash
nohup ./workflows/workflow_main.py ../cluster.configs/Experiments/python.ioos ../job.configs/MODEL_EXPERIMENTS/python.experiment > cloudflow_test.out &
tail -f cloudflow_test.out
```

#### Step 5: Execution Lifecycle Overview
When launched, the Cloudflow pipeline executes the following stages automatically:

1. **Resource Allocation:** Generates a dynamic cluster name (e.g., `PYTHON-ordinary-foxhound`), queries AWS for requested EC2 compute instances, logs telemetry to DynamoDB, and calculates initial cost projections.

```bash
jobtype: python_experiment
13:56:30.743 | INFO    | Flow run 'ordinary-foxhound' - Beginning flow run 'ordinary-foxhound' for flow 'experiment-flow'
13:56:30.752 | INFO    | Flow run 'ordinary-foxhound' - View at http://127.0.0.1:4200/runs/flow-run/7a279cf1-e479-4908-8e10-77f695c04102
 2026-08-25 13:56:30,775  INFO - ClusterFactory.cluster | Attempting to make a new cluster : AWS
13:56:30.775 | INFO    | workflow - Attempting to make a new cluster : AWS

***************************************************************
Your cluster name: PYTHON-ordinary-foxhound
***************************************************************

 2026-08-25 13:56:30,776  INFO - AWSCluster.memorable_tags | Your cluster Name: PYTHON-ordinary-foxhound
13:56:30.776 | INFO    | workflow - Your cluster Name: PYTHON-ordinary-foxhound
self.tags: [{'Key': 'Name', 'Value': 'PYTHON-ordinary-foxhound'}, {'Key': 'Project', 'Value': 'Basic_Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}]
 2026-08-25 13:56:32,226  INFO - AWSCluster.__init__ | nodeCount: 1  PPN: 8
13:56:32.226 | INFO    | workflow - nodeCount: 1  PPN: 8
 2026-08-25 13:56:32,226  INFO - ClusterFactory.cluster | Created new AWS cluster
13:56:32.226 | INFO    | workflow - Created new AWS cluster
13:56:32.227 | INFO    | Task run 'cluster_init-13a' - Finished in state Completed()
in job init
<cloudflow.job.PYTHON_Experiment.PYTHON_Experiment object at 0x14787826d7f0>
13:56:32.235 | INFO    | Task run 'job_init-36d' - Finished in state Completed()
 2026-08-25 13:56:32,237  INFO - cluster_tasks.cluster_start | Starting 1 instances ...
13:56:32.237 | INFO    | workflow - Starting 1 instances ...
 2026-08-25 13:56:32,238  INFO - cluster_tasks.cluster_start | Waiting for nodes to start ...
13:56:32.238 | INFO    | workflow - Waiting for nodes to start ...

===============================================================
  ESTIMATED CLUSTER COST  (on-demand, Linux, no pre-installed SW)
===============================================================
  Instance type : c5.4xlarge
  Region        : us-east-2  (US East (Ohio))
  Node count    : 1
  Per-node rate : $0.6800 / hr
  Cluster cost  : $0.6800 / hr  |  $16.32 / day
  NOTE: Estimate is for on-demand pricing only.
        Actual charges depend on run time and AWS billing.
===============================================================

 2026-08-25 13:56:32,401  INFO - AWSCluster._estimate_and_print_cost | Cost estimate – 1x c5.4xlarge @ us-east-2: $0.6800/hr  |  $16.32/day
13:56:32.401 | INFO    | workflow - Cost estimate – 1x c5.4xlarge @ us-east-2: $0.6800/hr  |  $16.32/day

```

2. **Node Initialization:** Waits for requested instances to enter a running state and initializes environment mounts.
```bash
 2026-08-25 13:56:34,610  INFO - AWSCluster.start | AWS resources have been allocated for cloudflow job. Waiting for nodes to enter running state ...
13:56:34.610 | INFO    | workflow - AWS resources have been allocated for cloudflow job. Waiting for nodes to enter running state ...
 2026-08-25 13:56:34,627  INFO - AWSCluster.__put_instance_records | DB_table output for head node based on instance id i-0e61b9c06fb1304cc: {'instance-id': 'i-0e61b9c06fb1304cc', 'name-tag': 'PYTHON-ordinary-foxhound', 'instance-type': 'c5.4xlarge', 'start-time': 1787666194, 'human-time': '2026-08-25 13:56 UTC', 'minutes-max': 120, 'username': 'jason_ducker'}
13:56:34.627 | INFO    | workflow - DB_table output for head node based on instance id i-0e61b9c06fb1304cc: {'instance-id': 'i-0e61b9c06fb1304cc', 'name-tag': 'PYTHON-ordinary-foxhound', 'instance-type': 'c5.4xlarge', 'start-time': 1787666194, 'human-time': '2026-08-25 13:56 UTC', 'minutes-max': 120, 'username': 'jason_ducker'}
 2026-08-25 13:56:45,432  INFO - AWSCluster.start | Waiting an additional 150 seconds for nodes to fully initialize ...
13:56:45.432 | INFO    | workflow - Waiting an additional 150 seconds for nodes to fully initialize ...
```

3. **Model Execution:** Enters the target directory (`MODEL_DIR`), checks the Python script for syntax errors before ssh into EC2 instance, then ssh into EC2 instance and executes the specified Python executable and script within the job configuration file. 
```bash
instance 1 : running
{"instance_id": "i-0e61b9c06fb1304cc", "instance_type": "c5.4xlarge", "state": "pending", "host": "10.26.37.132", "tags": [{"Key": "Name", "Value": "PYTHON-ordinary-foxhound"}, {"Key": "Project", "Value": "Basic_Model_Experiment"}, {"Key": "ApprovedSubnet", "Value": "subnet-00075cfbfcbc8f2cf"}], "user": "jason_ducker", "start_time": 1787666355.8087168}
13:59:15.812 | INFO    | Task run 'cluster_start-a51' - Finished in state Completed()
runscript: /mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox/cloudflow/workflows/experiment_launcher.sh
**********************************************************
Current directory is /save/jason.ducker/Cloud-Sandbox/cloudflow
```


4. **Deprovisioning & Reporting:** Automatically terminates instantiated compute instance upon run completion or failure, releasing resources and reporting actual compute wall-time and final estimated AWS cost.
```bash
+ '[' 0 -ne 0 ']'
+ echo 'Python script execution has succesfully completed on the cloud!'
Python script execution has succesfully completed on the cloud!
+ duration=6
+ echo 'Python script execution took 0 minutes and 6 seconds elapsed.'
Python script execution took 0 minutes and 6 seconds elapsed.
 2026-08-25 13:59:21,597  INFO - tasks.experiment_run | PYTHON use case script execution finished successfully
13:59:21.597 | INFO    | workflow - PYTHON use case script execution finished successfully
13:59:21.599 | INFO    | Task run 'experiment_run-238' - Finished in state Completed()
 2026-08-25 13:59:21,602  INFO - AWSCluster.terminate | Terminating instances: [{'instance_id': 'i-0e61b9c06fb1304cc', 'instance_type': 'c5.4xlarge', 'state': 'pending', 'host': '10.26.37.132', 'tags': [{'Key': 'Name', 'Value': 'PYTHON-ordinary-foxhound'}, {'Key': 'Project', 'Value': 'Basic_Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}], 'user': 'jason_ducker', 'start_time': 1787666355.8087168}]
13:59:21.602 | INFO    | workflow - Terminating instances: [{'instance_id': 'i-0e61b9c06fb1304cc', 'instance_type': 'c5.4xlarge', 'state': 'pending', 'host': '10.26.37.132', 'tags': [{'Key': 'Name', 'Value': 'PYTHON-ordinary-foxhound'}, {'Key': 'Project', 'Value': 'Basic_Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}], 'user': 'jason_ducker', 'start_time': 1787666355.8087168}]
timelog: PYTHON-ordinary-foxhound: 1 minutes - 1 x c5.4xlarge

===============================================================
  ACTUAL CLUSTER COST  (on-demand, Linux, based on real runtime)
===============================================================
  Cluster name  : PYTHON-ordinary-foxhound
  Instance type : c5.4xlarge
  Node count    : 1
  Elapsed time  : 1 minutes  (0.017 hrs)
  Per-node rate : $0.6800 / hr
  ACTUAL COST   : $0.0113
  NOTE: On-demand rate only; Reserved/Spot pricing will differ.
===============================================================

 2026-08-25 13:59:22,125  INFO - cluster_tasks.cluster_terminate | Responses from terminate: 
13:59:22.125 | INFO    | workflow - Responses from terminate: 
[{'CurrentState': {'Code': 32, 'Name': 'shutting-down'},
  'InstanceId': 'i-0e61b9c06fb1304cc',
  'PreviousState': {'Code': 16, 'Name': 'running'}}]
13:59:22.127 | INFO    | Task run 'cluster_terminate-083' - Finished in state Completed()
13:59:47.772 | INFO    | Flow run 'ordinary-foxhound' - Finished in state Completed()

```
**You've succesfully completed your basic Python model execution using the IOOS Cloud-Sandbox cloudflow method!**

---

### Mode B: MPI-Enabled Python Execution (`mpi4py`)

Multi-node parallel Python execution linked via `mpiexec` across host instances.

#### Step 1: Environment Build Script (`mpi4py` + `netCDF4`)
MPI Python environments must be compiled against Spack HPC modules available on the head node. Below is an example build script to compile and link Intel MPI compilers and netCDF4 libraries to your Python environment:

```bash
#!/bin/bash
set -e

echo "=== Loading Spack HPC Modules ==="
module load intel-oneapi-compilers/2023.1.0-gcc-11.2.1-3rbcwfi
module load esmf/8.5.0-intel-2021.9.0-5sphkv4

export MPICC=$(which mpiicc)
export MPICXX=$(which mpiicpc)
export NETCDF4_DIR=$(nc-config --prefix)
export HDF5_DIR=$(dirname $(dirname $(which h5dump)))
export LDFLAGS="-L$(nc-config --libdir) -Wl,-rpath,$(nc-config --libdir)"
export CFLAGS="-I$(nc-config --includedir)"

echo "=== Building Environment ==="
./miniforge3/bin/mamba env create -f ocs_mesh_cloud_sandbox.yml -y

ENV_NAME=$(grep -E '^name:' ocs_mesh_cloud_sandbox.yml | awk '{print $2}')
ENV_PATH="./miniforge3/envs/$ENV_NAME"
ENV_PIP="$ENV_PATH/bin/pip"
ENV_LIB="$ENV_PATH/lib"
ENV_SP="$ENV_PATH/lib/python3.13/site-packages"
ENV_BIN="$ENV_PATH/bin"

# Purge conflicting binaries and pre-packaged mpi4py
rm -f $ENV_LIB/libnetcdf.so* $ENV_LIB/libhdf5*
rm -rf $ENV_SP/mpi4py* $ENV_SP/*mpi4py*

echo "=== Building Parallel Extensions ==="
$ENV_PIP install mpi4py --no-binary mpi4py --no-build-isolation --no-cache-dir
$ENV_PIP install h5py --no-binary h5py --no-build-isolation --no-cache-dir
$ENV_PIP install cftime --no-cache-dir

git clone [https://github.com/Unidata/netcdf4-python.git](https://github.com/Unidata/netcdf4-python.git)
cd netcdf4-python && git checkout v1.7.4rel
rm -f src/netCDF4/_netCDF4.c
export CFLAGS="-I$(nc-config --includedir) -DPyMPI_HAVE_MPI_Session=0"
../$ENV_PIP install . --no-binary netcdf4 --no-build-isolation --no-deps --no-cache-dir
cd .. && rm -rf netcdf4-python

$ENV_BIN/python -c "import mpi4py, netCDF4; print('MPI environment ready!')"
```

#### Step 2: Configure Job & Cluster Specifications
Edit `../job.configs/MODEL_EXPERIMENTS/python_mpi.experiment`:
```json
{
  "MODEL"   : "PYTHON",
  "JOBTYPE" : "python_experiment",
  "APP"     : "mpi",
  "EXEC"    : "/save/jason_ducker/miniforge3/envs/ocsmesh/bin/python",
  "SCRIPT"  : "/save/jason_ducker/GSOC_Group/test_mpi.py"
}
```
* **`MODEL`**: Model framework class (`PYTHON`).
* **`JOBTYPE`**: Job type (`python_experiment`).
* **`APP`**: Application execution mode (`mpi` for parallel MPI execution).
* **`EXEC`**: Absolute pathway to the compiled MPI-enabled Python environment (e.g., `ocsmesh`).
* **`SCRIPT`**: Absolute pathway to the target parallel Python script hosted on EFS.

> **Note:** If you would like to add dynamic arguments to utilize for your Python script, then please refer to [Section 4: Integrating Custom Arguments into Cloudflow](https://github.com/jduckerOWP/Cloud-Sandbox_OWP/blob/main/cloudflow/CLOUDFLOW_PYTHON_MODEL_EXECUTION_INSTRUCTIONS.md#4-integrating-custom-arguments-into-cloudflow) for instructions on integrating those arguments within cloudflow.

Edit `../cluster.configs/Experiments/python.ioos` (Set `nodeCount` to desired scale, e.g., `2`)[cite: 4]:
```json
{
  "platform"        : "AWS",
  "region"          : "us-east-2",
  "nodeType"        : "c5.4xlarge",
  "nodeCount"       : 2,
  "vm_retry_delay"  : 300,
  "vm_max_retries"  : 5,
  "image_id"        : "ami-0cbf4e2a2768a602b",
  "key_name"        : "rsa_sandbox_key",
  "sg_ids"          : ["sg-05c044182398b2a27", "sg-0e5148638d9196f69", "sg-06ca6bc5d4b377dad"],
  "subnet_id"       : "subnet-00075cfbfcbc8f2cf",
  "placement_group" : "ioos_cloud_sandbox_Terraform_Placement_Group",
  "table_name"      : "IOOS-Sandbox-Compute-Nodes"
}
```
* **`platform`**: Target cloud provider (`AWS`).
* **`region`**: AWS region hosting Sandbox resources (`us-east-2`).
* **`nodeType`**: Requested AWS EC2 instance type (e.g., `c5.4xlarge`).
* **`nodeCount`**: Allocated compute nodes (`2` or more). Because `mpiexec` manages multi-node IP distribution, MPI Python jobs scale seamlessly across multiple instances.
* * **`vm_retry_delay`**: Delay in seconds between resource allocation queries (`300`).
* **`vm_max_retries`**: Maximum query retries for AWS resource requests (`5`).
* **`tags`**: Resource tags assigned for Prefect job ID tracking.
* **`image_id`**: AMI ID matching the head node and mounted EFS volume (`ami-0cbf4e2a2768a602b`).
* **`key_name`**: SSH key pair name configured for the AWS account (`rsa_sandbox_key`).
* **`sg_ids`**: Security group IDs for network traffic control.
* **`subnet_id`**: AWS account subnet identifier.
* **`placement_group`**: Target data center placement group.
* **`table_name`**: AWS DynamoDB table tracking job specifications (`IOOS-Sandbox-Compute-Nodes`).

---

> **Important:** Ensure `image_id` matches the exact AMI associated with your running head node so compute nodes mount identical environments. If you're still having issues launching the job, you may need to include an extra security group id for the EFS volume mounted on the head node your'e on. Besides that, you only need to worry about changing `nodeType`, `nodeCount`, and `tags` if desired. 

---

#### Step 3: Configure Shell Launcher Script
Edit `workflows/python_mpi_basic_run.sh` to load required runtime modules:
```bash
module load intel-oneapi-compilers/2023.1.0-gcc-11.2.1-3rbcwfi
module load esmf/8.5.0-intel-2021.9.0-5sphkv4
```

#### Step 4: Submit and Monitor Job
```bash
nohup ./workflows/workflow_main.py ../cluster.configs/Experiments/python.ioos ../job.configs/MODEL_EXPERIMENTS/python_mpi.experiment > cloudflow_test.out &
tail -f cloudflow_test.out
```

#### Step 5: Execution Lifecycle Overview
When launched, the Cloudflow pipeline executes the following stages automatically:

1. **Resource Allocation:** Generates a dynamic cluster name (e.g., `PYTHON-independent-cricket`), queries AWS for requested EC2 compute instances, logs telemetry to DynamoDB, and calculates initial cost projections.

```bash
jobtype: python_experiment
13:29:26.576 | INFO    | Flow run 'magic-roadrunner' - Beginning flow run 'magic-roadrunner' for flow 'experiment-flow'
13:29:26.584 | INFO    | Flow run 'magic-roadrunner' - View at http://127.0.0.1:4200/runs/flow-run/167d22f0-5e93-48b4-9f50-2175ceba14c8
 2026-08-31 13:29:26,607  INFO - ClusterFactory.cluster | Attempting to make a new cluster : AWS
13:29:26.607 | INFO    | workflow - Attempting to make a new cluster : AWS

***************************************************************
Your cluster name: PYTHON-magic-roadrunner
***************************************************************

 2026-08-31 13:29:26,609  INFO - AWSCluster.memorable_tags | Your cluster Name: PYTHON-magic-roadrunner
13:29:26.609 | INFO    | workflow - Your cluster Name: PYTHON-magic-roadrunner
self.tags: [{'Key': 'Name', 'Value': 'PYTHON-magic-roadrunner'}, {'Key': 'Project', 'Value': 'MPI_Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}]
 2026-08-31 13:29:26,869  INFO - AWSCluster.__init__ | nodeCount: 2  PPN: 8
13:29:26.869 | INFO    | workflow - nodeCount: 2  PPN: 8
 2026-08-31 13:29:26,869  INFO - ClusterFactory.cluster | Created new AWS cluster
13:29:26.869 | INFO    | workflow - Created new AWS cluster
13:29:26.871 | INFO    | Task run 'cluster_init-66e' - Finished in state Completed()
in job init
<cloudflow.job.PYTHON_Experiment.PYTHON_Experiment object at 0x14f1c8dbdfd0>
13:29:26.878 | INFO    | Task run 'job_init-71e' - Finished in state Completed()
 2026-08-31 13:29:26,881  INFO - cluster_tasks.cluster_start | Starting 2 instances ...
13:29:26.881 | INFO    | workflow - Starting 2 instances ...
 2026-08-31 13:29:26,882  INFO - cluster_tasks.cluster_start | Waiting for nodes to start ...
13:29:26.882 | INFO    | workflow - Waiting for nodes to start ...

===============================================================
  ESTIMATED CLUSTER COST  (on-demand, Linux, no pre-installed SW)
===============================================================
  Instance type : c5.4xlarge
  Region        : us-east-2  (US East (Ohio))
  Node count    : 2
  Per-node rate : $0.6800 / hr
  Cluster cost  : $1.3600 / hr  |  $32.64 / day
  NOTE: Estimate is for on-demand pricing only.
        Actual charges depend on run time and AWS billing.
===============================================================

 2026-08-31 13:29:27,047  INFO - AWSCluster._estimate_and_print_cost | Cost estimate – 2x c5.4xlarge @ us-east-2: $1.3600/hr  |  $32.64/day
13:29:27.047 | INFO    | workflow - Cost estimate – 2x c5.4xlarge @ us-east-2: $1.3600/hr  |  $32.64/day
```

2. **Node Initialization:** Waits for requested instances to enter a running state and initializes environment mounts.
```bash
 2026-08-31 13:29:29,086  INFO - AWSCluster.start | AWS resources have been allocated for cloudflow job. Waiting for nodes to enter running state ...
13:29:29.086 | INFO    | workflow - AWS resources have been allocated for cloudflow job. Waiting for nodes to enter running state ...
 2026-08-31 13:29:29,110  INFO - AWSCluster.__put_instance_records | DB_table output for head node based on instance id i-0042d07eae3ded59e: {'instance-id': 'i-0042d07eae3ded59e', 'name-tag': 'PYTHON-magic-roadrunner', 'instance-type': 'c5.4xlarge', 'start-time': 1788182969, 'human-time': '2026-08-31 13:29 UTC', 'minutes-max': 120, 'username': 'jason_ducker'}
13:29:29.110 | INFO    | workflow - DB_table output for head node based on instance id i-0042d07eae3ded59e: {'instance-id': 'i-0042d07eae3ded59e', 'name-tag': 'PYTHON-magic-roadrunner', 'instance-type': 'c5.4xlarge', 'start-time': 1788182969, 'human-time': '2026-08-31 13:29 UTC', 'minutes-max': 120, 'username': 'jason_ducker'}
 2026-08-31 13:29:29,110  INFO - AWSCluster.__put_instance_records | DB_table output for head node based on instance id i-0289c9482b3e35507: {'instance-id': 'i-0289c9482b3e35507', 'name-tag': 'PYTHON-magic-roadrunner', 'instance-type': 'c5.4xlarge', 'start-time': 1788182969, 'human-time': '2026-08-31 13:29 UTC', 'minutes-max': 120, 'username': 'jason_ducker'}
13:29:29.110 | INFO    | workflow - DB_table output for head node based on instance id i-0289c9482b3e35507: {'instance-id': 'i-0289c9482b3e35507', 'name-tag': 'PYTHON-magic-roadrunner', 'instance-type': 'c5.4xlarge', 'start-time': 1788182969, 'human-time': '2026-08-31 13:29 UTC', 'minutes-max': 120, 'username': 'jason_ducker'}
 2026-08-31 13:29:39,997  INFO - AWSCluster.start | Waiting an additional 150 seconds for nodes to fully initialize ...
13:29:39.997 | INFO    | workflow - Waiting an additional 150 seconds for nodes to fully initialize ...
```

3. **Model Execution:** Enters the target directory (`MODEL_DIR`), checks the Python MPI script for syntax errors before proceeding to executing the script, and then executes the Python script using MPI over SSH (e.g., `mpiexec -launcher ssh -hosts <IP> -np <CORES> ... python $SCRIPT`)
```bash
instance 1 : running
instance 2 : running
{"instance_id": "i-0042d07eae3ded59e", "instance_type": "c5.4xlarge", "state": "pending", "host": "10.26.36.23", "tags": [{"Key": "Name", "Value": "PYTHON-magic-roadrunner"}, {"Key": "Project", "Value": "MPI_Model_Experiment"}, {"Key": "ApprovedSubnet", "Value": "subnet-00075cfbfcbc8f2cf"}], "user": "jason_ducker", "start_time": 1788183130.3750582}
{"instance_id": "i-0289c9482b3e35507", "instance_type": "c5.4xlarge", "state": "pending", "host": "10.26.36.71", "tags": [{"Key": "Name", "Value": "PYTHON-magic-roadrunner"}, {"Key": "Project", "Value": "MPI_Model_Experiment"}, {"Key": "ApprovedSubnet", "Value": "subnet-00075cfbfcbc8f2cf"}], "user": "jason_ducker", "start_time": 1788183130.3750582}
13:32:10.379 | INFO    | Task run 'cluster_start-064' - Finished in state Completed()
runscript: /mnt/efs/fs1/save/jason_ducker/Cloud-Sandbox/cloudflow/workflows/experiment_launcher.sh
**********************************************************
Current directory is /save/jason_ducker/Cloud-Sandbox/cloudflow
**********************************************************
+ set -u
+ export SCRIPT=/save/jason_ducker/GSOC_Group/test_mpi.py
+ SCRIPT=/save/jason_ducker/GSOC_Group/test_mpi.py
+ export EXEC=/save/jason_ducker/miniforge3/envs/ocsmesh_test/bin/python
+ EXEC=/save/jason_ducker/miniforge3/envs/ocsmesh_test/bin/python
+ echo '--- '
--- 
+ echo '--- Checking PYTHON MPI script for syntax errors and then running PYTHON MPI script -----------------'
--- Checking PYTHON MPI script for syntax errors and then running PYTHON MPI script -----------------
+ echo ---
---
+ /save/jason_ducker/miniforge3/envs/ocsmesh_test/bin/python -m py_compile /save/jason_ducker/GSOC_Group/test_mpi.py
+ mpirun -envall -launcher ssh -hosts 10.26.36.23,10.26.36.71 -np 16 -ppn 8 /save/jason_ducker/miniforge3/envs/ocsmesh_test/bin/python /save/jason_ducker/GSOC_Group/test_mpi.py
Rank 1/16 is alive on host 'ip-10-26-36-23.us-east-2.compute.internal'
Rank 2/16 is alive on host 'ip-10-26-36-23.us-east-2.compute.internal'
Rank 3/16 is alive on host 'ip-10-26-36-23.us-east-2.compute.internal'
Rank 4/16 is alive on host 'ip-10-26-36-23.us-east-2.compute.internal'
Rank 5/16 is alive on host 'ip-10-26-36-23.us-east-2.compute.internal'
Rank 6/16 is alive on host 'ip-10-26-36-23.us-east-2.compute.internal'
Rank 7/16 is alive on host 'ip-10-26-36-23.us-east-2.compute.internal'
Rank 8/16 is alive on host 'ip-10-26-36-71.us-east-2.compute.internal'
Rank 9/16 is alive on host 'ip-10-26-36-71.us-east-2.compute.internal'
Rank 10/16 is alive on host 'ip-10-26-36-71.us-east-2.compute.internal'
Rank 11/16 is alive on host 'ip-10-26-36-71.us-east-2.compute.internal'
Rank 12/16 is alive on host 'ip-10-26-36-71.us-east-2.compute.internal'
Rank 13/16 is alive on host 'ip-10-26-36-71.us-east-2.compute.internal'
Rank 14/16 is alive on host 'ip-10-26-36-71.us-east-2.compute.internal'
Rank 15/16 is alive on host 'ip-10-26-36-71.us-east-2.compute.internal'
============================================================
          MPI4PY CONFIGURATION SANITY CHECK          
============================================================
Python Version:   3.13.14
MPI Vendor:       Intel MPI v2021.12.1
Total MPI Ranks:  16
------------------------------------------------------------
Rank 0/16 is alive on host 'ip-10-26-36-23.us-east-2.compute.internal'
------------------------------------------------------------
Running Ring Communication Pass-Around Test...
Rank 0 received token back from Rank 15. Value matches: True
============================================================
+ '[' 0 -ne 0 ']'
+ echo 'Python script execution has succesfully completed on the cloud!'
Python script execution has succesfully completed on the cloud!
```


4. **Deprovisioning & Reporting:** Automatically terminates instantiated compute instance upon run completion or failure, releasing resources and reporting actual compute wall-time and final estimated AWS cost.
```bash
+ echo 'Python script execution took 0 minutes and 18 seconds elapsed.'
Python script execution took 0 minutes and 18 seconds elapsed.
 2026-08-31 13:32:28,691  INFO - tasks.experiment_run | PYTHON mpi script execution finished successfully
13:32:28.691 | INFO    | workflow - PYTHON mpi script execution finished successfully
13:32:28.692 | INFO    | Task run 'experiment_run-bf0' - Finished in state Completed()
 2026-08-31 13:32:28,696  INFO - AWSCluster.terminate | Terminating instances: [{'instance_id': 'i-0042d07eae3ded59e', 'instance_type': 'c5.4xlarge', 'state': 'pending', 'host': '10.26.36.23', 'tags': [{'Key': 'Name', 'Value': 'PYTHON-magic-roadrunner'}, {'Key': 'Project', 'Value': 'MPI_Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}], 'user': 'jason_ducker', 'start_time': 1788183130.3750582}, {'instance_id': 'i-0289c9482b3e35507', 'instance_type': 'c5.4xlarge', 'state': 'pending', 'host': '10.26.36.71', 'tags': [{'Key': 'Name', 'Value': 'PYTHON-magic-roadrunner'}, {'Key': 'Project', 'Value': 'MPI_Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}], 'user': 'jason_ducker', 'start_time': 1788183130.3750582}]
13:32:28.696 | INFO    | workflow - Terminating instances: [{'instance_id': 'i-0042d07eae3ded59e', 'instance_type': 'c5.4xlarge', 'state': 'pending', 'host': '10.26.36.23', 'tags': [{'Key': 'Name', 'Value': 'PYTHON-magic-roadrunner'}, {'Key': 'Project', 'Value': 'MPI_Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}], 'user': 'jason_ducker', 'start_time': 1788183130.3750582}, {'instance_id': 'i-0289c9482b3e35507', 'instance_type': 'c5.4xlarge', 'state': 'pending', 'host': '10.26.36.71', 'tags': [{'Key': 'Name', 'Value': 'PYTHON-magic-roadrunner'}, {'Key': 'Project', 'Value': 'MPI_Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}], 'user': 'jason_ducker', 'start_time': 1788183130.3750582}]
timelog: PYTHON-magic-roadrunner: 1 minutes - 2 x c5.4xlarge

===============================================================
  ACTUAL CLUSTER COST  (on-demand, Linux, based on real runtime)
===============================================================
  Cluster name  : PYTHON-magic-roadrunner
  Instance type : c5.4xlarge
  Node count    : 2
  Elapsed time  : 1 minutes  (0.017 hrs)
  Per-node rate : $0.6800 / hr
  ACTUAL COST   : $0.0227
  NOTE: On-demand rate only; Reserved/Spot pricing will differ.
===============================================================

 2026-08-31 13:32:29,689  INFO - cluster_tasks.cluster_terminate | Responses from terminate: 
13:32:29.689 | INFO    | workflow - Responses from terminate: 
[{'CurrentState': {'Code': 32, 'Name': 'shutting-down'},
  'InstanceId': 'i-0042d07eae3ded59e',
  'PreviousState': {'Code': 16, 'Name': 'running'}}]
[{'CurrentState': {'Code': 32, 'Name': 'shutting-down'},
  'InstanceId': 'i-0289c9482b3e35507',
  'PreviousState': {'Code': 16, 'Name': 'running'}}]
13:32:29.690 | INFO    | Task run 'cluster_terminate-c2b' - Finished in state Completed()
13:32:30.601 | INFO    | Flow run 'magic-roadrunner' - Finished in state Completed()
```
**You've succesfully completed your MPI Python model execution using the IOOS Cloud-Sandbox cloudflow method!**

---

### Mode C: Dask Distributed Execution

Scalable task or data parallelism across AWS workers via Dask Distributed.

> **Important Requirement:** Dask requires a single unified Conda environment containing both Cloudflow dependencies and script-level dependencies across head and worker nodes.

#### Step 1: Create Unified Dask Environment
Create `dask_miniforge3_installation.yml` that includes your dask script Python module dependencies as needed starting with the template yaml file below:
```yaml
name: cloudflow_dask
channels:
  - conda-forge
dependencies:
  - pip
  - setuptools
  - wheel
  - boto3==1.40.22
  - botocore==1.40.22
  - dask>=2026.1.0
  - distributed
  - matplotlib==3.10.6
  - netCDF4==1.7.2
  - numpy==2.3.2
  - pillow>=12.2.0
  - pyproj==3.7.2
  - pip:
    - "fastapi>=0.111.0,<0.116.0"
    - prefect==3.6.29
    - haikunator
```

Build environment and bind main workflow script:
```bash
mamba env create -f dask_miniforge3_installation.yml -y
sed -i 's|#!/usr/bin/env -S python3 -u|#!/usr/bin/env /save/jason.ducker/miniforge3/envs/cloudflow_dask/bin/python|' workflows/workflow_main.py
```

#### Step 2: Configure Script Logging
Inside your script (`./workflows/python_examples.py`), redirect logging to Dask worker output:
```python
import logging
log = logging.getLogger("distributed.worker")
log.info("Executing Dask task step...")
```

---

#### Method 1: Data Parallelism (`client.map`)
Use when applying a single function across an iterable dataset across workers.

1. **Job Configuration** (`../job.configs/MODEL_EXPERIMENTS/python_dask_data_parallelism.experiment`):
   ```json
   {
     "MODEL"                        : "PYTHON",
     "JOBTYPE"                      : "python_experiment",
     "APP"                          : "dask_data_parallelism_example",
     "SCRIPT"                       : "./workflows/python_examples.py",
     "ARG1"                         : "./dask_output"
   }
   ```
* **`MODEL`**: Model framework class (`PYTHON`).
* **`JOBTYPE`**: Job type (`python_experiment`).
* **`APP`**: Python application mode for dask data parallelism.
* **`SCRIPT`**: Absolute pathway to the dask Python script hosted on EFS. This must be located within the `Cloud-Sandbox/cloudflow/workflows` directory for proper dask implementation on cloudflow.
* **`ARG1`**: Processing parameter (e.g., target year `2001`).
* **`ARG2`**: Target output directory path on EFS.

> **Note:** If you would like to add dynamic arguments to utilize for your Python dask script, then please refer to [Section 4: Integrating Custom Arguments into Cloudflow](https://github.com/jduckerOWP/Cloud-Sandbox_OWP/blob/main/cloudflow/CLOUDFLOW_PYTHON_MODEL_EXECUTION_INSTRUCTIONS.md#4-integrating-custom-arguments-into-cloudflow) for instructions on integrating those arguments within cloudflow.

2.  **Configure Cluster Infrastructure**
Edit `../cluster.configs/Experiments/python.ioos`:
```json
{
  "platform"        : "AWS",
  "region"          : "us-east-2",
  "nodeType"        : "c5.4xlarge",
  "nodeCount"       : 2,
  "vm_retry_delay"  : 300,
  "vm_max_retries"  : 5,
  "tags"            : [
                        { "Key": "Name", "Value": "Python" },
                        { "Key": "Project", "Value": "Model_Experiment" }
                      ],
  "image_id"        : "ami-0cbf4e2a2768a602b",
  "key_name"        : "rsa_sandbox_key",
  "sg_ids"          : ["sg-05c044182398b2a27", "sg-0e5148638d9196f69", "sg-06ca6bc5d4b377dad"],
  "subnet_id"       : "subnet-00075cfbfcbc8f2cf",
  "placement_group" : "ioos_cloud_sandbox_Terraform_Placement_Group",
  "table_name"      : "IOOS-Sandbox-Compute-Nodes"
}
```
* **`platform`**: Target cloud provider (`AWS`).
* **`region`**: AWS region hosting Sandbox resources (`us-east-2`).
* **`nodeType`**: Requested AWS EC2 instance type (e.g., `c5.4xlarge`).
* **`nodeCount`**: Number of EC2 compute nodes allocated for dask job.
* **`vm_retry_delay`**: Delay in seconds between resource allocation queries (`300`).
* **`vm_max_retries`**: Maximum query retries for AWS resource requests (`5`).
* **`tags`**: Resource tags assigned for Prefect job ID tracking.
* **`image_id`**: AMI ID matching the head node and mounted EFS volume (`ami-0cbf4e2a2768a602b`).
* **`key_name`**: SSH key pair name configured for the AWS account (`rsa_sandbox_key`).
* **`sg_ids`**: Security group IDs for network traffic control.
* **`subnet_id`**: AWS account subnet identifier.
* **`placement_group`**: Target data center placement group.
* **`table_name`**: AWS DynamoDB table tracking job specifications (`IOOS-Sandbox-Compute-Nodes`).

---

> **Important:** Ensure `image_id` matches the exact AMI associated with your running head node so compute nodes mount identical environments. If you're still having issues launching the job, you may need to include an extra security group id for the EFS volume mounted on the head node your'e on. Besides that, you only need to worry about changing `nodeType`, `nodeCount`, and `tags` if desired. 

---

3. **Task Integration** (`workflows/tasks.py`)
Modify the code accordingly within the `python_dask_experiment_run` function to conform with your specific Python dask data parallelism implementation. The code block below serves as a guide for proper implementation of the dask data parallelism method on cloudflow:
   ```python
   elif(job.APP == 'dask_data_parallelism_example'):
       client.upload_file(job.SCRIPT)
       from python_examples import dask_data_parallelism_example

       file_list = [f"sensor_{str(i).zfill(3)}" for i in range(0, 21)]
       output_dir = os.path.abspath(job.ARG1)
       os.makedirs(output_dir, exist_ok=True)

       futures = client.map(dask_data_parallelism_example, file_list, output_root=output_dir)
       results = client.gather(futures)
       for r in results:
           print(r)
   ```
4. **Execution**:
   ```bash
   nohup ./workflows/workflow_main.py ../cluster.configs/Experiments/python.ioos ../job.configs/MODEL_EXPERIMENTS/python_dask_data_parallelism.experiment > cloudflow_test.out &
   tail -f cloudflow_test.out
   ```

5. **Execution Lifecycle Overview**
When launched, the Cloudflow pipeline executes the following stages automatically:

a. **Resource Allocation:** Generates a dynamic cluster name (e.g., `PYTHON-benevolent-shoebill`), queries AWS for requested EC2 compute instances, logs telemetry to DynamoDB, and calculates initial cost projections.

```bash
jobtype: python_experiment
19:00:12.192 | INFO    | Flow run 'benevolent-shoebill' - Beginning flow run 'benevolent-shoebill' for flow 'python-experiment-dask-flow'
19:00:12.201 | INFO    | Flow run 'benevolent-shoebill' - View at http://127.0.0.1:4200/runs/flow-run/9ba19ff5-cfaf-4ead-bbad-0a644ee751d7
 2026-08-28 19:00:12,229  INFO - ClusterFactory.cluster | Attempting to make a new cluster : AWS
19:00:12.229 | INFO    | workflow - Attempting to make a new cluster : AWS

***************************************************************
Your cluster name: PYTHON-benevolent-shoebill
***************************************************************

 2026-08-28 19:00:12,231  INFO - AWSCluster.memorable_tags | Your cluster Name: PYTHON-benevolent-shoebill
19:00:12.231 | INFO    | workflow - Your cluster Name: PYTHON-benevolent-shoebill
self.tags: [{'Key': 'Name', 'Value': 'PYTHON-benevolent-shoebill'}, {'Key': 'Project', 'Value': 'Basic_Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}]
 2026-08-28 19:00:14,481  INFO - AWSCluster.__init__ | nodeCount: 1  PPN: 8
19:00:14.481 | INFO    | workflow - nodeCount: 1  PPN: 8
 2026-08-28 19:00:14,481  INFO - ClusterFactory.cluster | Created new AWS cluster
19:00:14.481 | INFO    | workflow - Created new AWS cluster
19:00:14.483 | INFO    | Task run 'cluster_init-150' - Finished in state Completed()
in job init
<cloudflow.job.PYTHON_Experiment.PYTHON_Experiment object at 0x14ac0943d400>
19:00:14.490 | INFO    | Task run 'job_init-206' - Finished in state Completed()
 2026-08-28 19:00:14,493  INFO - cluster_tasks.cluster_start | Starting 1 instances ...
19:00:14.493 | INFO    | workflow - Starting 1 instances ...
 2026-08-28 19:00:14,493  INFO - cluster_tasks.cluster_start | Waiting for nodes to start ...
19:00:14.493 | INFO    | workflow - Waiting for nodes to start ...

===============================================================
  ESTIMATED CLUSTER COST  (on-demand, Linux, no pre-installed SW)
===============================================================
  Instance type : c5.4xlarge
  Region        : us-east-2  (US East (Ohio))
  Node count    : 1
  Per-node rate : $0.6800 / hr
  Cluster cost  : $0.6800 / hr  |  $16.32 / day
  NOTE: Estimate is for on-demand pricing only.
        Actual charges depend on run time and AWS billing.
===============================================================

 2026-08-28 19:00:14,667  INFO - AWSCluster._estimate_and_print_cost | Cost estimate – 1x c5.4xlarge @ us-east-2: $0.6800/hr  |  $16.32/day
19:00:14.667 | INFO    | workflow - Cost estimate – 1x c5.4xlarge @ us-east-2: $0.6800/hr  |  $16.32/day
```

b. **Node Initialization:** Waits for requested instances to enter a running state and initializes environment mounts.
```bash
 2026-08-28 19:00:16,896  INFO - AWSCluster.start | AWS resources have been allocated for cloudflow job. Waiting for nodes to enter running state ...
19:00:16.896 | INFO    | workflow - AWS resources have been allocated for cloudflow job. Waiting for nodes to enter running state ...
 2026-08-28 19:00:16,918  INFO - AWSCluster.__put_instance_records | DB_table output for head node based on instance id i-02180321f1bec8414: {'instance-id': 'i-02180321f1bec8414', 'name-tag': 'PYTHON-benevolent-shoebill', 'instance-type': 'c5.4xlarge', 'start-time': 1787943616, 'human-time': '2026-08-28 19:00 UTC', 'minutes-max': 120, 'username': 'jason_ducker'}
19:00:16.918 | INFO    | workflow - DB_table output for head node based on instance id i-02180321f1bec8414: {'instance-id': 'i-02180321f1bec8414', 'name-tag': 'PYTHON-benevolent-shoebill', 'instance-type': 'c5.4xlarge', 'start-time': 1787943616, 'human-time': '2026-08-28 19:00 UTC', 'minutes-max': 120, 'username': 'jason_ducker'}
 2026-08-28 19:00:27,861  INFO - AWSCluster.start | Waiting an additional 150 seconds for nodes to fully initialize ...
19:00:27.861 | INFO    | workflow - Waiting an additional 150 seconds for nodes to fully initialize ...
```

c. **Dask Client Connectivity Checks:** Once resources have been allocated, a series of steps spin up the Dask client on a head node port, establish SSH connectivity with the Dask workers on the allocated EC2 instance(s), verify all connectivity is working, and deploy the Dask workers to the client upon script execution. 
```bash
instance 1 : running
{"instance_id": "i-02180321f1bec8414", "instance_type": "c5.4xlarge", "state": "pending", "host": "10.26.37.191", "tags": [{"Key": "Name", "Value": "PYTHON-benevolent-shoebill"}, {"Key": "Project", "Value": "Basic_Model_Experiment"}, {"Key": "ApprovedSubnet", "Value": "subnet-00075cfbfcbc8f2cf"}], "user": "jason_ducker", "start_time": 1787943778.0703945}
19:02:58.074 | INFO    | Task run 'cluster_start-d37' - Finished in state Completed()
 2026-08-28 19:02:58,078  INFO - cluster_tasks.find_available_port | Found available Dask port: 8786
19:02:58.078 | INFO    | workflow - Found available Dask port: 8786
 2026-08-28 19:02:58,079  INFO - cluster_tasks.start_dask | Checking SSH route to workers: ['10.26.37.191']
19:02:58.079 | INFO    | workflow - Checking SSH route to workers: ['10.26.37.191']
 2026-08-28 19:02:58,080  INFO - cluster_tasks.start_dask | Starting Scheduler on Head Node: 10.26.36.77:8786
19:02:58.080 | INFO    | workflow - Starting Scheduler on Head Node: 10.26.36.77:8786
 2026-08-28 19:03:01,085  INFO - cluster_tasks.start_dask | Deployed dask of workers to 10.26.37.191...
19:03:01.085 | INFO    | workflow - Deployed dask of workers to 10.26.37.191...
 2026-08-28 19:03:11,085  INFO - cluster_tasks.start_dask | Verifying cluster connectivity...
19:03:11.085 | INFO    | workflow - Verifying cluster connectivity...
 2026-08-28 19:03:17,179  INFO - cluster_tasks.start_dask | SUCCESS: 8/8 workers registered.
19:03:17.179 | INFO    | workflow - SUCCESS: 8/8 workers registered.
19:03:17.182 | INFO    | Task run 'start_dask-052' - Finished in state Completed()
 2026-08-28 19:03:17,195  INFO - tasks.python_dask_experiment_run | Cluster resources: dict_keys(['tcp://10.26.37.191:33045', 'tcp://10.26.37.191:33983', 'tcp://10.26.37.191:35043', 'tcp://10.26.37.191:35655', 'tcp://10.26.37.191:36823', 'tcp://10.26.37.191:40057', 'tcp://10.26.37.191:40205', 'tcp://10.26.37.191:45177'])
19:03:17.195 | INFO    | workflow - Cluster resources: dict_keys(['tcp://10.26.37.191:33045', 'tcp://10.26.37.191:33983', 'tcp://10.26.37.191:35043', 'tcp://10.26.37.191:35655', 'tcp://10.26.37.191:36823', 'tcp://10.26.37.191:40057', 'tcp://10.26.37.191:40205', 'tcp://10.26.37.191:45177'])
```

d. **Dask Data Parallelism Execution:** Directly submits computational tasks or maps functions across the connected worker pool using the native Prefect/Dask Distributed API. Reports back the logging information from the dask workers at the end of the script, reflecting the logging mechanisms that was used in the Python script.
```bash
2026-08-28 19:03:25,698  INFO - tasks.python_dask_experiment_run | output directory is /mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output
19:03:25.698 | INFO    | workflow - output directory is /mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_000.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_001.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_002.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_003.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_004.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_005.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_006.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_007.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_008.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_009.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_010.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_011.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_012.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_013.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_014.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_015.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_016.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_017.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_018.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_019.csv
/mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_020.csv
 2026-08-28 19:03:28,932  INFO - tasks.python_dask_experiment_run | Fetching logs from AWS workers...
19:03:28.932 | INFO    | workflow - Fetching logs from AWS workers...
 2026-08-28 19:03:28,934  INFO - tasks.python_dask_experiment_run | [tcp://10.26.37.191:33045] 2026-08-28 19:03:27,926 - distributed.worker - INFO - Successfully wrote csv file /mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_011.csv
19:03:28.934 | INFO    | workflow - [tcp://10.26.37.191:33045] 2026-08-28 19:03:27,926 - distributed.worker - INFO - Successfully wrote csv file /mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_011.csv
 2026-08-28 19:03:28,934  INFO - tasks.python_dask_experiment_run | [tcp://10.26.37.191:33045] 2026-08-28 19:03:26,910 - distributed.worker - INFO - Successfully wrote csv file /mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_003.csv
19:03:28.934 | INFO    | workflow - [tcp://10.26.37.191:33045] 2026-08-28 19:03:26,910 - distributed.worker - INFO - Successfully wrote csv file /mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/result_sensor_003.csv
 2026-08-28 19:03:28,935  INFO - tasks.python_dask_experiment_run | [tcp://10.26.37.191:33045] 2026-08-28 19:03:19,077 - distributed.worker - INFO - Starting Worker plugin /mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/workflows/python_examples.py9e024ab7-5513-45c4-a24c-b90a20ac353b
19:03:28.935 | INFO    | workflow - [tcp://10.26.37.191:33045] 2026-08-28 19:03:19,077 - distributed.worker - INFO - Starting Worker plugin /mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/workflows/python_examples.py9e024ab7-5513-45c4-a24c-b90a20ac353b
 2026-08-28 19:03:28,935  INFO - tasks.python_dask_experiment_run | [tcp://10.26.37.191:33045] 2026-08-28 19:03:17,098 - distributed.worker - INFO - -------------------------------------------------
19:03:28.935 | INFO    | workflow - [tcp://10.26.37.191:33045] 2026-08-28 19:03:17,098 - distributed.worker - INFO - -------------------------------------------------
 2026-08-28 19:03:28,935  INFO - tasks.python_dask_experiment_run | [tcp://10.26.37.191:33045] 2026-08-28 19:03:17,098 - distributed.worker - INFO -         Registered to:     tcp://10.26.36.77:8786
19:03:28.935 | INFO    | workflow - [tcp://10.26.37.191:33045] 2026-08-28 19:03:17,098 - distributed.worker - INFO -         Registered to:     tcp://10.26.36.77:8786
 2026-08-28 19:03:28,935  INFO - tasks.python_dask_experiment_run | [tcp://10.26.37.191:33045] 2026-08-28 19:03:17,097 - distributed.worker - INFO - Starting Worker plugin shuffle
19:03:28.935 | INFO    | workflow - [tcp://10.26.37.191:33045] 2026-08-28 19:03:17,097 - distributed.worker - INFO - Starting Worker plugin shuffle
 2026-08-28 19:03:28,936  INFO - tasks.python_dask_experiment_run | [tcp://10.26.37.191:33045] 2026-08-28 19:03:17,055 - distributed.worker - INFO - -------------------------------------------------
```

e. **Deprovisioning & Reporting:** Automatically terminates instantiated compute instance upon run completion or failure, releasing resources and reporting actual compute wall-time and final estimated AWS cost.
```bash
19:03:28.968 | INFO    | Task run 'python_dask_experiment_run-192' - Finished in state Completed()
 2026-08-28 19:03:28,971  INFO - cluster_tasks.dask_client_close | Terminating local Dask scheduler...
19:03:28.971 | INFO    | workflow - Terminating local Dask scheduler...
 2026-08-28 19:03:29,285  INFO - cluster_tasks.dask_client_close | Dask scheduler terminated gracefully.
19:03:29.285 | INFO    | workflow - Dask scheduler terminated gracefully.
 2026-08-28 19:03:29,285  INFO - cluster_tasks.dask_client_close | Terminating 1 remote Dask worker SSH processes...
19:03:29.285 | INFO    | workflow - Terminating 1 remote Dask worker SSH processes...
 2026-08-28 19:03:29,287  INFO - cluster_tasks.dask_client_close | Remote worker SSH processes signaled to stop.
19:03:29.287 | INFO    | workflow - Remote worker SSH processes signaled to stop.
19:03:29.288 | INFO    | Task run 'dask_client_close-bc2' - Finished in state Completed()
 2026-08-28 19:03:29,291  INFO - AWSCluster.terminate | Terminating instances: [{'instance_id': 'i-02180321f1bec8414', 'instance_type': 'c5.4xlarge', 'state': 'pending', 'host': '10.26.37.191', 'tags': [{'Key': 'Name', 'Value': 'PYTHON-benevolent-shoebill'}, {'Key': 'Project', 'Value': 'Basic_Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}], 'user': 'jason_ducker', 'start_time': 1787943778.0703945}]
19:03:29.291 | INFO    | workflow - Terminating instances: [{'instance_id': 'i-02180321f1bec8414', 'instance_type': 'c5.4xlarge', 'state': 'pending', 'host': '10.26.37.191', 'tags': [{'Key': 'Name', 'Value': 'PYTHON-benevolent-shoebill'}, {'Key': 'Project', 'Value': 'Basic_Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}], 'user': 'jason_ducker', 'start_time': 1787943778.0703945}]
timelog: PYTHON-benevolent-shoebill: 1 minutes - 1 x c5.4xlarge

===============================================================
  ACTUAL CLUSTER COST  (on-demand, Linux, based on real runtime)
===============================================================
  Cluster name  : PYTHON-benevolent-shoebill
  Instance type : c5.4xlarge
  Node count    : 1
  Elapsed time  : 1 minutes  (0.017 hrs)
  Per-node rate : $0.6800 / hr
  ACTUAL COST   : $0.0113
  NOTE: On-demand rate only; Reserved/Spot pricing will differ.
===============================================================

 2026-08-28 19:03:29,852  INFO - cluster_tasks.cluster_terminate | Responses from terminate: 
19:03:29.852 | INFO    | workflow - Responses from terminate: 
[{'CurrentState': {'Code': 32, 'Name': 'shutting-down'},
  'InstanceId': 'i-02180321f1bec8414',
  'PreviousState': {'Code': 16, 'Name': 'running'}}]
19:03:29.854 | INFO    | Task run 'cluster_terminate-25b' - Finished in state Completed()
19:04:38.226 | INFO    | Flow run 'benevolent-shoebill' - Finished in state Completed()
```
**You've succesfully completed your Python dask data parallelism execution using the IOOS Cloud-Sandbox cloudflow method!**

---

#### Method 2: Task Parallelism (`client.submit`)
Use when submitting dedicated computations to the Dask cluster.

1. **Job Configuration** (`../job.configs/MODEL_EXPERIMENTS/python_dask_task_parallelism.experiment`):
   ```json
   {
     "MODEL"                        : "PYTHON",
     "JOBTYPE"                      : "python_experiment",
     "dask_task_parallelism_example": "basic",
     "SCRIPT"                       : "./workflows/python_examples.py",
     "ARG1"                         : "2001",
     "ARG2"                         : "./dask_output"
   }
   ```
* **`MODEL`**: Model framework class (`PYTHON`).
* **`JOBTYPE`**: Job type (`python_experiment`).
* **`APP`**: Python application mode for dask task parallelism.
* **`SCRIPT`**: Absolute pathway to the dask Python script hosted on EFS. This must be located within the `Cloud-Sandbox/cloudflow/workflows` directory for proper dask implementation on cloudflow.
* **`ARG1`**: Processing parameter (e.g., target year `2001`).
* **`ARG2`**: Target output directory path on EFS.

> **Note:** If you would like to add dynamic arguments to utilize for your Python dask script, then please refer to [Section 4: Integrating Custom Arguments into Cloudflow](https://github.com/jduckerOWP/Cloud-Sandbox_OWP/blob/main/cloudflow/CLOUDFLOW_PYTHON_MODEL_EXECUTION_INSTRUCTIONS.md#4-integrating-custom-arguments-into-cloudflow) for instructions on integrating those arguments within cloudflow.

2.  **Configure Cluster Infrastructure**
Edit `../cluster.configs/Experiments/python.ioos`:
```json
{
  "platform"        : "AWS",
  "region"          : "us-east-2",
  "nodeType"        : "c5.4xlarge",
  "nodeCount"       : 2,
  "vm_retry_delay"  : 300,
  "vm_max_retries"  : 5,
  "tags"            : [
                        { "Key": "Name", "Value": "Python" },
                        { "Key": "Project", "Value": "Model_Experiment" }
                      ],
  "image_id"        : "ami-0cbf4e2a2768a602b",
  "key_name"        : "rsa_sandbox_key",
  "sg_ids"          : ["sg-05c044182398b2a27", "sg-0e5148638d9196f69", "sg-06ca6bc5d4b377dad"],
  "subnet_id"       : "subnet-00075cfbfcbc8f2cf",
  "placement_group" : "ioos_cloud_sandbox_Terraform_Placement_Group",
  "table_name"      : "IOOS-Sandbox-Compute-Nodes"
}
```
* **`platform`**: Target cloud provider (`AWS`).
* **`region`**: AWS region hosting Sandbox resources (`us-east-2`).
* **`nodeType`**: Requested AWS EC2 instance type (e.g., `c5.4xlarge`).
* **`nodeCount`**: Number of EC2 compute nodes allocated for dask job.
* **`vm_retry_delay`**: Delay in seconds between resource allocation queries (`300`).
* **`vm_max_retries`**: Maximum query retries for AWS resource requests (`5`).
* **`tags`**: Resource tags assigned for Prefect job ID tracking.
* **`image_id`**: AMI ID matching the head node and mounted EFS volume (`ami-0cbf4e2a2768a602b`).
* **`key_name`**: SSH key pair name configured for the AWS account (`rsa_sandbox_key`).
* **`sg_ids`**: Security group IDs for network traffic control.
* **`subnet_id`**: AWS account subnet identifier.
* **`placement_group`**: Target data center placement group.
* **`table_name`**: AWS DynamoDB table tracking job specifications (`IOOS-Sandbox-Compute-Nodes`).

---

> **Important:** Ensure `image_id` matches the exact AMI associated with your running head node so compute nodes mount identical environments. If you're still having issues launching the job, you may need to include an extra security group id for the EFS volume mounted on the head node your'e on. Besides that, you only need to worry about changing `nodeType`, `nodeCount`, and `tags` if desired. 

---

3. **Task Integration** (`workflows/tasks.py`):
Modify the code accordingly within the `python_dask_experiment_run` function to conform with your specific Python dask task parallelism implementation. The code block below serves as a guide for proper implementation of the dask task parallelism method on cloudflow:
   ```python
   elif(job.APP == 'dask_task_parallelism_example'):
       client.upload_file(job.SCRIPT)
       from python_examples import dask_task_parallelism_example

       log.info("Running Python Dask task parallelism example")
       futures = client.submit(dask_task_parallelism_example, int(job.ARG1))
       results = client.gather(futures)

       output_dir = os.path.abspath(job.ARG2)
       os.makedirs(output_dir, exist_ok=True)

       ds_to_save = results.to_dataset(name='AORC_partial_data_gap')
       output_path = os.path.join(output_dir, f"aorc_gap_mask_{job.ARG1}.nc")
       ds_to_save.to_netcdf(output_path)
       log.info(f"Saved AORC masked year {job.ARG1} to {output_path}")
   ```
4. **Execution**:
   ```bash
   nohup ./workflows/workflow_main.py ../cluster.configs/Experiments/python.ioos ../job.configs/MODEL_EXPERIMENTS/python_dask_task_parallelism.experiment > cloudflow_test.out &
   tail -f cloudflow_test.out
   ```

5. **Execution Lifecycle Overview**
When launched, the Cloudflow pipeline executes the following stages automatically:

a. **Resource Allocation:** Generates a dynamic cluster name (e.g., `PYTHON-benevolent-shoebill`), queries AWS for requested EC2 compute instances, logs telemetry to DynamoDB, and calculates initial cost projections.

```bash
jobtype: python_experiment
20:03:54.112 | INFO    | Flow run 'sparkling-seahorse' - Beginning flow run 'sparkling-seahorse' for flow 'python-experiment-dask-flow'
20:03:54.139 | INFO    | Flow run 'sparkling-seahorse' - View at http://127.0.0.1:4200/runs/flow-run/58a8725b-384e-44f3-8813-7542bc647b15
 2026-08-28 20:03:54,174  INFO - ClusterFactory.cluster | Attempting to make a new cluster : AWS
20:03:54.174 | INFO    | workflow - Attempting to make a new cluster : AWS

***************************************************************
Your cluster name: PYTHON-sparkling-seahorse
***************************************************************

 2026-08-28 20:03:54,176  INFO - AWSCluster.memorable_tags | Your cluster Name: PYTHON-sparkling-seahorse
20:03:54.176 | INFO    | workflow - Your cluster Name: PYTHON-sparkling-seahorse
self.tags: [{'Key': 'Name', 'Value': 'PYTHON-sparkling-seahorse'}, {'Key': 'Project', 'Value': 'Basic_Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}]
 2026-08-28 20:03:55,929  INFO - AWSCluster.__init__ | nodeCount: 2  PPN: 2
20:03:55.929 | INFO    | workflow - nodeCount: 2  PPN: 2
 2026-08-28 20:03:55,930  INFO - ClusterFactory.cluster | Created new AWS cluster
20:03:55.930 | INFO    | workflow - Created new AWS cluster
20:03:55.931 | INFO    | Task run 'cluster_init-53f' - Finished in state Completed()
in job init
<cloudflow.job.PYTHON_Experiment.PYTHON_Experiment object at 0x149cf2565d30>
20:03:55.938 | INFO    | Task run 'job_init-948' - Finished in state Completed()
 2026-08-28 20:03:55,940  INFO - cluster_tasks.cluster_start | Starting 2 instances ...
20:03:55.940 | INFO    | workflow - Starting 2 instances ...
 2026-08-28 20:03:55,941  INFO - cluster_tasks.cluster_start | Waiting for nodes to start ...
20:03:55.941 | INFO    | workflow - Waiting for nodes to start ...

===============================================================
  ESTIMATED CLUSTER COST  (on-demand, Linux, no pre-installed SW)
===============================================================
  Instance type : r7i.xlarge
  Region        : us-east-2  (US East (Ohio))
  Node count    : 2
  Per-node rate : $0.2646 / hr
  Cluster cost  : $0.5292 / hr  |  $12.70 / day
  NOTE: Estimate is for on-demand pricing only.
        Actual charges depend on run time and AWS billing.
===============================================================

 2026-08-28 20:03:56,121  INFO - AWSCluster._estimate_and_print_cost | Cost estimate – 2x r7i.xlarge @ us-east-2: $0.5292/hr  |  $12.70/day
20:03:56.121 | INFO    | workflow - Cost estimate – 2x r7i.xlarge @ us-east-2: $0.5292/hr  |  $12.70/day
```

b. **Node Initialization:** Waits for requested instances to enter a running state and initializes environment mounts.
```bash
2026-08-28 20:03:58,585  INFO - AWSCluster.start | AWS resources have been allocated for cloudflow job. Waiting for nodes to enter running state ...
20:03:58.585 | INFO    | workflow - AWS resources have been allocated for cloudflow job. Waiting for nodes to enter running state ...
 2026-08-28 20:03:58,603  INFO - AWSCluster.__put_instance_records | DB_table output for head node based on instance id i-0023e349461362893: {'instance-id': 'i-0023e349461362893', 'name-tag': 'PYTHON-sparkling-seahorse', 'instance-type': 'r7i.xlarge', 'start-time': 1787947438, 'human-time': '2026-08-28 20:03 UTC', 'minutes-max': 120, 'username': 'jason_ducker'}
20:03:58.603 | INFO    | workflow - DB_table output for head node based on instance id i-0023e349461362893: {'instance-id': 'i-0023e349461362893', 'name-tag': 'PYTHON-sparkling-seahorse', 'instance-type': 'r7i.xlarge', 'start-time': 1787947438, 'human-time': '2026-08-28 20:03 UTC', 'minutes-max': 120, 'username': 'jason_ducker'}
 2026-08-28 20:03:58,604  INFO - AWSCluster.__put_instance_records | DB_table output for head node based on instance id i-062197a9de6c15549: {'instance-id': 'i-062197a9de6c15549', 'name-tag': 'PYTHON-sparkling-seahorse', 'instance-type': 'r7i.xlarge', 'start-time': 1787947438, 'human-time': '2026-08-28 20:03 UTC', 'minutes-max': 120, 'username': 'jason_ducker'}
20:03:58.604 | INFO    | workflow - DB_table output for head node based on instance id i-062197a9de6c15549: {'instance-id': 'i-062197a9de6c15549', 'name-tag': 'PYTHON-sparkling-seahorse', 'instance-type': 'r7i.xlarge', 'start-time': 1787947438, 'human-time': '2026-08-28 20:03 UTC', 'minutes-max': 120, 'username': 'jason_ducker'}
 2026-08-28 20:04:09,689  INFO - AWSCluster.start | Waiting an additional 150 seconds for nodes to fully initialize ...
20:04:09.689 | INFO    | workflow - Waiting an additional 150 seconds for nodes to fully initialize ...
```

c. **Dask Client Connectivity Checks:** Once resources have been allocated, a series of steps spin up the Dask client on a head node port, establish SSH connectivity with the Dask workers on the allocated EC2 instance(s), verify all connectivity is working, and deploy the Dask workers to the client upon script execution. 
```bash
instance 1 : running
instance 2 : running
{"instance_id": "i-0023e349461362893", "instance_type": "r7i.xlarge", "state": "pending", "host": "10.26.37.190", "tags": [{"Key": "Name", "Value": "PYTHON-sparkling-seahorse"}, {"Key": "Project", "Value": "Basic_Model_Experiment"}, {"Key": "ApprovedSubnet", "Value": "subnet-00075cfbfcbc8f2cf"}], "user": "jason_ducker", "start_time": 1787947600.0835288}
{"instance_id": "i-062197a9de6c15549", "instance_type": "r7i.xlarge", "state": "pending", "host": "10.26.37.127", "tags": [{"Key": "Name", "Value": "PYTHON-sparkling-seahorse"}, {"Key": "Project", "Value": "Basic_Model_Experiment"}, {"Key": "ApprovedSubnet", "Value": "subnet-00075cfbfcbc8f2cf"}], "user": "jason_ducker", "start_time": 1787947600.0835288}
20:06:40.087 | INFO    | Task run 'cluster_start-f66' - Finished in state Completed()
 2026-08-28 20:06:40,092  INFO - cluster_tasks.find_available_port | Found available Dask port: 8786
20:06:40.092 | INFO    | workflow - Found available Dask port: 8786
 2026-08-28 20:06:40,092  INFO - cluster_tasks.start_dask | Checking SSH route to workers: ['10.26.37.190', '10.26.37.127']
20:06:40.092 | INFO    | workflow - Checking SSH route to workers: ['10.26.37.190', '10.26.37.127']
 2026-08-28 20:06:40,095  INFO - cluster_tasks.start_dask | Starting Scheduler on Head Node: 10.26.36.77:8786
20:06:40.095 | INFO    | workflow - Starting Scheduler on Head Node: 10.26.36.77:8786
 2026-08-28 20:06:43,101  INFO - cluster_tasks.start_dask | Deployed dask of workers to 10.26.37.190...
20:06:43.101 | INFO    | workflow - Deployed dask of workers to 10.26.37.190...
 2026-08-28 20:06:53,102  INFO - cluster_tasks.start_dask | Deployed dask of workers to 10.26.37.127...
20:06:53.102 | INFO    | workflow - Deployed dask of workers to 10.26.37.127...
 2026-08-28 20:07:03,103  INFO - cluster_tasks.start_dask | Verifying cluster connectivity...
20:07:03.103 | INFO    | workflow - Verifying cluster connectivity...
 2026-08-28 20:07:03,134  INFO - cluster_tasks.start_dask | SUCCESS: 4/4 workers registered.
20:07:03.134 | INFO    | workflow - SUCCESS: 4/4 workers registered.
20:07:03.144 | INFO    | Task run 'start_dask-892' - Finished in state Completed()
 2026-08-28 20:07:03,152  INFO - tasks.python_dask_experiment_run | Cluster resources: dict_keys(['tcp://10.26.37.127:38739', 'tcp://10.26.37.127:44251', 'tcp://10.26.37.190:36053', 'tcp://10.26.37.190:36785'])
20:07:03.152 | INFO    | workflow - Cluster resources: dict_keys(['tcp://10.26.37.127:38739', 'tcp://10.26.37.127:44251', 'tcp://10.26.37.190:36053', 'tcp://10.26.37.190:36785'])
```

d. **Dask Task Parallelism Execution:** Directly submits computational tasks or maps functions across the connected worker pool using the native Prefect/Dask Distributed API. Reports back the logging information from the dask workers at the end of the script, reflecting the logging mechanisms that was used in the Python script.
```bash
2026-08-28 20:07:09,452  INFO - tasks.python_dask_experiment_run | Running Python dask task parallelism example
20:07:09.452 | INFO    | workflow - Running Python dask task parallelism example
 2026-08-28 20:57:19,071  INFO - tasks.python_dask_experiment_run | ✅ Saved AORC masked year 2001 to /mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/aorc_gap_mask_2001.nc
20:57:19.071 | INFO    | workflow - ✅ Saved AORC masked year 2001 to /mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/dask_output/aorc_gap_mask_2001.nc
 2026-08-28 20:57:19,071  INFO - tasks.python_dask_experiment_run | Fetching logs from AWS workers...
20:57:19.071 | INFO    | workflow - Fetching logs from AWS workers...
 2026-08-28 20:57:19,073  INFO - tasks.python_dask_experiment_run | [tcp://10.26.37.127:38739] 2026-08-28 20:07:15,181 - distributed.worker - INFO - Starting computation on dask workers for AORC data
20:57:19.073 | INFO    | workflow - [tcp://10.26.37.127:38739] 2026-08-28 20:07:15,181 - distributed.worker - INFO - Starting computation on dask workers for AORC data
 2026-08-28 20:57:19,074  INFO - tasks.python_dask_experiment_run | [tcp://10.26.37.127:38739] 2026-08-28 20:07:12,138 - distributed.worker - INFO - Loading AORC data for year 2001
20:57:19.074 | INFO    | workflow - [tcp://10.26.37.127:38739] 2026-08-28 20:07:12,138 - distributed.worker - INFO - Loading AORC data for year 2001
 2026-08-28 20:57:19,074  INFO - tasks.python_dask_experiment_run | [tcp://10.26.37.127:38739] 2026-08-28 20:07:04,914 - distributed.worker - INFO - Starting Worker plugin /mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/workflows/python_examples.py4ad2f3d2-11c9-478a-ab4e-bf2f7b650b16
20:57:19.074 | INFO    | workflow - [tcp://10.26.37.127:38739] 2026-08-28 20:07:04,914 - distributed.worker - INFO - Starting Worker plugin /mnt/efs/fs1/save/jason.ducker/Cloud-Sandbox_OWP/cloudflow/workflows/python_examples.py4ad2f3d2-11c9-478a-ab4e-bf2f7b650b16
 2026-08-28 20:57:19,074  INFO - tasks.python_dask_experiment_run | [tcp://10.26.37.127:38739] 2026-08-28 20:07:02,970 - distributed.worker - INFO - -------------------------------------------------
20:57:19.074 | INFO    | workflow - [tcp://10.26.37.127:38739] 2026-08-28 20:07:02,970 - distributed.worker - INFO - -------------------------------------------------
 2026-08-28 20:57:19,075  INFO - tasks.python_dask_experiment_run | [tcp://10.26.37.127:38739] 2026-08-28 20:07:02,970 - distributed.worker - INFO -         Registered to:     tcp://10.26.36.77:8786
20:57:19.075 | INFO    | workflow - [tcp://10.26.37.127:38739] 2026-08-28 20:07:02,970 - distributed.worker - INFO -         Registered to:     tcp://10.26.36.77:8786
 2026-08-28 20:57:19,075  INFO - tasks.python_dask_experiment_run | [tcp://10.26.37.127:38739] 2026-08-28 20:07:02,970 - distributed.worker - INFO - Starting Worker plugin shuffle
20:57:19.075 | INFO    | workflow - [tcp://10.26.37.127:38739] 2026-08-28 20:07:02,970 - distributed.worker - INFO - Starting Worker plugin shuffle
 2026-08-28 20:57:19,075  INFO - tasks.python_dask_experiment_run | [tcp://10.26.37.127:38739] 2026-08-28 20:07:02,937 - distributed.worker - INFO - -------------------------------------------------
```

e. **Deprovisioning & Reporting:** Automatically terminates instantiated compute instance upon run completion or failure, releasing resources and reporting actual compute wall-time and final estimated AWS cost.
```bash
20:57:19.097 | INFO    | Task run 'python_dask_experiment_run-fb5' - Finished in state Completed()
 2026-08-28 20:57:19,099  INFO - cluster_tasks.dask_client_close | Terminating local Dask scheduler...
20:57:19.099 | INFO    | workflow - Terminating local Dask scheduler...
 2026-08-28 20:57:19,865  INFO - cluster_tasks.dask_client_close | Dask scheduler terminated gracefully.
20:57:19.865 | INFO    | workflow - Dask scheduler terminated gracefully.
 2026-08-28 20:57:19,865  INFO - cluster_tasks.dask_client_close | Terminating 2 remote Dask worker SSH processes...
20:57:19.865 | INFO    | workflow - Terminating 2 remote Dask worker SSH processes...
 2026-08-28 20:57:19,867  INFO - cluster_tasks.dask_client_close | Remote worker SSH processes signaled to stop.
20:57:19.867 | INFO    | workflow - Remote worker SSH processes signaled to stop.
20:57:19.868 | INFO    | Task run 'dask_client_close-1d3' - Finished in state Completed()
 2026-08-28 20:57:19,872  INFO - AWSCluster.terminate | Terminating instances: [{'instance_id': 'i-0023e349461362893', 'instance_type': 'r7i.xlarge', 'state': 'pending', 'host': '10.26.37.190', 'tags': [{'Key': 'Name', 'Value': 'PYTHON-sparkling-seahorse'}, {'Key': 'Project', 'Value': 'Basic_Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}], 'user': 'jason_ducker', 'start_time': 1787947600.0835288}, {'instance_id': 'i-062197a9de6c15549', 'instance_type': 'r7i.xlarge', 'state': 'pending', 'host': '10.26.37.127', 'tags': [{'Key': 'Name', 'Value': 'PYTHON-sparkling-seahorse'}, {'Key': 'Project', 'Value': 'Basic_Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}], 'user': 'jason_ducker', 'start_time': 1787947600.0835288}]
20:57:19.872 | INFO    | workflow - Terminating instances: [{'instance_id': 'i-0023e349461362893', 'instance_type': 'r7i.xlarge', 'state': 'pending', 'host': '10.26.37.190', 'tags': [{'Key': 'Name', 'Value': 'PYTHON-sparkling-seahorse'}, {'Key': 'Project', 'Value': 'Basic_Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}], 'user': 'jason_ducker', 'start_time': 1787947600.0835288}, {'instance_id': 'i-062197a9de6c15549', 'instance_type': 'r7i.xlarge', 'state': 'pending', 'host': '10.26.37.127', 'tags': [{'Key': 'Name', 'Value': 'PYTHON-sparkling-seahorse'}, {'Key': 'Project', 'Value': 'Basic_Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}], 'user': 'jason_ducker', 'start_time': 1787947600.0835288}]
timelog: PYTHON-sparkling-seahorse: 51 minutes - 2 x r7i.xlarge

===============================================================
  ACTUAL CLUSTER COST  (on-demand, Linux, based on real runtime)
===============================================================
  Cluster name  : PYTHON-sparkling-seahorse
  Instance type : r7i.xlarge
  Node count    : 2
  Elapsed time  : 51 minutes  (0.850 hrs)
  Per-node rate : $0.2646 / hr
  ACTUAL COST   : $0.4498
  NOTE: On-demand rate only; Reserved/Spot pricing will differ.
===============================================================

 2026-08-28 20:57:20,867  INFO - cluster_tasks.cluster_terminate | Responses from terminate: 
20:57:20.867 | INFO    | workflow - Responses from terminate: 
[{'CurrentState': {'Code': 32, 'Name': 'shutting-down'},
  'InstanceId': 'i-0023e349461362893',
  'PreviousState': {'Code': 16, 'Name': 'running'}}]
[{'CurrentState': {'Code': 32, 'Name': 'shutting-down'},
  'InstanceId': 'i-062197a9de6c15549',
  'PreviousState': {'Code': 16, 'Name': 'running'}}]
20:57:20.869 | INFO    | Task run 'cluster_terminate-f5e' - Finished in state Completed()
20:58:05.514 | INFO    | Flow run 'sparkling-seahorse' - Finished in state Completed()
```
**You've succesfully completed your Python dask task parallelism execution using the IOOS Cloud-Sandbox cloudflow method!**
---

## 4. Integrating Custom Arguments into Cloudflow

Follow this procedure to pass custom arguments (e.g., `ARG1`, `ARG2`) to your Python scripts for any of the modes (Basic, MPI, Dask).

### Step 1: Add Arguments to Job Config
```bash
vi ../job.configs/MODEL_EXPERIMENTS/python.experiment
```
```json
{
  "MODEL"   : "PYTHON",
  "JOBTYPE" : "python_experiment",
  "APP"     : "use_case",
  "EXEC"    : "/save/jason.ducker/miniforge3/envs/special_env/bin/python",
  "SCRIPT"  : "./workflows/python_examples.py",
  "ARG1"    : "5",
  "ARG2"    : "John_Doe"
}
```

### Step 2: Register Arguments in Job Class
```bash
vi job/PYTHON_Experiment.py
```
```python
def parseConfig(self, cfDict):
    self.MODEL = cfDict['MODEL']
    self.jobtype = cfDict['JOBTYPE']
    self.APP = cfDict.get('APP', "basic")
    # Register custom argument inputs
    self.ARG1 = cfDict.get('ARG1', None)
    self.ARG2 = cfDict.get('ARG2', None)
```

> **Note:** For Dask jobs, steps 1 & 2 complete the integration of your arguments to leverage for your dask job. For Basic and MPI modes, proceed through steps 3–6 below.

### Step 3: Handle App Mode in Workflow Runner
```bash
vi workflows/tasks.py
```
```python
elif(JOBTYPE=='python_experiment' and APP=='use_case'):
    SCRIPT = job.SCRIPT
    ARG1 = job.ARG1
    ARG2 = job.ARG2
    try:
        result = subprocess.run([runscript, str(JOBTYPE), str(APP), str(NPROCS), str(PPN), HOSTS, str(MODEL_DIR), str(EXEC), str(SCRIPT), str(ARG1), str(ARG2)], universal_newlines=True, stderr=subprocess.STDOUT)
        if result.returncode != 0:
            log.exception(f'PYTHON use case script execution failed ... result: {result.returncode}')
            raise Exception('PYTHON use case script execution failed')
    except Exception as e:
        log.exception('Exception during subprocess.run :' + str(e))
        raise Exception('Exception during subprocess.run')
    log.info('PYTHON use case script execution finished successfully')
```

### Step 4: Parse Environment Variables in Launcher Header
```bash
vi workflows/experiment_launcher.sh
```
```bash
if [[ "$JOBTYPE" == "python_experiment" && "$APP" == "use_case" ]]; then
  export SCRIPT=$8
  export ARG1=$9
  export ARG2="${10}" 
fi
```

### Step 5: Dispatch Script Execution in Launcher Body
```bash
vi workflows/experiment_launcher.sh
```
```bash
elif [[ "$JOBTYPE" == "python_experiment" && "$APP" == "use_case" ]]; then
    export JOBDIR=$PWD/workflows
    cd "$JOBDIR" || exit 1
    RUNSCRIPT="./python_use_case_run.sh $SCRIPT $EXEC $ARG1 $ARG2"
    $RUNSCRIPT 
    result=$?
```

### Step 6: Update Runner Execution Shell Script
```bash
cp workflows/python_basic_run.sh workflows/python_use_case_run.sh
vi workflows/python_use_case_run.sh
```
```bash
export SCRIPT=$1
export EXEC=$2
export ARG1=$3
export ARG2=$4

ssh ec2-user@$HOSTS "cd $CLOUDFLOW_DIR && env && pwd && $EXEC -m py_compile $SCRIPT $ARG1 $ARG2 && $EXEC -u $SCRIPT $ARG1 $ARG2"
```
