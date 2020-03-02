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

expected_impi_versions="2019.5 2019.6"

impi_major_version=2019
impi_minor_version=6
impi_symlink="/opt/intel/impi/latest"
has_intel64_level=1

function usage()
{
    echo ""
    echo "usage: aws_impi.sh COMMAND [OPTIONS]"
    echo ""
    echo "  COMMAND:"
    echo "    install   - install Intel MPI ${impi_version}"
    echo "    uninstall - uninstall Intel MPI ${impi_version}"
    echo ""
    echo "  OPTIONS:"
    echo "    -version <version>  - Install/uninstall specific Intel MPI version (${impi_version} by default)."
    echo "    -tuning_url <url>   - Download and setup custom tuning file during Intel MPI installation."
    echo "                          By default installer doesn't download tuning file and the tuning file"
    echo "                          from Intel MPI package is used."
    echo "    -check_efa <0|1>    - Force the installer to check for desired OFI/EFA provider capabilities"
    echo "                          during Intel MPI installation. Enabled by default."
}

# Default options
impi_version="${impi_major_version}.${impi_minor_version}"
tuning_url=""
check_efa=1

if [ -z $1 ]; then
    usage
    exit 1
fi

command=$1
shift

# Parse options

while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -version)
        impi_version="$2"
        shift
        shift
        ;;
        -tuning_url)
        tuning_url="$2"
        shift
        shift
        ;;
        -check_efa)
        check_efa="$2"
        shift
        shift
        ;;
        -*|--*=)
        echo "Error: unsupported option $1" >&2
        usage
        exit 1
        ;;
    esac
done

# Check options correctness

version_found=0
for expected_version in $expected_impi_versions;
do
    if [ "$impi_version" == "$expected_version" ];
    then
        version_found=1
        impi_major_version=$(echo $impi_version | cut -d. -f1)
        impi_minor_version=$(echo $impi_version | cut -d. -f2)
        break
    fi
done
if [ "$version_found" == 0 ];
then
    echo "Unexpected IMPI version: $impi_version"
    echo "Expected IMPI versions: $expected_impi_versions"
    exit 1
fi

setup_custom_tuning=0
if [ "$tuning_url" != "" ];
then
    if curl --output /dev/null --silent --head --fail "$tuning_url";
    then
        setup_custom_tuning=1
    else
        echo "Can't find tuning file by url $tuning_url"
        exit 1
    fi
fi

if [ "$check_efa" != "1" ] && [ "$check_efa" != "0" ];
then
    echo "Unexpected check_efa value: $check_efa"
    usage
    exit 1
fi


echo ""
echo "COMMAND"
echo "$command"
echo ""
echo "OPTIONS"
echo "version: ${impi_major_version}.${impi_minor_version}"
echo "tuning_url: $tuning_url"
echo "check_efa: $check_efa"
echo ""


impi_package_prefix="intel-mpi"
impi_package_name="${impi_package_prefix}-${impi_version}*"
impi_install_path_pattern="/opt/intel/impi/${impi_version}*"
if [ "$has_intel64_level" == "1" ];
then
    impi_install_path_pattern="${impi_install_path_pattern}/intel64"
fi
custom_tuning_filename="efa_tuning.dat"
custom_tuning_path="${impi_symlink}/etc/${custom_tuning_filename}"

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

function patch_env_files()
{
    if [ "$impi_symlink" == "" ] || [ ! -d $impi_symlink ];
    then
        echo "Can't find installed Intel MPI, exit"
        exit 1
    fi

    ########################## mpivars.sh ##########################
    env_file="${impi_symlink}/bin/mpivars.sh"
    if [ ! -f $env_file ] || [ -L $env_file ];
    then
        echo "Can't find ${env_file}, exit"
        exit 1
    fi
    pattern="export I_MPI_ROOT"
    sudo sed -i "/${pattern}/a export LD_LIBRARY_PATH=${libfabric_lib_path}:\${LD_LIBRARY_PATH}" $env_file
    sudo sed -i "/${pattern}/a if [ -z \"\${I_MPI_OFI_LIBRARY_INTERNAL}\" ]; then export I_MPI_OFI_LIBRARY_INTERNAL=0 ; fi" $env_file
    if [ "$setup_custom_tuning" == "1" ];
    then
        sudo sed -i "/${pattern}/a if [ -z \"\${I_MPI_TUNING_BIN}\" ]; then export I_MPI_TUNING_BIN=${custom_tuning_path} ; fi" $env_file
    fi

    ########################## mpivars.csh ##########################
    env_file="${impi_symlink}/bin/mpivars.csh"
    if [ ! -f $env_file ] || [ -L $env_file ];
    then
        echo "Can't find ${env_file}, exit"
        exit 1
    fi
    pattern="setenv I_MPI_ROOT"
    sudo sed -i "/${pattern}/a if \!(\$?LD_LIBRARY_PATH) then\n    setenv LD_LIBRARY_PATH ${libfabric_lib_path}\nelse\n    setenv LD_LIBRARY_PATH ${libfabric_lib_path}:\${LD_LIBRARY_PATH}\nendif" $env_file
    sudo sed -i "/${pattern}/a if \!(\$?I_MPI_OFI_LIBRARY_INTERNAL) setenv I_MPI_OFI_LIBRARY_INTERNAL 0" $env_file
    if [ "$setup_custom_tuning" == "1" ];
    then
        sudo sed -i "/${pattern}/a if \!(\$?I_MPI_TUNING_BIN) setenv I_MPI_TUNING_BIN ${custom_tuning_path}" $env_file
    fi

    ########################## module file ##########################
    env_file="${impi_symlink}/modulefiles/mpi"
    if [ ! -f $env_file ] || [ -L $env_file ];
    then
        echo "Can't find ${env_file}, exit"
        exit 1
    fi
    pattern="I_MPI_ROOT"
    sudo sed -i "/${pattern}/a prepend-path LD_LIBRARY_PATH ${libfabric_lib_path}" $env_file
    sudo sed -i "/${pattern}/a setenv I_MPI_OFI_LIBRARY_INTERNAL 0" $env_file
    if [ "$setup_custom_tuning" == "1" ];
    then
        sudo sed -i "/${pattern}/a setenv I_MPI_TUNING_BIN ${custom_tuning_path}" $env_file
    fi
}

