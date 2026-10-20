# ZOMBIE_JOB_CHECKLIST.md

When running model executions within the `IOOS-Sandbox/cloudflow` codebase on AWS EC2 instances, scenarios can arise where a job stalls or loses communication without terminating, resulting in a **"zombie"** job. These uncommunicative processes waste computing allocations and accumulate cloud infrastructure costs.

This checklist outlines mandatory environment configurations, application hooks, manual intervention procedures, and health-check workflows to minimize and resolve zombie executions across all job types.

---

## Table of Contents

- [1. Standard MPI & Coastal Applications](#1-standard-mpi--coastal-applications)
- [2. Python MPI Applications (`mpi4py`)](#2-python-mpi-applications-mpi4py)
- [3. Python Dask Implementation](#3-python-dask-implementation)
  - [Fast-Fail Client & Scheduler Setup](#fast-fail-client--scheduler-setup)
  - [Manual Cleanup of Stalled Schedulers](#manual-cleanup-of-stalled-schedulers)
- [4. Live Job Health-Check Protocols](#4-live-job-health-check-protocols)
- [5. Terminating Stalled Jobs to Prevent Accrued Costs](#5-terminating-stalled-jobs-to-prevent-accrued-costs)

---

## 1. Standard MPI & Coastal Applications

For standard Intel MPI executions (e.g., SCHISM, OPEMP), export the following environment variables in your launch scripts to ensure dead or unresponsive ranks are aggressively purged by the MPI runtime rather than hanging indefinitely:

```bash
# Enable keepalive probes to detect hung/dead nodes or communication stalls
export I_MPI_HEARTBEAT=1  

# Enable heartbeat mechanism; extra time (seconds) given to a rank before cleanup
export I_MPI_EXTRA_TIMEOUT=60  

# Force Hydra to send a SIGKILL (9) instead of a SIGTERM (15) to all ranks
export I_MPI_JOB_ABORT_SIGNAL=9

# Ensure the job terminates immediately if any process exits with a non-zero status
export I_MPI_JOB_TIMEOUT_SIGNAL=9
```

## 2. Python MPI Applications (`mpi4py`)

While `mpirun -m mpi4py` manages `MPI_Init` / `MPI_Finalize` lifecycles and unbuffered stdout/stderr execution, **it does not catch unhandled Python exceptions across ranks by default**. If Rank $N$ throws a Python exception, it will crash while remaining ranks hang waiting at the next collective operation (`comm.barrier()`, `comm.gather()`).

### Implementation Steps

1. **Include Environment Flags:** Ensure the environment variables from [Section 1](#1-standard-mpi--coastal-applications) are present in your shell launch scripts. Basic run launcher scripts have already prescribed these conditions.
2. **Register Global Exception Hook:** Add the following boilerplate to your Python entrypoint (`tasks.py` or script head) to issue an explicit `comm.Abort(1)` on uncaught errors:

```python
import sys
import traceback
from mpi4py import MPI

def mpi_autokill_excepthook(type, value, tb):
    """
    Global exception hook to prevent MPI deadlocks on uncaught Python errors.
    Flushes stderr with the failing rank ID and forcibly aborts all MPI processes.
    """
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    
    sys.stderr.write(f"\n=======================================================\n")
    sys.stderr.write(f"CRITICAL: Uncaught exception on MPI Rank {rank}\n")
    sys.stderr.write(f"=======================================================\n")
    traceback.print_exception(type, value, tb, file=sys.stderr)
    sys.stderr.flush()
    
    # Forcefully terminate all ranks across the MPI communicator
    comm.Abort(1)

# Register hook globally
sys.excepthook = mpi_autokill_excepthook
```

## 3. Python Dask Implementation

### Fast-Fail Client & Scheduler Setup

Client configurations set via `dask.config.set(...)` enforce fast TCP connection and read/write timeouts (15–20 seconds) directly on the client, preventing it from hanging during network drops or node crashes. 

However, because `worker-ttl` (30 seconds) is a **scheduler-side policy**, setting it inside `dask.config.set(...)` around the `Client` only works if the scheduler process itself inherited or was launched with that configuration.

* Launch `dask-scheduler` with `DASK_DISTRIBUTED__SCHEDULER__WORKER_TTL=30s`.
* Enforce `retries=0` during task submissions.
* Handle `KilledWorker` from `distributed.scheduler` and general `RuntimeError`/`OSError` types during client execution (`client.gather()`).

### Manual Cleanup of Stalled Schedulers

If the head node experiences network saturation due to overall background jobs, your Dask scheduler may stall and lose connection to workers without raising an exception to Prefect. Follow these steps to manually kill the Dask scheduler, which will return an exception to your Prefect job and gracefully terminate your AWS instances:

1. **Identify the Dask scheduler process:**
   ```bash
   ps aux | grep -E "dask_scheduler|dask-scheduler"
   ```
*Example Output:*
   ```text
   ec2-user  249187 11.4  0.6 1045208 207248 pts/1  Sl+  12:40   0:02 /save/Jason_Ducker_miniforge3/miniforge3/envs/cloudflow/bin/python -s -m distributed.cli.dask_scheduler --host 10.26.36.207 --port 8786 --dashboard-address 0
   ```
2. **Force-kill the scheduler PID:**
   ```bash
   kill -9 249187
   ```

## 4. Live Job Health-Check Protocols

It is good practice to regularly check your model implementation for the following features to ensure the job is actively progressing:

1. **Master Output Progress:** Briefly check your master output file to ensure the model is still progressing in time.
   > ⚠️ **Caution:** Do not leave `tail -f output.log` running continuously. If you lose connection while actively pinging the output file across the mount, you can trigger a network error between the head node and instances, causing the model to randomly hang.
2. **Field Output Updating:** Verify that model output files (e.g., NetCDF files) are updating on disk as expected.
3. **Timestep Execution Delta:** Check the timestamp on the last iteration of your model time step to see if it has advanced within the past 10–30 minutes.

---

## 5. Terminating Stalled Jobs to Prevent Accrued Costs

If health checks indicate that your model is stuck in a zombie state, perform the following cleanup steps:

1. **Identify the specific launcher script PID:**
   ```bash
   ps aux | grep -E '\.sh'
   ```
*Example Output:*
   ```text
   ec2-user  350507  0.0  0.0   4688  3504 pts/4    S+   13:02   0:00 /bin/bash ./schism_basic_run.sh /save/hawaii 2 /save/schism/build/bin/pschism_BLD_STANDALONE_SH_MEM_COMM_TVD-VL
   ```
2. **Kill the launcher job:**
   ```bash
   kill -9 350507
   ```
Killing the launcher script returns a failure signal to Prefect, allowing it to gracefully terminate the assigned EC2 instances and prevent further cloud cost accumulation.


