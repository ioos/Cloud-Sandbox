Steps to run SECOFS:

0. Update modulefiles/intel_x86_64 file as needed to 
   reflect the exact modules installed on your system.
   e.g. on NOS SB - 'cp nos.intel_x86_64 intel_x86_64'

1. Edit setup_schism.sh to change the destination folders if needed:
   e.g. change MODEL_DIR="/save/$USER" to point to your /save folder
   and change DATA_DIR to point to you /com folder

2. setup_schism.sh        - Launch this, it will call the below three script.

    get_schism.sh          - clone the schism source code and the branch to use
    build_schism.sh        - build the model and binaries
    get_testcase_inputs.sh - download the test case input data from S3

3. Setup your cluster config file.
   e.g. cloudflow/cluster/configs/IOOS/secofs.hpc6
   Get adminstrator help to properly fill out the values for your deployment.

4. Setup your job config file.
   e.g. cloudflow/jobs/jobs/OFS/secofs.coldstart or secofs.hotstart
   These will use the the model configuration template in: cloudflow/job/templates
       secofs_coldstart.param.nml.in        - run day 1 from a cold start
       secofs_hotstart.param.nml.in         - start run from coldstart provided day 2 to N
       secofs_restart_continue.param.nml.in - use to continue a previous run with a newer hotstart, e.g. run day N to Z

5. Run the job(s)
   e.g.
   cd cloudflow
   ./workflows/workflow_main.sh cluster/configs/IOOS/secofs.hpc6 jobs/jobs/OFS/secofs.coldstart >& secofs.cold.out &

Model will run in the following output folder:
/com/_your_folder_/secofs/20171201/outputs

After running a coldstart and/or before continuing from a hoststart.nc file,
the following script needs to be run. Edit the script as needed for your specific case.
Eventually, this step can be implemented in a workflow.

6. Modify and run combine_hotstarts.sh as needed. See that script and ./README.hotstart.md.

Note: Due to AWS EFS limitations of 512 concurrent locks on a file (meaning no more than 512 processes can have the same file open concurrently). If you are running an older version of schism and using EFS, hotstart runs are limited to less than 512 processes since each process is attempting to open the hotstart.nc file. This issue has been patched in the schism source code retrieved by the scripts in this package.

Note: Due to high memory requirements during initialization, if there is insufficient memory available on the nodes, you will see errors such as: "ABORT:  STEP: wrong sign vsource         650         431  9.0000004E-02 -3.3998805E+24". Use more nodes or nodes with more RAM.

coldstart:
    hpc7a.96xlarge x 2 nodes minimum
    hpc6a.48xlarge x 6 nodes minimum

hotstart:
    hpc7a.96xlarge x 2 nodes minimum
    hpc6a.48xlarge x 7 nodes minimum
    
I have seen MPI ABORT on 8 hpc6a.48xlarge, not consistently though and not the ABORT wrong sign vsource error.

When restarting, the run start date and time stays the same. The timestep the model run starts at is determined by the hotstart.nc file that is created from a prior run when using the restart option. See cloudflow/job/templates/secofs.__option__. 
