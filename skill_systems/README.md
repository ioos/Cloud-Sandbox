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