
module purge

export TARGETMX=${TARGETMX:-x86_64}
export MODULEFILE=${MODULEFILE:-intel_x86_64}


if [[ $TARGETMX == "x86_64" ]]; then

  echo "Loading module $MODULEFILE for target: $TARGETMX"
  module load intel_x86_64

elif [[ $TARGETMX == "skylake_avx512" ]]; then

  # don't set NO_AVX512 - make uses ifdef - default is to use
  # outdated
  echo "module list needs to be updated for $TARGETMX"
  module avail
  exit

elif [[ $TARGETMX == "haswell" ]]; then
  export NO_AVX512=on
  module avail
  echo "target haswell not supported yet"
  exit

else
  echo "Target platform not supported"
  exit
fi
