# Copyright © 2019 Intel Corporation
# SPDX-License-Identifier: MIT

# Copyright 2019 Intel Corporation

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#!/bin/bash

impi_version="2019.4-070"

function usage()
{
    echo "usage: aws_impi.sh ACTION [OPTIONS]"
    echo ""
    echo "  ACTION: install | uninstall | reinstall"
    echo "    install         - install Intel MPI ${impi_version}"
    echo "    uninstall       - uninstall Intel MPI ${impi_version}"
    echo "    reinstall       - reinstall Intel MPI ${impi_version}"
    echo ""
    echo "  OPTIONS: dont_check_efa"
    echo "    dont_check_efa  - force the script to skip check for desired OFI/EFA provider capabilities"
    echo "                      during Intel MPI installation. By default this option is disabled, i.e. the script"
    echo "                      will try to detect whether desired OFI/EFA provider presents and"
    echo "                      will fail if provider is absent."
}

if [ -z $1 ]; then
    usage
    exit 1
fi

action=$1

if [ -z $2 ]; then
    options="check_efa" # default behavior
else
    options=$2
fi

echo "action $action, options $options"

impi_package_name="intel-mpi-${impi_version}"
impi_install_path_pattern="/opt/intel/impi/2019.4*"
impi_install_path=""
tuning_filename="efa_tuning.dat"
tuning_filename_path=""
is_ubuntu=0
libfabric_lib_path="/opt/amazon/efa/lib64"

is_ubuntu=`cat /etc/*release* | grep -i "ubuntu" | wc -l`
if [ "$is_ubuntu" != "0" ];
then
    is_ubuntu=1
fi

if [ "$is_ubuntu" == "1" ];
then
    libfabric_lib_path="/opt/amazon/efa/lib"
else
    libfabric_lib_path="/opt/amazon/efa/lib64"
fi

function print_efa_install_instruction()
{
    echo "You can use the following commands to install the latest version of libfabric EFA provider"
    echo "    curl -O https://s3-us-west-2.amazonaws.com/aws-efa-installer/aws-efa-installer-latest.tar.gz"
    echo "    tar -zxf aws-efa-installer-latest.tar.gz"
    echo "    cd aws-efa-installer"
    echo "    sudo ./efa_installer.sh -y"
}

function check_efa_provider()
{
    fi_info_path="/opt/amazon/efa/bin/fi_info"
    if [ ! -f $fi_info_path ];
    then
        echo "Can't find ${fi_info_path}"
        print_efa_install_instruction
        exit 1
    fi

    prov_count=`${fi_info_path} -p efa -c "FI_TAGGED|FI_RMA" -t FI_EP_RDM | grep "provider:" | grep -v rxd | wc -l`
    if [ "$prov_count" == "0" ];
    then
        prov_count=`${fi_info_path} -p efa -c "FI_TAGGED" -t FI_EP_RDM | grep "provider:" | grep -v rxd | wc -l`
        if [ "$prov_count" == "0" ];
        then
            echo "Can't find provider with desired capabilities"
            print_efa_install_instruction
            exit 1
        elif [ "$prov_count" == "1" ];
        then
            echo "Older version of EFA provider found. This version does not support Intel MPI."
            print_efa_install_instruction
            exit 1
        else
            echo "Unexpected provider lists"
            exit 1
        fi
    else
        echo "EFA provider is found! Installation will proceed!"
    fi
}

function set_tuning_filename_path()
{
    if ls -d $impi_install_path_pattern > /dev/null 2>&1;
    then
        impi_install_path=`ls -d $impi_install_path_pattern | head -n 1`
        tuning_filename_path="${impi_install_path}/intel64/etc/${tuning_filename}"
    else
        impi_install_path=""
        tuning_filename_path=""
    fi
}

