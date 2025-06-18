#!/usr/bin/env bash
set -euo pipefail

SAVEDIR=${1:-"/save/$USER/"}
if [ ! -d $SAVEDIR ]; then
    mkdir -p $SAVEDIR | echo "Can not create $SAVEDIR"; exit 1
fi

CURHOME=$PWD
CSHOME="${PWD%/*/*}"
echo "Cloud Sandbox root directory is: $CSHOME"

REPO="https://github.com/asascience/2022-NOS-Code-Delivery-to-NCO"
BRANCH="ioos-cloud"
SAVEPATH='nosofs-3.5.0'

cd $SAVEDIR
echo "Obtaining the source code, cloning the repository ... "
echo "git clone -b $BRANCH $REPO $SAVEPATH"
#git clone -b ioos-cloud https://github.com/asascience/2022-NOS-Code-Delivery-to-NCO nosofs-3.5.0
#git clone -b $BRANCH $REPO $SAVEPATH
cd $SAVEPATH/sorc
cp $CURHOME/intel_x86_64 $SAVEDIR/$SAVEPATH/modulefiles

echo "Building everything ... "
echo "The build scripts can be modified to only build specific models."
#./ROMS_COMPILE.sh
./FVCOM_COMPILE.sh

# Obtain the fixed field files (too large for gitHub)
mkdir -p $SAVEDIR/$SAVEPATH/fix
cd $SAVEDIR/$SAVEPATH/fix

### Obtain the Fixed Field Files
# These files are too large to easily store on github and need to be obtained elsewhere.
# You can run the below script to download all of the fixed field files from the IOOS-cloud-sandbox S3 bucket.
# Edit the script to only download a subset.
# This is already in the nosofs repo
## $CURHOME/get_fixfiles_s3.sh

bash get_fixfiles_s3.sh

