#!/usr/bin/env bash

mkdir /tmp/slurminstall
cd /tmp/slurminstall

# /save/environments/spack/share/spack/setup-env.sh
SPACK_DIR='/save/environments/spack'
. $SPACK_DIR/share/spack/setup-env.sh

# source /save/environments/spack/share/spack/setup-env.csh
# 1. Make sure the clocks, users and groups (UIDs and GIDs) are synchronized across the cluster.

# 2. Install MUNGE for authentication. Make sure that all nodes in your cluster have the same munge.key. Make sure the MUNGE daemon, munged, is started before you start the Slurm daemons.

# https://github.com/dun/munge/wiki/Installation-Guide

sudo yum -y install libtool
sudo yum -y install bzip2-devel

wget https://ioos-cloud-sandbox.s3.amazonaws.com/public/libs/munge-0.5.14-rpms.tgz
tar -xzvf munge-0.5.14-rpms.tgz
sudo yum -y localinstall munge-0.5.14-2.el7.x86_64.rpm munge-libs-0.5.14-2.el7.x86_64.rpm munge-devel-0.5.14-2.el7.x86_64.rpm

# TODO - create munge user
# Create key
#sudo -u munge ${sbindir}/mungekey --verbose
sudo /usr/sbin/mungekey --verbose

# 3. Install SLURM

# April 12, 2022 current version
sudo yum -y install readline-devel
sudo yum -y install pam-devel
sudo yum -y install perl-ExtUtils-MakeMaker

spack load gcc@8.5.0
#spack load hdf5
#module load hdf5-1.10.7-intel-2021.3.0-qfvg7gc

#wget https://download.schedmd.com/slurm/slurm-21.08.6.tar.bz2
#rpmbuild -ta slurm*.tar.bz2

wget https://ioos-cloud-sandbox.s3.amazonaws.com/public/libs/slurm-20.11.5-rpms.tgz
tar -xzvf slurm-20.11.5-rpms.tgz

#sudo yum install perl-Switch
sudo yum -y localinstall slurm*.rpm

#sudo /mnt/efs/fs1/save/downloads/slurm-20.11.5/libtool --finish /usr/lib64

# 4. Install the configuration file in <sysconfdir>/slurm.conf.
# NOTE: You will need to install this configuration file on all nodes of the cluster.

# 5. systemd (optional): enable the appropriate services on each system:
#
# Controller: systemctl enable slurmctld
# Database: systemctl enable slurmdbd
# Compute Nodes: systemctl enable slurmd

# 6. Start the slurmctld and slurmd daemons.
