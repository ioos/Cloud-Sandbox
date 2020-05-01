# Cloud-Sandbox

## CloudFlow API Specification
https://asascience.github.io/Cloud-Sandbox

### Directory structure

    .
    ├── cloudflow            Python3 cloudflow sources
    │   ├── cluster          Cluster abstract base class and implementations 
    │   │   └── configs      cluster configuration files (JSON)
    │   ├── job              Job abstract base class and implementations
    │   │   ├── jobs         job configuration files (JSON)
    │   │   └── templates    Ocean model input namelist templates
    │   ├── plotting         plotting and mp4 routines
    │   ├── services         Cloud agnostic interfaces and implementations e.g. S3
    │   ├── tests            Misc. testing. (TODO: add unit testing)
    │   ├── utils            Various utility functions, e.g. getTiling(totalCores), ndate(), etc.
    │   └── workflows        Workflows and workflow tasks
    │       └── scripts      BASH scripts for various tasks
    ├── docs                 Documentation
    └── README.md

### Workflows

How to setup the workflows:

1. Setup the machine configuration files for the forecast and/or post processing.

See: workflow_main.py - This is the main entry point. 

There are two configuration files that need to be specified. These should be changed for your particular cloud configuration. These correspond to the machine configuration used for the forecast and post processing flows.

Examples:

fcstconf = f'{curdir}/../configs/cbofs.config'

postconf = f'{curdir}/../configs/post.config'

2. Setup the job configuration files. 

These are provided as command line arguments to workflow_main.py or a copy of it.

For examples:

See:

 jobs/cbofs.00z.fcst (forecast)

 and

 jobs/cbofs.00z.plots (plots)

To submit the job(s) (and to optionally log to an output file and run as a background process):

./workflow_main.py jobs/yourjob1 [jobs/yourjob2] 2>&1 someoutfile &

Note: job2 will only run if job1 finishes without error.

If using the cloud, cloud resources will be provisioned for you, based on the configuration files specified in step 1. The cloud resources will be automatically terminated when each flow ends, whether successfully or not.

To customize the flows see: flows.py
To add any additional tasks, see: workflow_tasks.py

To add additional Job functionality or define new Job types:
  See the classes in the ./job folder.

To add additional Cluster functionality or define new Cluster implementations:
  See the classes in the ./cluster folder.

See the ./plotting folder for plotting jobs.

```
Example: configs/cbofs.config
{
"platform"  : "AWS",
"region"    : "us-east-1",
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

```
Description of variables for cluster:
platform  - The cloud provider being used? Current options are AWS or Local (runs on local machine).
region    - The AWS region to create your resources in.
nodeType  - EC2 instance type.
nodeCount - # of instances to provision.
tags      - The tags to add to these resources, used for tracking usage.
image_id  - For AWS, the AMI id to use for each instance.
key_name  - The private key file to use to ssh into the instances.
sg_ids    - The AWS security groups to use.
subnet_id - The subnet id to launch in.
placement_group - The cluster placement group. If multiple nodes are specified, all nodes will run in close proximity to each other.
```

```
Example: jobs/cbofs.00z.fcst
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

```
Description of variables for jobs
JOBTYPE   - current options are "forecast" and "plotting"
OFS       - name of the forecast. Current options are "cbofs", "dbofs", "liveocean"
CDATE     - run date, format YYYYMMDD or "today" = today's date
HH        - forecast cycle, e.g. 06 for 06z forecast cycle.
COMROT    - common root path where output will be
EXEC      - not currently used
TIME_REF  - reference time of the tidal forcing data being used
BUCKET    - cloud storage bucket where output will be stored
BCKTFLDR  - cloud storage folder, key prefix
NTIMES    - number of timesteps to run this forecast
ININAME   - currently only used for liveocean, the path/name of the INI/restart file to use.
OUTDIR    - model output directory. "auto" = automatically set this, based on CDATE, etc.
OCEANIN   - name of the ocean.in file to use. "auto" = automatically create this based on a template.
OCNINTMPL - template ocean.in file to use.
```
Copyright © 2020 RPS Group, Inc. All rights reserved.