function patch_env_files()
{
    set_tuning_filename_path

    echo "impi_install_path $impi_install_path"

    if [ "$impi_install_path" == "" ] || [ ! -d $impi_install_path ];
    then
        echo "Can't find installed Intel MPI, exit"
        exit 1
    fi

    env_file="${impi_install_path}/intel64/bin/mpivars.sh"
    if [ ! -f $env_file ] || [ -L $env_file ];
    then
        echo "Can't find ${env_file}, exit"
        exit 1
    fi
    pattern="I_MPI_ROOT="
    sudo sed -i "/${pattern}/a if [ -z \"\${MPIR_CVAR_CH4_OFI_ENABLE_ATOMICS}\" ]; then export MPIR_CVAR_CH4_OFI_ENABLE_ATOMICS=0 ; fi" $env_file
    sudo sed -i "/${pattern}/a if [ -z \"\${I_MPI_OFI_LIBRARY_INTERNAL}\" ]; then export I_MPI_OFI_LIBRARY_INTERNAL=0 ; fi" $env_file
    sudo sed -i "/${pattern}/a if [ -z \"\${I_MPI_EXTRA_FILE_SYSTEM}\" ]; then export I_MPI_EXTRA_FILE_SYSTEM=1 ; fi" $env_file
    sudo sed -i "/${pattern}/a if [ -z \"\${ROMIO_FSTYPE_FORCE}\" ]; then export ROMIO_FSTYPE_FORCE=\"nfs:\" ; fi" $env_file
    sudo sed -i "/${pattern}/a if [ -z \"\${I_MPI_TUNING_BIN}\" ]; then export I_MPI_TUNING_BIN=${tuning_filename_path} ; fi" $env_file
    sudo sed -i "/${pattern}/a export LD_LIBRARY_PATH=${libfabric_lib_path}:\${LD_LIBRARY_PATH}" $env_file

    env_file="${impi_install_path}/intel64/bin/mpivars.csh"
    if [ ! -f $env_file ] || [ -L $env_file ];
    then
        echo "Can't find ${env_file}, exit"
        exit 1
    fi
    pattern="setenv I_MPI_ROOT"
    sudo sed -i "/${pattern}/a if \!(\$?MPIR_CVAR_CH4_OFI_ENABLE_ATOMICS) setenv MPIR_CVAR_CH4_OFI_ENABLE_ATOMICS 0" $env_file
    sudo sed -i "/${pattern}/a if \!(\$?I_MPI_OFI_LIBRARY_INTERNAL) setenv I_MPI_OFI_LIBRARY_INTERNAL 0" $env_file
    sudo sed -i "/${pattern}/a if \!(\$?I_MPI_EXTRA_FILE_SYSTEM) setenv I_MPI_EXTRA_FILE_SYSTEM 1" $env_file
    sudo sed -i "/${pattern}/a if \!(\$?ROMIO_FSTYPE_FORCE) setenv ROMIO_FSTYPE_FORCE \"nfs:\"" $env_file
    sudo sed -i "/${pattern}/a if \!(\$?I_MPI_TUNING_BIN) setenv I_MPI_TUNING_BIN ${tuning_filename_path}" $env_file
    sudo sed -i "/${pattern}/a if \!(\$?LD_LIBRARY_PATH) then\n    setenv LD_LIBRARY_PATH ${libfabric_lib_path}\nelse\n    setenv LD_LIBRARY_PATH ${libfabric_lib_path}:\${LD_LIBRARY_PATH}\nendif" $env_file

    env_file="${impi_install_path}/intel64/modulefiles/mpi"
    if [ ! -f $env_file ] || [ -L $env_file ];
    then
        echo "Can't find ${env_file}, exit"
        exit 1
    fi
    pattern="setenv              I_MPI_ROOT"
    sudo sed -i "/${pattern}/a setenv MPIR_CVAR_CH4_OFI_ENABLE_ATOMICS 0" $env_file
    sudo sed -i "/${pattern}/a setenv I_MPI_OFI_LIBRARY_INTERNAL 0" $env_file
    sudo sed -i "/${pattern}/a setenv I_MPI_EXTRA_FILE_SYSTEM 1" $env_file
    sudo sed -i "/${pattern}/a setenv ROMIO_FSTYPE_FORCE \"nfs:\"" $env_file
    sudo sed -i "/${pattern}/a setenv I_MPI_TUNING_BIN ${tuning_filename_path}" $env_file
    sudo sed -i "/${pattern}/a prepend-path LD_LIBRARY_PATH ${libfabric_lib_path}" $env_file
}

