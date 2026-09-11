# Cloudflow Model Execution Instructions

This guide provides step-by-step instructions for staging, configuring, and executing coastal model runs (such as SCHISM as demonstrated in this example) on an `ioos/Cloud-Sandbox` head node using Cloudflow and Prefect.

---

## 1. Stage Your Model Files to S3

Before starting work on a Cloud-Sandbox head node, upload your local model setup to the public `ioos-transfers` S3 bucket.

From your local machine:
```bash
aws s3 cp /pathway/to/your/model/setup s3://ioos-transfers/your_model_setup --recursive
```

---

## 2. Head Node Setup & Environment Configuration

Log into your assigned head node and prepare your user workspace on the shared EFS volume (`/save`).

### Create Workspace and Pull Staged Model Setup
```bash
cd /save
mkdir -p jason.ducker
cd jason.ducker

# Pull your model setup down from S3
aws s3 cp s3://ioos-transfers/your_model_setup ./your_model_setup --recursive

# Clone the Cloud-Sandbox repository
git clone https://github.com/ioos/Cloud-Sandbox.git
```

> **Note:** If you do not have a working Python environment set up for Cloudflow, follow the **Python Miniforge3 Installation** directives on the main [Cloud-Sandbox Repository]([https://github.com/ioos/Cloud-Sandbox.git](https://github.com/ioos/Cloud-Sandbox/blob/main/LOCAL_PYTHON_MINIFORGE3_INSTALLATION_CLOUD_SANDBOX_INSTRUCTIONS.md)).

---

## 3. Module Environment & Model Compilation

Load the necessary compiler and library modules available on the head node via Spack to compile your model (SCHISM shown as an example).

```bash
# View available environment modules
module avail

# Load required compiler and library modules
module load intel-oneapi-compilers/2024.2.1-none-none-r2buaru
module load intel-oneapi-mpi/2021.13-none-none-hesoai3
module load netcdf-fortran/4.6.2-intel-oneapi-compilers/2024.2.1-qf6u5b4

# Export compiler wrappers
export CC=mpiicx
export CXX=mpiicpx
export FC=mpiifx
```

---

## 4. Cloudflow Execution Setup

Navigate to the Cloudflow package directory and bind your custom Python environment.

```bash
cd /save/jason.ducker/Cloud-Sandbox/cloudflow/

# Update the hashbang line in workflow_main.py to point to your Python executable
sed -i 's|#!/usr/bin/env -S python3 -u|#!/usr/bin/env /save/jason.ducker/miniforge3/envs/cloudflow/bin/python|' workflows/workflow_main.py
```

### Configure Model Job Specifications
Edit or create your target model job configuration file. Pre-configured templates (ADCIRC, FVCOM, ROMS, SCHISM, D-Flow FM) reside in `Cloud-Sandbox/cloudflow/job.configs/MODEL_EXPERIMENTS/`.

```bash
vi ../job.configs/MODEL_EXPERIMENTS/schism.experiment
```

```json
{
  "MODEL"     : "SCHISM",
  "JOBTYPE"   : "schism_experiment",
  "APP"       : "basic",
  "EXEC"      : "/save/ec2-user/OWP/schism_jerome_hpc7a/build/bin/pschism_TVD-VL",
  "MODEL_DIR" : "/save/ec2-user/OWP/laura",
  "NSCRIBES"  : "4"
}
```

* **`MODEL`**: Target model framework class.
* **`JOBTYPE`**: Type of job (`schism_experiment`).
* **`APP`**: Application execution mode (`basic`).
* **`EXEC`**: Absolute pathway to the pre-compiled executable on the head node.
* **`MODEL_DIR`**: Directory where model input files are staged.
* **`NSCRIBES`**: (SCHISM-specific) Number of dedicated I/O core processes.

### Configure AWS Cluster Infrastructure
Define the cloud resources requested for this run.

```bash
vi ../cluster.configs/Experiments/schism.ioos
```

```json
{
  "platform"        : "AWS",
  "region"          : "us-east-2",
  "nodeType"        : "hpc6a.48xlarge",
  "nodeCount"       : 1,
  "vm_retry_delay"  : 300,
  "vm_max_retries"  : 5,
  "tags"            : [
                        { "Key": "Name", "Value": "SCHISM" },
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

* **`platform`**: Cloud provider target (`AWS`).
* **`region`**: AWS region hosting current Cloud-Sandbox resources (`us-east-2`).
* **`nodeType`**: Requested AWS EC2 instance type for computation.
* **`nodeCount`**: Total number of compute nodes requested for the run.
* **`vm_retry_delay`**: Time delay in seconds between queries when requesting AWS resources.
* **`vm_max_retries`**: Maximum number of retry attempts to acquire AWS resources.
* **`tags`**: Key-value pairs for resource tracking and Prefect job ID assignment.
* **`image_id`**: AMI ID used for compute nodes (must match the exact AMI of your head node).
* **`key_name`**: SSH key pair name configured for the AWS account.
* **`sg_ids`**: List of security group IDs governing network permissions.
* **`subnet_id`**: Target AWS subnet ID for node deployment.
* **`placement_group`**: Data center placement group ensuring low-latency networking.
* **`table_name`**: AWS DynamoDB table name tracking job specifications and telemetry.

---

> **Important:** Ensure `image_id` matches the exact AMI associated with your running head node so compute nodes mount identical environments. If you're still having issues launching the job, you may need to include an extra security group id for the EFS volume mounted on the head node your'e on. Besides that, you only need to worry about changing `nodeType`, `nodeCount`, and `tags` if desired. 

---

## 5. Prefect Workflow Server & Execution

Cloudflow uses Prefect as its orchestration engine.

### Check or Start Prefect Server
Check if a local Prefect server instance is running:

```bash
if curl -s --connect-timeout 2 http://127.0.0.1:4200/api/health > /dev/null; then
    echo "Prefect server is RUNNING and available."
else
    echo "No active Prefect server detected."
fi
```

If no active server is detected, start and configure it:

```bash
/save/jason.ducker/miniforge3/envs/cloudflow/bin/prefect server start --background
/save/jason.ducker/miniforge3/envs/cloudflow/bin/prefect config set PREFECT_API_URL=http://127.0.0.1:4200/api
```

### Submit and Monitor the Job
Launch the Cloudflow workflow in the background and follow the execution logs:

```bash
nohup ./workflows/workflow_main.py ../cluster.configs/Experiments/schism.ioos ../job.configs/MODEL_EXPERIMENTS/schism.experiment > cloudflow_test.out &

# Stream live output
tail -f cloudflow_test.out
```

---

## 6. Execution Lifecycle Overview

When launched, the Cloudflow pipeline executes the following stages automatically:

1. **Resource Allocation:** Generates a dynamic cluster name (e.g., `SCHISM-prehistoric-caiman`), queries AWS for requested EC2 compute instances, logs telemetry to DynamoDB, and calculates initial cost projections.
```bash
18:01:51.100 | INFO    | Flow run 'prehistoric-caiman' - Beginning flow run 'prehistoric-caiman' for flow 'experiment-flow'
18:01:51.108 | INFO    | Flow run 'prehistoric-caiman' - View at http://127.0.0.1:4200/runs/flow-run/df676663-5b1d-4f54-b527-98237ebcc09f
 2026-08-17 18:01:51,135  INFO - ClusterFactory.cluster | Attempting to make a new cluster : AWS
18:01:51.135 | INFO    | workflow - Attempting to make a new cluster : AWS
 2026-08-17 18:01:51,137  INFO - AWSCluster.memorable_tags | Your cluster Name: SCHISM-prehistoric-caiman
18:01:51.137 | INFO    | workflow - Your cluster Name: SCHISM-prehistoric-caiman
 2026-08-17 18:01:53,433  INFO - AWSCluster.__init__ | nodeCount: 1  PPN: 96
18:01:53.433 | INFO    | workflow - nodeCount: 1  PPN: 96
 2026-08-17 18:01:53,434  INFO - ClusterFactory.cluster | Created new AWS cluster
18:01:53.434 | INFO    | workflow - Created new AWS cluster
18:01:53.435 | INFO    | Task run 'cluster_init-02e' - Finished in state Completed()
18:01:53.442 | INFO    | Task run 'job_init-cbe' - Finished in state Completed()
 2026-08-17 18:01:53,445  INFO - cluster_tasks.cluster_start | Starting 1 instances ...
18:01:53.445 | INFO    | workflow - Starting 1 instances ...
 2026-08-17 18:01:53,445  INFO - cluster_tasks.cluster_start | Waiting for nodes to start ...
18:01:53.445 | INFO    | workflow - Waiting for nodes to start ...
 2026-08-17 18:01:53,631  INFO - AWSCluster._estimate_and_print_cost | Cost estimate – 1x hpc6a.48xlarge @ us-east-2: $2.8800/hr  |  $69.12/day
18:01:53.631 | INFO    | workflow - Cost estimate – 1x hpc6a.48xlarge @ us-east-2: $2.8800/hr  |  $69.12/day
```

2. **Node Initialization:** Waits for requested instances to enter a running state and initializes environment mounts.
```bash
2026-08-17 18:01:56,766  INFO - AWSCluster.start | AWS resources have been allocated for cloudflow job. Waiting for nodes to enter running state ...
18:01:56.766 | INFO    | workflow - AWS resources have been allocated for cloudflow job. Waiting for nodes to enter running state ...
 2026-08-17 18:01:56,798  INFO - AWSCluster.__put_instance_records | DB_table output for head node based on instance id i-0466f56b8b2e7329d: {'instance-id': 'i-0466f56b8b2e7329d', 'name-tag': 'SCHISM-prehistoric-caiman', 'instance-type': 'hpc6a.48xlarge', 'start-time': 1786989716, 'human-time': '2026-08-17 18:01 UTC', 'minutes-max': 120, 'username': 'jason_ducker'}
18:01:56.798 | INFO    | workflow - DB_table output for head node based on instance id i-0466f56b8b2e7329d: {'instance-id': 'i-0466f56b8b2e7329d', 'name-tag': 'SCHISM-prehistoric-caiman', 'instance-type': 'hpc6a.48xlarge', 'start-time': 1786989716, 'human-time': '2026-08-17 18:01 UTC', 'minutes-max': 120, 'username': 'jason_ducker'}
 2026-08-17 18:02:08,459  INFO - AWSCluster.start | Waiting an additional 150 seconds for nodes to fully initialize ...
18:02:08.459 | INFO    | workflow - Waiting an additional 150 seconds for nodes to fully initialize ...
```
3. **Model Execution:** Enters the target directory (`MODEL_DIR`) and executes the binary using MPI over SSH (e.g., `mpiexec -launcher ssh -hosts <IP> -np <CORES> ...`)
```bash
+ echo ------------------------
------------------------
+ echo 'SCHISM model working directory is /save/jason.ducker/hawaii'
SCHISM model working directory is /save/jason.ducker/hawaii
+ echo ------------------------
------------------------
+ cd /save/jason.ducker/hawaii
+ SECONDS=0
+ echo '--- '
--- 
+ echo '--- Running SCHISM -----------------'
--- Running SCHISM -----------------
+ echo ---
---
+ mpiexec -launcher ssh -hosts 10.26.36.96 -np 140 -ppn 70 /save/jason.ducker/schism/build/bin/pschism_BLD_STANDALONE_SH_MEM_COMM_TVD-VL 4
```
4. **Deprovisioning & Reporting:** Automatically terminates instantiated compute instances upon run completion or failure, releasing resources and reporting actual compute wall-time and final estimated AWS cost.

```bash
+ echo 'SCHISM model has succesfully completed on the cloud!'
SCHISM model has succesfully completed on the cloud!
+ duration=54
+ echo 'SCHISM simulation took 0 minutes and 54 seconds elapsed.'
SCHISM simulation took 0 minutes and 54 seconds elapsed.
 2026-08-20 20:54:04,899  INFO - tasks.experiment_run | SCHISM basic model run finished successfully
20:54:04.899 | INFO    | workflow - SCHISM basic model run finished successfully
20:54:04.900 | INFO    | Task run 'experiment_run-651' - Finished in state Completed()
 2026-08-20 20:54:04,904  INFO - AWSCluster.terminate | Terminating instances: [{'instance_id': 'i-0e9e6c30bc929194f', 'instance_type': 'hpc7a.96xlarge', 'state': 'pending', 'host': '10.26.36.96', 'tags': [{'Key': 'Name', 'Value': 'SCHISM-abiding-axolotl'}, {'Key': 'Project', 'Value': 'Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}], 'user': 'jason_ducker', 'start_time': 1787259190.1130044}]
20:54:04.904 | INFO    | workflow - Terminating instances: [{'instance_id': 'i-0e9e6c30bc929194f', 'instance_type': 'hpc7a.96xlarge', 'state': 'pending', 'host': '10.26.36.96', 'tags': [{'Key': 'Name', 'Value': 'SCHISM-abiding-axolotl'}, {'Key': 'Project', 'Value': 'Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}], 'user': 'jason_ducker', 'start_time': 1787259190.1130044}]
 2026-08-20 20:54:05,475  INFO - cluster_tasks.cluster_terminate | Responses from terminate: 
20:54:05.475 | INFO    | workflow - Responses from terminate: 
20:54:05.476 | INFO    | Task run 'cluster_terminate-303' - Finished in state Completed()
20:54:25.990 | INFO    | Flow run 'abiding-axolotl' - Finished in state Completed()
jobtype: schism_experiment

***************************************************************
Your cluster name: SCHISM-abiding-axolotl
***************************************************************

self.tags: [{'Key': 'Name', 'Value': 'SCHISM-abiding-axolotl'}, {'Key': 'Project', 'Value': 'Model_Experiment'}, {'Key': 'ApprovedSubnet', 'Value': 'subnet-00075cfbfcbc8f2cf'}]
in job init
<cloudflow.job.SCHISM_Experiment.SCHISM_Experiment object at 0x148d2f338d70>

===============================================================
  ESTIMATED CLUSTER COST  (on-demand, Linux, no pre-installed SW)
===============================================================
  Instance type : hpc7a.96xlarge
  Region        : us-east-2  (US East (Ohio))
  Node count    : 1
  Per-node rate : $7.2000 / hr
  Cluster cost  : $7.2000 / hr  |  $172.80 / day
  NOTE: Estimate is for on-demand pricing only.
        Actual charges depend on run time and AWS billing.
===============================================================

AWS Insufficent Instance Capacity has been detected, Will attempt to wait {self.vm_retry_delay} seconds at the start. A 10% exponential backoff on the delay time will be implemented over each retry interval. Cloudflow will retry {self.vm_max_retries} times over to see if we can obtain the user requested AWS resources.
Insufficient capacity. Retrying in 300 seconds... (Attempt {retries}/{self.vm_max_retries})
Insufficient capacity. Retrying in 494 seconds... (Attempt {retries}/{self.vm_max_retries})
instance 1 : running
{"instance_id": "i-0e9e6c30bc929194f", "instance_type": "hpc7a.96xlarge", "state": "pending", "host": "10.26.36.96", "tags": [{"Key": "Name", "Value": "SCHISM-abiding-axolotl"}, {"Key": "Project", "Value": "Model_Experiment"}, {"Key": "ApprovedSubnet", "Value": "subnet-00075cfbfcbc8f2cf"}], "user": "jason_ducker", "start_time": 1787259190.1130044}
```


### You've successfully completed your model execution using the IOOS Cloud-Sandbox cloudflow method!

