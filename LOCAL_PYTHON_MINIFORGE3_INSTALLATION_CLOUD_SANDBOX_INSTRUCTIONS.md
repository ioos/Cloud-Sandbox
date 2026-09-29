# Installing miniforge Python package manager for local ec2-user on ioos Cloud-Sandbox 

## Miniforge Setup 

You need to create a unique directory to install your local version of mamba, and thus, python.

### Change Directory to Your Affiliation
```bash
cd /save/ec2-user/Affiliation
```
Replace `Affiliation` above with your working group.

### Create Your Personal Installation Directory

```bash#
mkdir FirstName_LastName_Miniforge_Installation; 
```
Replace the `FirstName` and `LastName` above with your first and last name.

### Change To Your Personal Installation Directory
```bash
cd FirstName_LastName_Miniforge_Installation
export WORKINGDIR=$(pwd)
```
> [!IMPORTANT]
> Do not log out after this step!  The `WORKINGDIR` environment variable is used
in later steps.  If, for some reason, you do log out or your shell gets killed, just change to your affiliation directory and then repeat the steps in this section.

### Install Miniforge3

> The following miniforge3 installation takes approximately 6 minutes to install for a user.

```bash
# ~1-2 seconds
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
# ~6 minutes
time bash Miniforge3-$(uname)-$(uname -m).sh -b -p ${WORKINGDIR}/miniforge3
export MAMBA=$WORKINGDIR/miniforge3/bin/mamba
echo "Your default python3 executable is: ${WORKINGDIR}/miniforge3/bin/python3"
cd ..
```

## Install Cloudflow Compatible Python Environment

> The following cloudflow Python installation takes approximately 13 minutes to install for a user.

```bash
# ~11-12 seconds
git clone https://github.com/ioos/Cloud-Sandbox.git
cd Cloud-Sandbox/cloudflow
# ~13 minutes
time $MAMBA env create -f cloudflow_minforge3_installation.yml -y
echo "Your cloudflow python3 executable is: ${WORKINGDIR}/miniforge3/envs/cloudflow/bin/python3"
```


## Done

You are now all done and ready to go as a ec2-user with their own seperate Python installation to utilize, including a cloudflow compatible Python enviornment!