function install_impi()
{
    echo "1. Checking prerequisites"

    if [ "$options" == "check_efa" ];
    then
        check_efa_provider
    else
        echo "Skip check for libfabric EFA provider"
    fi

    echo "2. Installing Intel MPI package ${impi_version}"

    if [ "$is_ubuntu" == "1" ];
    then
        curl -o apt_key https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
        sudo apt-key add apt_key
        sudo sh -c 'echo deb https://apt.repos.intel.com/mpi all main > /etc/apt/sources.list.d/intel-mpi.list'
        sudo apt-get update
        sudo apt-get install ${impi_package_name} -y
        sudo apt install aptitude -y
        sudo apt install unzip -y
        rm apt_key
    else
        sudo yum-config-manager --add-repo https://yum.repos.intel.com/mpi/setup/intel-mpi.repo
        sudo rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
        sudo yum install yum-plugin-remove-with-leaves -y
        sudo yum install ${impi_package_name} -y
        sudo yum install unzip -y
    fi

    echo "3. Setting Intel MPI tuning file for EFA"

    tuning_file_url="https://software.intel.com/sites/default/files/managed/f2/65/tuning_skx_shm-ofi_2019u4_aws.zip"
    tuning_file_name_zip="efa_tuning.zip"
    curl -o $tuning_file_name_zip $tuning_file_url
    origin_tuning_file_name=`unzip -Z1 $tuning_file_name_zip | grep ".dat"`
    unzip -o $tuning_file_name_zip
    set_tuning_filename_path
    sudo cp $origin_tuning_file_name $tuning_filename_path

    echo "4. Patching environment files"

    patch_env_files

    echo "5. Cleaning up temporary files"

    rm checksum.txt
    rm $tuning_file_name_zip
    rm $origin_tuning_file_name

    echo "Intel MPI installation completed"
}

function uninstall_impi()
{
    echo "1. Removing tuning file"

    set_tuning_filename_path
    if [ "$tuning_filename_path" != "" ] && [ -f "$tuning_filename_path" ] && [ ! -L "$tuning_filename_path" ];
    then
        sudo rm $tuning_filename_path
    fi

    echo "2. Unstalling Intel MPI package ${impi_version}"

    if [ "$is_ubuntu" == "1" ];
    then
        sudo apt-get autoremove ${impi_package_name} -y
    else
        sudo yum remove ${impi_package_name} --remove-leaves -y
        sudo yum remove ${impi_package_name} -y
        sudo yum remove intel-mpi-rt-2019.4-243 -y
        sudo yum remove intel-mpi-doc-2019 -y
        sudo yum remove intel-comp-l-all-vars-19.0.4-243 -y
    fi

    impi_opt_path="/opt/intel"
    if [ -d "${impi_opt_path}" ] && [ ! -L "${impi_opt_path}" ];
    then
        if [ -z "$(ls -A ${impi_opt_path})" ];
        then
            echo "3. Deleting ${impi_opt_path}"
            sudo rm -r ${impi_opt_path}
        fi
    fi

    echo "Intel MPI uninstallation completed"
}

if [ "$action" == "install" ];
then
    install_impi
elif [ "$action" == "uninstall" ];
then
    uninstall_impi
elif [ "$action" == "reinstall" ];
then
    uninstall_impi
    install_impi
else
    usage
    exit 1
fi
