# Script system to manage templated sets of ADCIRC runs

## B. Blanton, RENCI

## April 2024

## Set up for GEC test


### Overall process
The main script, run_storms.sh, looks for events/tracks to prep/submit in TracksToRun.  Details of the ADCIRC run parameters that are event specific, and job control paraneters are specified in a yaml file.  The following directories are in the "installation": 

<pre>
   |-ADCIRC
   |---bin                        # tide_factor code (may need compiling)
   |---common                     # template files
   |---configs                    # yaml config files
   |---ERA5                       # ADICRC simulation "work" dir
   |-----ec95d                    # ADCIRC grid used
   |-------2018.renci             # RENCI results for 2018 prior on ec95d
   |---Grids                      # ADCIRC grid files
   |---TracksToRun                # .trk files
   |-Forcing                      # Wind/DWLC files
   |---Winds
   |-----ERA5
   |-------2018                   # fort.22{1,2} files for ERA5, year 2018
   |---DynWatLevCor               # not used in this test
</pre>


### Compile codes

ADCIRC should be compiled external to this structure and pointed to by the **ADCIRCHome** key in the config yaml (see below).   The tide_factor code in **ADCIRC/bin** may need compiling as well. 

<hr>

### Job control template

1. Make (or modify) a template job submission script for whatever job manager is used.  RENCI uses slurm, with 

<pre>common/submit.slurm.template</pre> 

as the template. Relevant job control parameters are set in the Job: stanza in the config file:

<pre>
Job:
  Manager: slurm
  NumberOfCores: 64
  NumberOfWriterCores: 4
  Partition: batch
  ProcessorsPerNode: 1
  Queue: None
  Reservation: None
  StatusCommand: "squeue --noheader --format=\"%i %j %u %C\""
  SubmitCommand: sbatch
  WallTime: 12:00:00
</pre>

The StatusCommand is used in **run_storms.sh** to determine how many jobs are current running/pending to determine how many can be prepped/submitted.   See **bin/run_storms.sh** below.

<hr>

### Populate TracksToRun 

run_storms.sh looks for **trk** files in **TracksToRun**, in order to set up and submit a simulation. 

Put track/event files to run in **TracksToRun**.  These are just empty files that the main script, **run_storms.sh**, looks for to set up and submit a simulation.  For Reanalysys, these files are <pre> <year\>.trk </pre>.  The "year" is then used to set run timing, locate forcing files, etc.  For the test/example, do 

<pre>touch TracksToRun/2018.trk</pre>

<hr>

### Copy/edit configs/config.yml

Copy/edit relevant config.yml file in configs.  The test config file is called 

<pre> ec95d_prior_config.yml </pre>

Model parameters for the test should not need changing.  

For a new "installation", 2 parameters at the top of the config file should be set for the local environment. Namely, 

<pre>
ProjectHome: Location of "installation" (e.g. /projects/reanalysis/forPTripp/ADCIRC)
ADCIRCHome: Location of ADCIRC executables (e.g. /home/bblanton/ADCIRC/renci.v56_dev_nws67/work)
</pre>

<hr>

### Run test

NumberOfConcurrentRuns = maximum number of concurrently pending/running simulations.

configfile="pathtoconfigfile.yml", default = configs/config.yml

To run the year 2018:  
<pre>
1. touch TracksToRun/2018.trk
2. Set NumberOfConcurrentRuns=1
3. Set configfile="configs/ec95d_prior_config.yml"
4. Run 
   sh bin/run_storms.sh --configfile $configfile --maxrun $NumberOfConcurrentRuns
</pre>

<hr>

### bin/run_storms.sh

This is the main script.  It parses the yaml file, looks for trk files in **TracksToRun**, preps a simulation and submits the job to a scheduler (slurm in RENCI's case).  For the test case, the only things that probably need modifying are 

1. The part that determines how many jobs are currently running/pending, lines 378,9:

<pre>
res=`eval $Job_StatusCommand`
NumberOfRunningJobs=`echo "$res" | grep $User | grep Reanalysis | wc -l `
</pre>

Jobs matching $User and Reanalysis are counted.  The run jobname is constructed as: 

<pre>
JobName=$Main_ProjectName.$ThisTrack.$GridNameAbbrev
</pre>

so as long as "Reanalysis" is in ProjectName (in the config.yml file), then this is probably OK.

2. The part that sets up the job control file, lines 895+, depending on the details of the local slurm configuration, or in the case of a different job namager, set up differently in conjunction with the job control template file.

Other relevant scripts needed by **run_storms.sh**

- bin/functions.sh - Utility functions, like the yaml parser
- bin/OwiTimes.sh - Gets wind forcing time/coord parameters from fort.22{1,2} files
- bin/mods.sh - modules to execute when the run_storms.sh script executes.  Currently commented out in line 79.  

The exec_me.sh script can be used to continually run run_storms.sh.


