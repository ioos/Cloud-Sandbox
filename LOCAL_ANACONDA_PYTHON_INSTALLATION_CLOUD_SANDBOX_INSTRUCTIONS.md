# Installing Anaconda environment for local ec2-user on ioos Cloud-Sandbox 

## Setup 

You need to create a unique directory to install your local version of conda, and thus, python.

### Change Directory to Your Affiliation
```bash
cd /save/ec2-user/Affiliation
```
Replace `Affiliation` above with your working group.

### Create Your Personal Installation Directory

```bash
mkdir FirstName_LastName_Anaconda_Installation; 
```
Replace the `FirstName` and `LastName` above with your first and last name.

### Change To Your Personal Installation Directory
```bash
cd FirstName_LastName_Anaconda_Installation
export WORKINGDIR=$(pwd)
```
> [!IMPORTANT]
> Do not log out after this step!  The `WORKINGDIR` environment variable is used
in later steps.  If, for some reason, you do log out or your shell gets killed, just change to your affiliation directory and then repeat the steps in this section.

## Install Conda and Libraries

> [!WARNING]
> The following script takes quite a while to run (approximately 85 minutes).  You need to make sure that you don't get logged off during the execution.

```bash
# ~1-2 minutes
wget --no-verbose https://repo.continuum.io/archive/Anaconda3-2024.10-1-Linux-x86_64.sh
# ~45 minutes
time bash ./Anaconda3-2024.10-1-Linux-x86_64.sh -b -p ${WORKINGDIR}/anaconda3
cd ${WORKINGDIR}/anaconda3/bin
# ~ 3 minutes
./conda update -n base -c main conda
# ~2 minutes
./conda install -n base libarchive -c main --force-reinstall --solver classic
# 
./conda update --all --solver=classic
./conda install -c conda-forge pip boto3 prefect=0.15.13 dask distributed Pillow matplotlib netCDF4 numpy pyproj haikunator

echo "Your python3 executable is:\n\t ${WORKINGDIR}/anaconda3/bin/python3"
```

## Done

You are now all done and ready to go as a ec2-user with their own seperate Python installation to utilize!
