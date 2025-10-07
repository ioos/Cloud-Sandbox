1. Once you’ve logged into the head node of Cloud-Sandbox, go into the `/save/ec2-user` directory and create a new directory based on your affiliated organization. (Ex. `mkdir USER_AFFILIATION`). Go into the newly made directory for the next step.

2. Clone the latest Cloud-Sandbox code repository off the GitHub repository: 
~~~bash
git clone https://github.com/ioos/Cloud-Sandbox.git
~~~

3. **Create a job file for your model.** 
The keywords in this job file will inform the rest of the workflow.
Change directory into 
~~~bash
Cloud-Sandbox/cloudflow/job/jobs
~~~ 
Copy the `cloud_sandbox_basic.template` file into a new file called `your_model_name.basic`. Inside that new file, you must specify at minimum the: 
- MODEL (model name/class) 
- JOBTYPE (model job type, be explicit on the workflow name for the given model class)
- EXEC (executable) 
- any executable dependencies as a new variable (such as an input file) 
- MODEL_DIR (path to model directory on the Cloud-Sandbox) 

4. **Create an AWS cluster configuration file for your model.** 
Change directory into 
~~~bash
Cloud-Sandbox/cloudflow/cluster/config 
~~~
Create a new directory based on your affiliated organization. (Ex. `mkdir USER_AFFILIATION`). Copy `template.ioos` into a new file called `your_model_name.config` to specify the AWS cloud resource configuration you would like your model to run on. Move the new file `your_model_name.config` in your user affiliation directory. In that file you can edit the following variables: 
- nodeType (Eligible AWS node instances are listed within the `cloudflow/cluster/AWSCluster.py` Python script under variable `awsTypes` with the associated CPU core count) 
- nodeCount (Number of nodes you want to utilize of the given AWS node instance. A word of caution as the Cloud-Sandbox AWS account does have caps on the number of nodes you can allocate for a given instance)
- tags (The Values for “Name” and “Project” should reflect your model name and affiliation). 

5. **Build the workflow for your model - `workflow_main.py`**
Change directory into 
~~~bash
Cloud-Sandbox/cloudflow/workflows
~~~ 

Edit the `workflow_main.py` script. 
- In the function `main()` under the for loop `for jobfile in joblist:`
   - add an `elif jobtype == ` block with your JOBTYPE that you specified in the job file from Step #3. 
      - You can copy the block for `ucla-roms` for most models and replace the jobtype. Otherwise, choose or create a function in `Cloud-Sandbox/cloudflow/workflows/flows.py`
   - If you need to execute a specific Python environment pathway, then you will also need to replace the `-S python3 -u` syntax in the very first line with the Python environment pathway. For example, the first line will end up looking like `#/usr/bin/env /pathway/to/python`.

6. **Build the workflow for your model - `your_model_name.py`** 
We will create a file to read in the keywords from your job file by creating a new script and class for your model.
Change directory into 
~~~bash
Cloud-Sandbox/cloudflow/job
~~~ 	
Within that directory, you will want to copy the file called `Basic_Template.py` to `your_model_name.py`. Within the `your_model_name.py` file, you will see that the original configuration of this file is reflected strictly based on the `cloud_sandbox_basic.template` job file you’ve copied and modified in Step #3. 
- Rename the “Basic_Template” Python class name to “your_model_name_basic” so this can now reflect a unique Python class for your own specific model with the basic approach for model execution. 
- If your model execution only needs to know essentially the location of the model run directory and then executable itself, then you don’t need to modify anything else in this file. 
- If your model executable needs more information (e.g, model argument, specific model libraries to be linked) that you’ve included `your_model_name.basic` file in Step #3, then you will need to include that information within the `parseConfig` function inside your new Python class.
   - e.g., if you added the variable `"IN_FILE" : "path/to/inputfile"` in your `your_model_name.basic` job file, then you will need to add `self.IN_FILE = cfDict['IN_FILE']` in under `parseConfig`

