# IOOS Cloud-Sandbox

## Getting Started

### Sandbox Installation Instructions
_Create the sandbox in AWS using Terraform_

Terraform will create **all** of the AWS resources needed for the sandbox. 
This includes the VPC, subnet, security groups, EFS networked disk volumes, and others. AWS has a default limit of 5 VPCs per region. You will have to request a quota increase from AWS if you are already at your limit.

Install the AWS CLI: <br>
https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html

Make sure the CLI is configured to use your AWS account: <br>
https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-config

Install the Terraform CLI: <br>
https://www.terraform.io/downloads.html

Run the following command to finish installation: 
```
terraform init
```

Clone this repository: <br>
(e.g. using the default path ./Cloud-Sandbox)
```
git clone https://github.com/ioos/Cloud-Sandbox.git
cd ./Cloud-Sandbox/terraform
```

Terraform requires an existing key-pair to provide SSH access to the instance(s). The public key will be added to the created instance when it is created. Then the private key can be used to login it.

There are multiple ways to provide an acceptable key. You can use an existing key-pair that you have access to, or you can create a new one. I will describe two ways to create a new AWS EC2 key-pair, one using the AWS EC2 Console and the other using the AWS CLI.

**Using the AWS EC2 Console:**

Select "Key Pairs" under "Network & Security", then select "Create key pair" _(see screenshot below)_. **Save this private key someplace safe!** 

![AWS Console](./images/AWS-Key-pairs-screen.png)

**Using the AWS CLI:**

<pre>
aws ec2 create-key-pair --key-name <b><i>your-key-pair</i></b> --query "KeyMaterial" --output text > <b><i>your-key-pair.pem</i></b> 
</pre>
The private key file must have permissions that allows access only to you, e.g. if on Linux 

<pre>
chmod 600 <b><i>your-key-pair.pem</i></b> 
</pre>

**To obtain the public key from the private key:**<br>
_(You will need to cut and paste the key into the public_key variable mentioned below.)_

<pre>
ssh-keygen -y -f <b><i>your-key-pair.pem</i></b> 
</pre>

### Set the required variables for your use:

**_mysettings.tfvars_** - Edit this file to specify custom values to use for the following:

#### These must be defined, no default exists:
allowed_ssh_cidr = "your publicly visible IPv4 address/32" <br>
key_name = "**_your-key-pair_**" <br>
public_key = "**ssh-rsa** &nbsp;&nbsp; your_public_key" <br>
_(must include "ssh-rsa", assuming it is an rsa key)_

**You can get your publicly visible IPv4 address here:** <br> 
https://www.whatismyip.com/ 

#### Optionally change these settings to override the defaults:

| Variable              | Description                                  | Default value                  |
|-----------------------|----------------------------------------------|--------------------------------|
| **preferred_region**  | The AWS region to use                        | "us-east-1"                    |
| **instance_name**     | The "Name" tag for the instance              | "IOOS Cloud Sandbox Terraform" |
| **project_name**      | The "Project" tag for the resources created  | "IOOS-cloud-sandbox"           |
| **availability_zone** | The AWS Availability zone                    | "us-east-1a"                   |
| **instance_type**     | EC2 Instance type to use for setup           | "t3.medium"                 |

Run 'terrform plan' to check for errors and see what resources will be created: 
```
terraform plan -var-file="mysettings.tfvars"
```

Run 'terraform apply' to create the AWS resources.
```
terraform apply -var-file="mysettings.tfvars"
```

Enter 'yes' to create the resources.

### Install all of the required software and libraries
This is done automatically in init_template.tpl <br>
Wait for the setup to complete.


Details about the created instance and how to login will be output.<br>
It takes about 15 minutes for the entire setup to complete.<br>
Wait a few minutes before logging in.

```
Example output:
instance_id = "i-01346de00e778f"
instance_public_dns = "ec2-3-219-217-151.compute-1.amazonaws.com"
instance_public_ip = "3.219.217.151"
login_command = "ssh -i <path-to-key>/my-sandbox.pem centos@ec2-3-219-217-151.compute-1.amazonaws.

```
To watch the progress:
```
ssh -i my-sandbox.pem centos@ec2-3-219-217-151.compute-1.amazonaws
tail -f /tmp/setup.log
```

### Create the AMI 
This is done automatically.
The AMI ID will be found at the end of the log at /tmp/setup.log
It can also be found in the AWS console or via the AWS CLI. This AMI ID will be needed later.

### Install the NOS OFS ROMS and FVCOM models
```
ssh -i <your-key.pem> centos@<your-ec2-instance>
cd /save
git clone https://github.com/ioos/nosofs-NCO.git
cd nosofs-NCO/sorc

# To build everything
./ROMS_COMPILE.sh
./FVCOM_COMPILE.sh
```

### Optional: After setting everything up, you can change the instance type to something smaller:
Edit mysettings.tfvars and change the following:

Example: <br>
instance_type = "t3.micro" <br>

Run terraform apply:
```
terraform apply -var-file="mysettings.tfvars"
```



[//]: # "terraform destroy -target=resource"

### When done using the sandbox all of the AWS resources (including disks) can be destroyed with the following command:
```
terraform destroy -var-file="mysettings.tfvars"
```

### The following document contains some older instructions on building and running the models that is still valid.

### Cloud-Sandbox Setup and User Guide
https://ioos-cloud-sandbox.s3.amazonaws.com/public/IOOS_Cloud_Sandbox_Ref_v1.3.0.docx

### CloudFlow API Specification
https://ioos.github.io/Cloud-Sandbox/

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
Copyright © 2021 RPS Group, Inc. All rights reserved.
