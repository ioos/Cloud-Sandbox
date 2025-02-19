
# This is installed in /etc/profile.d by the AWS efa installer

# NO NO NO - overrides any module used for mpifort and mpirun
# PATH="/opt/amazon/efa/bin/:$PATH"
# PATH="/opt/amazon/openmpi/bin/:$PATH"

MODULEPATH="/opt/amazon/modules/modulefiles:$MODULEPATH"