7. **Build the workflow for your model - `JobFactory.py`**	
Edit `JobFactory.py` file and at the very top of the script, you will now add a new import statement to reflect the new “your_model” Python class you’ve constructed from the `your_model_name.py` file you created in Step #6 
- e.g., 
~~~python
from cloudflow.job.your_model_name import your_model_name
~~~
Inside `class JobFactory`, edit the `job` function 
- Insert an `elif` statement that reflects your `MODEL` `jobtype` variable defined in your `your_model_name.basic` file constructed in Step #3 
- Call the new Python class you created in Step #6 and imported here
  - `newjob = your_model_name(configfile, NPROCS)`

8. **Build the workflow for your model - `tasks.py`**	
If your model executable does not need more information than the template job file (just the pathway to the model run directory and the executable in `your_model_name.basic` job file in Step #3) then skip this step and move to the next one. If you added variables to your job file, read this step.

Change directory into 
~~~bash
Cloud-Sandbox/cloudflow/workflows
~~~ 	
Edit `tasks.py`
- Edit the `template_run` function 
  - Inside that function, add an `elif` statement within the code block to include the extra arguments for your model from your job file `your_model_name.basic` created in Step #3 to include in the launcher script that you will modify in Step #9. 
  - Add the new variable(s) you created in your job file to the `result` command. 
    - e.g., if you added the variable `"IN_FILE" : "path/to/inputfile"` in your `your_model_name.basic` job file, 
      - define the variable `IN_FILE = job.IN_FILE` and add `str(IN_FILE)` in the `subprocess.run` command within the square brackets. 
    - Make sure you put the new variables at the end of the other strings in the square brackets. 
  - Copy and modify the code logic like in the `schism`, `dflowfm`, or `ucla-roms` code blocks.
  

9. **Build the workflow for your model - `basic_launcher.py`**	
This controls the launch of your model inside the Cloud-Sandbox.
Change directory into 
~~~bash
Cloud-Sandbox/cloudflow/workflows
~~~ 	
Modify `basic_launcher.sh` 
- If you completed Step #8 due to model information required from the job file to kick start the executable, 
  - make an `if` shell script block to ingest the special input argument(s) 
    - You can simply follow along with the code blocks for `schism`, `dflowfm`, or `ucla-roms` for the `export` statements. 
    - The `$7` in these `export` statements refer to the 7th string added in the `result = subprocess.run` command in `tasks.py`, which should be the new variable you added in Step #8. If you added more than one new variable, they would be `$8`, `$9`, and so on.

Next, go towards the bottom of the script where you see a set of if/elif blocks of code for specific model suites. 
- Construct a code block for “your_model” that points to a shell launcher script and add the specific arguments required to run your model 
- That launcher script for “your_model” will be constructed in the next step, where it takes specific arguments required to run your model. 
  - The default requirements for each of the launcher scripts are the model run directory and the pathway to the model executable. If more is required for your given model to launch, then include those as well similar to the code logic you see in the other if/elif code blocks.

10. **Build the workflow for your model - `your_model_run.sh`**		
Copy the `model_basic_run.sh` file to a new file called `your_model_run.sh`. Inside that file, you will see the general workflow template that you will need to modify: 
(1) Load the required compilers and libraries used to compile your model 
(2) Export any required environmental variables needed for the AWS cloud environment to run your given model executable and 
(3) Call the method to run your model with the given executable (e.g., mpirun or mpiexec). 

11. Now, go back to `basic_launcher.sh` and ensure that the if/elif code block you’ve constructed in Step #9 is matching the syntax of calling that specific shell script. Check that the code logic also includes the script arguments required to properly run the given model suite. 
- You may need to add an `if` statement for `MPIOPTS` for your model depending on how your model is configured.

12. **Run your model**
Finally, we can now attempt to run the model! 
Change directory into 
~~~bash
Cloud-Sandbox/cloudflow
~~~ 	
Make sure you are in the `cloudflow` directory before running any models. Follow the steps below to submit the Cloud-Sandbox job submission to the background of the head node and monitor your job progress:
~~~bash
./workflows/workflow_main.py ./cluster/configs/your_model_name.config ./job/jobs/your_model_name.exp &> your_model_test.out &
~~~
To see the progress of the Cloud-Sandbox execution of your model
~~~bash
tail -f your_model_test.out 
~~~

