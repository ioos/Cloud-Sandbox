# Skills Image Generator

This is a packer build. Once your AWS profile is configured, you can do these commands

```
packer init .
packer build .
```

There is a DOTenvrc file in this directory for `direnv` in case you need to understand the variables involved.


# Notes

It appears that FIPS on the bastion creates issues for non-FIPS-created keys

If this process is to be repeated, it would be better if everyone ensured that they 
had a FIPS-compliant RSA key.  ED-25519 keys appear incompatible with the bastion.


The machine has 200Gb of disk in total, and the instance profile of the head node so there's very little it cannot accomplish within the account.

If different or more storage is required, then knowing what that is before anyone carries along too far in their work would be important.

Very few packages are installed beyond the basics for the OS and git.




After login in, the user will need to:


```
source activate base
conda activate ofs_dps
```
