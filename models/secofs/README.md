Run SECOFS test case:

Edit these scripts to set the proper destination folders as needed:

get_schism.sh - clone the schism source code and the branch to use
build_schism.sh - build the model and binaries
get_testcase_inputs.sh - download the sample input data from S3

After running a coldstart and/or before continuing from a hoststart.nc file,
the following script needs to be run. Edit the script as needed for your specific case.
Eventually, this step can be implemented in a workflow.

combine_hotstarts.sh

Note: Due to AWS EFS limitations of 512 concurrent locks on a file (meaning no more than 512 processes can have the same file open concurrently). If you are running an older version of schism and using EFS, hotstart runs are limited to less than 512 processes since each process is attempting to open the hotstart.nc file. This issue has been patched in the schism source code retrieved by the scripts in this package.

Note: Due to high memory requirements during initialization, if there is insufficient memory available on the nodes, you will see errors such as: "ABORT:  STEP: wrong sign vsource         650         431  9.0000004E-02 -3.3998805E+24". Use more nodes or nodes with more RAM.

coldstart:
    hpc7a.96xlarge x 2 nodes minimum
    hpc6a.48xlarge x 6 nodes minimum

hotstart:
    hpc7a.96xlarge x 2 nodes minimum
    hpc6a.48xlarge x 7 nodes minimum
    
I have seen MPI ABORT on 8 hpc6a.48xlarge, not consistently though and not the ABORT wrong sign vsource 

