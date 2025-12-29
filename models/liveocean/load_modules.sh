
module purge

TARGETMX=${TARGETMX:-x86_64}

if [[ $TARGETMX == "skylake_avx512" ]]; then

  # don't set NO_AVX512 - make uses ifdef - default is to use

  # outdated
  echo "module list needs to be updated for $TARGETMX"
  module avail
  exit
  # module load gcc-8.5.0-gcc-4.8.5-iakdnjp
  # module load intel-oneapi-compilers-2021.3.0-gcc-8.5.0-gp3iweu
  # module load intel-oneapi-mpi-2021.3.0-intel-2021.3.0-bixgqcx
  # module load zlib-1.2.11-intel-2021.3.0-gcfkvht
  # module load libszip-2.1.1-intel-2021.3.0-pzpdymm
  # module load netcdf-c-4.8.0-intel-2021.3.0-pejnxdb
  # module load netcdf-fortran-4.5.4-intel-2021.3.0-4lyzqsf
  # module load hdf5-1.10.7-intel-2021.3.0-btc4zhc

elif [[ $TARGETMX == "haswell" ]]; then
  export NO_AVX512=on
  module avail
  echo "target haswell not supported yet"
  exit
elif [[ $TARGETMX == "x86_64" ]]; then
  
  export NO_AVX512=on
 
# PT HERE - update this 
  module load intel-oneapi-compilers/2023.1.0-gcc-11.2.1-3a7dxu3
  module load intel-oneapi-mpi/2021.9.0-intel-2021.9.0-egjrbfg
  module load zlib-ng/2.1.4-intel-2021.9.0-57ptxrw
  module load libszip/2.1.1-intel-2021.9.0-s3p3pgl
  module load hdf5/1.14.3-intel-2021.9.0-4xskthb
  module load netcdf-fortran/4.6.1-intel-2021.9.0-meeveoj
  module load netcdf-c/4.9.2-intel-2021.9.0-vznmeik 

# PT HERE - fix this
  ## HACK HERE WITH SPACK - use 'module show <netcdf module above>' to get the full path
  NETCDF="/mnt/efs/fs1/save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-fortran-4.6.1-meeveojv5q6onmj6kitfb2mwfqscavn6"

  NETCDFC="/mnt/efs/fs1/save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-c-4.9.2-vznmeikm7cp5ht2ktorgf2ehhzgvqqel"

  export LD_LIBRARY_PATH="$NETCDF/lib:$LD_LIBRARY_PATH"
  export LD_LIBRARY_PATH="$NETCDFC/lib:$LD_LIBRARY_PATH"

  export NETCDF_INCDIR="$NETCDF/include"
else
  echo "Target platform not supported"
  exit
fi
