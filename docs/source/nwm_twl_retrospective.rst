NWM TWL Retrospective
=====================

Overview
--------

The **NWM TWL Retrospective** workflow is designed to support the **National Water Model (NWM) Total Water Level (TWL)** analysis. This effort involves running retrospective references for the National Water Model v3 to generate data for TWL calculations.

Configuration
-------------

The primary configuration for this retrospective run is defined in the cloudflow job experiment file:
`cloudflow/job/jobs/MODEL_EXPERIMENTS/wrf_hydro.experiment`

.. code-block:: json

   {
     "MODEL"     : "WRF_HYDRO",
     "JOBTYPE"   : "wrf_hydro_experiment",
     "APP"       : "basic",
     "EXEC"      : "/save/ec2-user/OWP/chps-wrf-hydro/trunk/NWC/nwm.vX.X/sorc/nwm.fd/build/Run/wrf_hydro_NoahMP.exe",
     "MODEL_DIR" : "/save/ec2-user/OWP/NWM_v3_retrospective_run"
   }

This configuration points to the **NWM v3 retrospective run** directory.

Total Water Level (TWL)
-----------------------

*Placeholder for TWL Analysis Workflow*

Currently, the workflow focuses on the NWM output generation. Future updates will document the specific steps, scripts, or coupling required to derive Total Water Level from these retrospective runs and potentially other coastal models (e.g., ADCIRC, SCHISM).
