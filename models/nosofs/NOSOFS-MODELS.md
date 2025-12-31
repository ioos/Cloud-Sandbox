# Install the NOS OFS ROMS and FVCOM models

Log into the sandbox using SSH and providing your SSL private key. <br>

For example: `ssh -i my-sandbox.pem centos@ec2-3-219-217-151.compute-1.amazonaws`

### Obtaian the NOSOFS 3.5 Source Code
https://github.com/asascience/2022-NOS-Code-Delivery-to-NCO

```
cd /save/<your personal work folder>
git clone -b ioos-cloud https://github.com/asascience/2022-NOS-Code-Delivery-to-NCO nosofs-NCO
cd nosofs-NCO/sorc

### To build everything
./ROMS_COMPILE.sh
./FVCOM_COMPILE.sh
```
The build scripts can be modified to only build specific models.

### Obtain the Fixed Field Files
These files are too large to easily store on github and need to be obtained elsewhere.
You can run the below script to download all of the fixed field files from the IOOS-cloud-sandbox S3 bucket.
Edit the script to only download a subset.
```
Example:
mkdir -p /save/ioos/<username>/nosofs-NCO/fix
cd /save/ioos/username/nosofs-NCO/fix
/save/ioos/<username>/Cloud-Sandbox/cloudflow/workflows/scripts/get_fixfiles_s3.sh
```

### Run the following commands

```
cd /save/ioos/<username>/Cloud-Sandbox/cloudflow
python3 -m pip install --user -r requirements.txt
```

### Directory structure
    .
    ├── cloudflow            Python3 cloudflow sources
    │   ├── cluster          Cluster abstract base class and implementations 
    │   │   └── configs      cluster configuration files (JSON)
    │   ├── job              Job abstract base class and implementations
    │   │   ├── jobs         job configuration files (JSON)
    │   │   └── templates    Ocean model input namelist templates
    │   ├── notebooks
    │   ├── plotting         plotting and mp4 routines
    │   ├── services         Cloud agnostic interfaces and implementations e.g. S3
    │   ├── tests            Misc. testing. (TODO: add unit testing)
    │   ├── utils            Various utility functions, e.g. getTiling(totalCores), ndate(), etc.
    │   └── workflows        Workflows and workflow tasks
    │       └── scripts      BASH scripts for various tasks
    ├── docs                 Documentation
    ├── terraform    
    └── README.md

### Setup the machine configuration files for the forecast and/or post processing

Update the configuration files to match your particular cloud configuration. These correspond to the machine configuration used for the forecast and post processing flows.

Edit the following file: `./Cloud-Sandbox/cloudflow/cluster/configs/ioos.config`

