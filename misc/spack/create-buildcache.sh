#!/usr/bin/env bash


gcc_485_pkgs='autoconf@2.69%gcc@4.8.5         gcc@8.5.0%gcc@4.8.5         libtool@2.4.6%gcc@4.8.5   perl@5.34.0%gcc@4.8.5 
              automake@1.16.3%gcc@4.8.5       gdbm@1.19%gcc@4.8.5         m4@1.4.19%gcc@4.8.5       pkgconf@1.8.0%gcc@4.8.5 
              berkeley-db@18.1.40%gcc@4.8.5   gmp@6.2.1%gcc@4.8.5         mpc@1.1.0%gcc@4.8.5       readline@8.1%gcc@4.8.5 
              bzip2@1.0.8%gcc@4.8.5           libiconv@1.16%gcc@4.8.5     mpfr@3.1.6%gcc@4.8.5      zlib@1.2.11%gcc@4.8.5 
              diffutils@3.8%gcc@4.8.5         libsigsegv@2.13%gcc@4.8.5   ncurses@6.2%gcc@4.8.5'

gcc_850_pkgs='autoconf@2.69%gcc@8.5.0         gdbm@1.19%gcc@8.5.0                         libtool@2.4.6%gcc@8.5.0   perl@5.34.0%gcc@8.5.0 
              automake@1.16.3%gcc@8.5.0       gmp@6.2.1%gcc@8.5.0                         m4@1.4.19%gcc@8.5.0       pkgconf@1.8.0%gcc@8.5.0 
              berkeley-db@18.1.40%gcc@8.5.0   intel-oneapi-compilers@2021.3.0%gcc@8.5.0   mpc@1.1.0%gcc@8.5.0       readline@8.1%gcc@8.5.0 
              bzip2@1.0.8%gcc@8.5.0           intel-oneapi-mpi@2021.3.0%gcc@8.5.0         mpfr@3.1.6%gcc@8.5.0      zlib@1.2.11%gcc@8.5.0 
              diffutils@3.8%gcc@8.5.0         libiconv@1.16%gcc@8.5.0                     ncurses@6.2%gcc@8.5.0 
              gcc@8.5.0%gcc@8.5.0             libsigsegv@2.13%gcc@8.5.0                   patchelf@0.13%gcc@8.5.0'

intel_202130_pkgs='autoconf@2.69%intel@2021.3.0               intel-oneapi-mpi@2021.3.0%intel@2021.3.0   numactl@2.0.14%intel@2021.3.0 
                   automake@1.16.3%intel@2021.3.0             intel-oneapi-tbb@2021.4.0%intel@2021.3.0   openssl@1.1.1l%intel@2021.3.0 
                   berkeley-db@18.1.40%intel@2021.3.0         libedit@3.1-20210216%intel@2021.3.0        parallel-netcdf@1.12.2%intel@2021.3.0 
                   bzip2@1.0.8%intel@2021.3.0                 libiconv@1.16%intel@2021.3.0               patchelf@0.13%intel@2021.3.0 
                   cmake@3.21.4%intel@2021.3.0                libsigsegv@2.13%intel@2021.3.0             perl@5.34.0%intel@2021.3.0 
                   curl@7.79.0%intel@2021.3.0                 libtool@2.4.6%intel@2021.3.0               pkgconf@1.8.0%intel@2021.3.0 
                   diffutils@3.7%intel@2021.3.0               libxml2@2.9.12%intel@2021.3.0              readline@8.1%intel@2021.3.0 
                   esmf@8.1.1%intel@2021.3.0                  m4@1.4.17%intel@2021.3.0                   util-macros@1.19.3%intel@2021.3.0 
                   gdbm@1.19%intel@2021.3.0                   ncurses@6.2%intel@2021.3.0                 xerces-c@3.2.3%intel@2021.3.0 
                   hdf5@1.10.7%intel@2021.3.0                 netcdf-c@4.8.0%intel@2021.3.0              xz@5.2.5%intel@2021.3.0 
                   intel-oneapi-mkl@2021.3.0%intel@2021.3.0   netcdf-fortran@4.5.3%intel@2021.3.0        zlib@1.2.11%intel@2021.3.0'

esmf_pkgs=''

#pkgs=$gcc_485_pkgs
#pkgs=$gcc_850_pkgs
pkgs=$intel_202130_pkgs

echo $pkgs

export TMP=/save/tmp

spack buildcache create -a --mirror-name s3-mirror $pkgs

spack buildcache update-index -d s3://ioos-cloud-sandbox/public/spack/mirror/