function install_impi()
{
    if [ "$check_efa" == "1" ];
    then
        echo "Checking libfabric EFA provider"
        check_efa_provider
    else
        echo "Skip check for libfabric EFA provider"
    fi

    echo "Installing Intel MPI package ${impi_version}"

    previous_impi_installations=""
    if [ "$is_ubuntu" == "1" ];
    then
        previous_impi_installations=$(sudo apt list --installed 2>&1 | grep -i "${impi_package_prefix}-*")
    else
        previous_impi_installations=$(sudo yum list installed ${impi_package_prefix}-* 2>&1 | grep "${impi_package_prefix}")
    fi

    if [ "$previous_impi_installations" != "" ];
    then
        echo ""
        echo "Another Intel MPI installations are detected:"
        echo ""
        echo "$previous_impi_installations"
        echo ""
        echo "Please uninstall them and run installer again."
        echo ""
        exit 1
    fi

    if [ "$setup_custom_tuning" == "1" ];
    then
        echo "Downloading Intel MPI custom tuning file"
        custom_tuning_zip="tuning.zip"
        curl -o $custom_tuning_zip $tuning_url
        custom_tuning_dat=`unzip -Z1 $custom_tuning_zip | grep ".dat"`
        unzip -o $custom_tuning_zip
        expected_checksum=$(cat checksum.txt)
        real_checksum=$(md5sum $custom_tuning_dat | awk '{ print $1 }')
        echo "expected_checksum $expected_checksum"
        echo "real_checksum $real_checksum"
        if [ "$real_checksum" != "$expected_checksum" ];
        then
            echo "Unexpected tuning file checksum $real_checksum, expected $expected_checksum"
            exit 1
        fi
    fi

    if [ "$is_ubuntu" == "1" ];
    then
        curl -o apt_key https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-${impi_major_version}.PUB
        sudo apt-key add apt_key
        sudo sh -c 'echo deb https://apt.repos.intel.com/mpi all main > /etc/apt/sources.list.d/intel-mpi.list'
        sudo apt-get update
        sudo apt-get install ${impi_package_name} -y
        sudo apt install aptitude -y
        sudo apt install unzip -y
        rm apt_key
    else
        sudo yum-config-manager --add-repo=https://yum.repos.intel.com/mpi/setup/intel-mpi.repo
        sudo rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-${impi_major_version}.PUB
        sudo yum install yum-plugin-remove-with-leaves -y
        sudo yum install ${impi_package_name} -y
        sudo yum install unzip -y
    fi

    if ! ls -d $impi_install_path_pattern > /dev/null 2>&1;
    then
        echo "Can't find Intel MPI installation directory"
        exit 1
    fi
    impi_install_path=`ls -d ${impi_install_path_pattern} | head -n 1`
    sudo ln -sfn $impi_install_path $impi_symlink

    if [ "$setup_custom_tuning" == "1" ];
    then
        echo "Copying Intel MPI custom tuning file"
        sudo cp $custom_tuning_dat $custom_tuning_path
        rm checksum.txt
        rm $custom_tuning_zip
        rm $custom_tuning_dat
    fi

    echo "Patching environment files"
    patch_env_files

    echo "Intel MPI installation completed"
}

function uninstall_impi()
{
    echo "Unstalling Intel MPI package ${impi_version}"

    if ! ls -d $impi_install_path_pattern > /dev/null 2>&1;
    then
        echo "Can't find Intel MPI installation directory."
        echo "Please specify the exact Intel MPI version for removal."
        exit 1
    fi

    if [ -f "${custom_tuning_path}" ] && [ ! -L "${custom_tuning_path}" ];
    then
        echo "Removing custom tuning file"
        sudo rm $custom_tuning_path
    fi

    old_custom_tuning_path=${impi_install_path_pattern}/etc/${custom_tuning_filename}
    if [ -f "${old_custom_tuning_path}" ] && [ ! -L "${old_custom_tuning_path}" ];
    then
        echo "Removing custom tuning file from old installation"
        sudo rm $old_custom_tuning_path
    fi

    if [ -L "${impi_symlink}" ];
    then
        echo "Removing symlink"
        sudo unlink $impi_symlink
    fi

    if [ "$is_ubuntu" == "1" ];
    then
        sudo apt-get autoremove ${impi_package_name} -y
    else
        sudo yum remove ${impi_package_name} --remove-leaves -y
        sudo yum remove ${impi_package_name} -y
        sudo yum remove "${impi_package_prefix}-rt-${impi_major_version}*" -y
        sudo yum remove "${impi_package_prefix}-doc-${impi_major_version}*" -y
        sudo yum remove "intel-comp-l-all-vars-*" -y
    fi

    impi_opt_path="/opt/intel"
    if [ -d "${impi_opt_path}" ] && [ ! -L "${impi_opt_path}" ];
    then
        if [ -z "$(ls -A ${impi_opt_path})" ];
        then
            sudo rm -r ${impi_opt_path}
        fi
    fi

    echo "Intel MPI uninstallation completed"
}

if [ "$command" == "install" ];
then
    install_impi
elif [ "$command" == "uninstall" ];
then
    uninstall_impi
else
    usage
    exit 1
fi