| Key | Description |
| --- | ----- |
| platform | the cloud provider being used. Current options are "AWS" or "Local" (runs on local machine) |
| region | the AWS region to create your resources in |
| nodeType | EC2 instance type to run the model on |
| nodeCount | number of EC2 nodes to run model on |
| tags | the tags to add to these resources, used for tracking usage |
| image_id | the AMI ID that you got from setup.log |
| key_name | the PEM key specified in mysettings.tfvars |
| sg_ids | the [security groups](https://console.aws.amazon.com/ec2/#securityGroups) created by Terraform |
| subnet_id | the [subnet](https://console.aws.amazon.com/vpc/#subnets) created by Terraform |
| placement_group | the [placement group](https://console.aws.amazon.com/ec2/#PlacementGroups) created by Terraform. If multiple nodes are specified, all nodes will run in close proximity to each other. |

**Example**
```
{
"platform"  : "AWS",
"region"    : "us-east-2",
"nodeType"  : "c5.xlarge",
"nodeCount" : 2,
"tags"      : [ 
                { "Key": "Name", "Value": "IOOS-cloud-sandbox" },
                { "Key": "Project", "Value": "IOOS-cloud-sandbox" },
                { "Key": "NAME", "Value": "cbofs-fcst" }
              ],
"image_id"  : "ami-0c999999999999999",
"key_name"  : "your-pem-key",
"sg_ids"    : ["sg-00000000000000123", "sg-00000000000000345", "sg-00000000000000678"],
"subnet_id" : "subnet-09abc999999999999",
"placement_group" : "your-cluster-placement-group"
}
```
Copy the same values over for the post-processing. The nodeType and nodeCount may be different, but the other values should be the same.

Edit this file: `./Cloud-Sandbox/cloudflow/cluster/configs/post.config`

The above machine configuration files are specified in the workflow_main.py script. Feel free to rename them to whatever you want.

```
fcstconf = f'{curdir}/../cluster/configs/ioos.config'
postconf = f'{curdir}/../cluster/configs/post.config'
```

### Setup the job configuration files

These files contain parameters for running the models. These are provided as command line arguments to workflow_main.py.

Example:

`./Cloud-Sandbox/cloudflow/job/jobs/cbofs.00z.fcst` (forecast)

`./Cloud-Sandbox/cloudflow/job/jobs/cbofs.00z.plots` (plots)

The variables are described below:

| Variable | Description |
| -------- | ----------- |
| JOBTYPE  | current options are "forecast" and "plotting" |
| OFS       | name of the forecast. Current options are "cbofs", "dbofs", "liveocean" |
| CDATE     | run date, format YYYYMMDD or "today" = today's date |
| HH        | forecast cycle, e.g. 06 for 06z forecast cycle |
| COMROT    | common root path where output will be |
| EXEC      | not currently used |
| TIME_REF  | reference time of the tidal forcing data being used |
| BUCKET    | cloud storage bucket where output will be stored |
| BCKTFLDR  | cloud storage folder, key prefix |
| NTIMES    | number of timesteps to run this forecast |
| ININAME   | currently only used for liveocean, the path/name of the INI/restart file to use |
| OUTDIR    | model output directory. "auto" = automatically set this, based on CDATE, etc. |
| OCEANIN   | name of the ocean.in file to use. "auto" = automatically create this based on a template |
| OCNINTMPL | template ocean.in file to use |

**Example**
```
{
  "JOBTYPE"   : "romsforecast",
  "OFS"       : "cbofs",
  "CDATE"     : "today",
  "HH"        : "00",
  "COMROT"    : "/com/nos",
  "EXEC"      : "",
  "TIME_REF"  : "20160101.0d0",
  "BUCKET"    : "ioos-cloud-sandbox",
  "BCKTFLDR"  : "/nos/cbofs/output",
  "NTIMES"    : "34560",
  "ININAME"   : "",
  "OUTDIR"    : "auto",
  "OCEANIN"   : "auto",
  "OCNINTMPL" : "auto"
}
```


### Run the Job

The main entry point is: `./Cloud-Sandbox/cloudflow/workflows/workflow_main.py`

The job should be run from the cloudflow directory. To capture output, create an empty file first. Multiple jobs may be specified.
To submit the job(s) and to optionally log to an output file and run as a background process:

```
cd ./Cloud-Sandbox/cloudflow
touch /tmp/workflowlog.txt
./workflows/workflow_main.py job/jobs/yourjob1 [job/jobs/yourjob2] 2>&1 /tmp/workflowlog.txt &
```
Note: *job2 will only run if job1 finishes without error.*

Cloud resources will be provisioned for you based on the configuration files modified earlier. The cloud resources will be automatically terminated when each flow ends, whether successfully or not.

The default output directory for NOSOFS is `/ptmp` while the forecast job is running. Results are copied to `/com` when the job is complete.

### Additional Customization

- To customize the flows see `flows.py`
- To add any additional tasks, see `workflow_tasks.py`
- To add additional Job functionality or define new Job types, see the classes in the `./job folder`.
- To add additional Cluster functionality or define new Cluster implementations, see the classes in the `./cluster folder`.
- See the `./plotting folder` for plotting jobs.

*Copyright © 2023 RPS Group, Inc. All rights reserved.*
