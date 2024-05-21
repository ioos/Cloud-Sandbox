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

#### Example add all new and modified files and commit
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
cd /save/ec2-user/Cloud-Sandbox/models/adcirc-cora || exit 1
./getS3packages.sh
```

### Run the sandbox patch
```
cd /save/ec2-user/Cloud-Sandbox/patches/adcirc-cora || exit 1
./fix4cora.sh
```






