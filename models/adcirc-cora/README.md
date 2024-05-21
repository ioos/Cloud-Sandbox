## CORA ADCIRC Setup

```
cd /save/ec2-user/Cloud-Sandbox
```

### Save your current work
#### See what branch you are on
```
git branch
```

#### Maybe create a new branch
```
git checkout -b new_branch_name
```

#### Commit any changes to your new development branch
```
git status
```

#### Add the files you want to commit

```
git add list of files or folders
```

#### Or, for example add all new and modified files
git add -A

#### Commit your changes
```
git commit -m "your commit message"
```

#### Push your changes to the repository
```
git branch --set-upstream-to=origin/new_branch_name new_branch_name
git push origin new_branch_name
```

### Checkout the cora-adcirc dev branch

Note: You might have made some changes/fixes that have not been added to
the main branch yet. If so, you will need to merge your changes with the cora-test
changes.

```
git checkout main
git pull
git checkout new_branch_name
git pull origin cora-test
```

Otherwise, proceed as follows.

```
git checkout main
git pull
git checkout -t origin/cora-test
```

[ git branch --set-upstream-to=origin/cora-test cora-test]: #

### Download the CORA packages from S3
```
cd /save/ec2-user/Cloud-Sandbox/models/adcirc-cora
./getS3packages.sh
```

### Run the sandbox patch
```
cd /save/ec2-user/Cloud-Sandbox/patches/adcirc-cora
./fix4cora.sh
```

### Launch the test run

#### Setup your config file, using the entries from your current config file.
This test takes about an hour on 1 hpc6a node.
```
cd /save/ec2-user/Cloud-Sandbox/cloudflow/cluster/configs
cp ioos.cora.config noaa.cora.config
vi noaa.cora.config
```

There is nothing that needs to be changed in the job file
```
cd /save/ec2-user/Cloud-Sandbox/cloudflow
cat job/jobs/cora.reanalysis 
```

#### Make sure workflows/workflow_main.py is using the correct cluster .config file.
```
vi workflows/workflow_main.py
```

Look for the following around line 30 and use the config file you have been using, 
setting the type and number of nodes to whatever you want to use.

e.g.
```
fcstconf = f'{curdir}/../cluster/configs/noaa.cora.config'
```

#### Launch it using the workflow main script
```
./workflows/workflow_main.py job/jobs/cora.reanalysis >& job.out &
tail -f job.out
```

The model runs in /save/ec2-user/cora-runs/ADCIRC/ERA5/ec95d/2018

There is an executable in the adcirc work folder that can be used to compare two different runs.
I haven't played with it yet.
```
/save/ec2-user/adcirc/work/adcircResultsComparison --help
```
