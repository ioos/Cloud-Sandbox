#!/usr/bin/env bash

mkdir /tmp/slurminstall
cd /tmp/slurminstall

# 1. Make sure the clocks, users and groups (UIDs and GIDs) are synchronized across the cluster.

# 2. Install MUNGE for authentication. Make sure that all nodes in your cluster have the same munge.key. Make sure the MUNGE daemon, munged, is started before you start the Slurm daemons.

wget https://ioos-cloud-sandbox.s3.amazonaws.com/public/libs/munge-0.5.14-rpms.tgz
tar -xzvf munge-0.5.14-rpms.tgz

# April 12, 2022 current version
#wget https://download.schedmd.com/slurm/slurm-21.08.6.tar.bz2
#rpmbuild -ta slurm*.tar.bz2

wget https://ioos-cloud-sandbox.s3.amazonaws.com/public/libs/slurm-20.11.5-rpms.tgz

# rpm --install <the rpm files>

# 4. Install the configuration file in <sysconfdir>/slurm.conf.
# NOTE: You will need to install this configuration file on all nodes of the cluster.

# 5. systemd (optional): enable the appropriate services on each system:
#
# Controller: systemctl enable slurmctld
# Database: systemctl enable slurmdbd
# Compute Nodes: systemctl enable slurmd

# 6. Start the slurmctld and slurmd daemons.
