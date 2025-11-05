import time
import numpy as np
import dask.array as da
import xarray as xr


# --- 1. The Function to be Executed on the Dask Workers (REVISED for Xarray/Zarr) ---
def load_and_process_xarray_example(chunk_size : int):
    """
    Connects to the Dask cluster to load and process a mock Xarray/Zarr dataset.

    This demonstrates how the cluster resources are utilized for large, 
    array-based computations. In a real application, the 'mock_zarr_data'
    would be replaced by a line like:
    ds = xr.open_zarr('s3://your-bucket/data.zarr')

    Args:
        user_input: A user identifier or label for the job.

    Returns:
        A dictionary containing job results and resource metrics.
    """
    
    # NOTE: We cannot use get_worker() here because the initial Dask collection
    # (xarray/dask array) automatically uses the Client's default scheduler.
    # The actual Dask tasks (chunks) will be submitted to workers.

    start_time = time.time()
    
    # 1. Define Mock Zarr Data Structure
    # Simulate a very large 3D dataset that is chunked (like a Zarr store)
    array_size = (10 * chunk_size, 10 * chunk_size, 10) # ~10k x 10k x 10 elements
    
    # Create a Dask Array to simulate the chunked, lazy-loaded Zarr data
    # The chunks defined here reflect the parallel work units for the Dask workers
    mock_dask_array = da.random.random(
        array_size,
        chunks=(chunk_size, chunk_size, 10))
    
    # 2. Wrap Dask Array in an Xarray Dataset
    # This simulates opening a complex dataset (e.g., from Zarr)
    ds = xr.Dataset(
        {
            "temperature": (("lat", "lon", "time"), mock_dask_array),
        },
        coords={
            "lat": np.arange(array_size[0]),
            "lon": np.arange(array_size[1]),
            "time": np.arange(array_size[2]),
        }
    )
    
    # 3. Define and Execute the Distributed Task
    # Define a simple aggregation task (mean across all dimensions)
    # The .compute() call triggers the execution on the remote Dask cluster.
    print(f"Loading and computing distributed mean on {ds['temperature'].nbytes/1e9:.2f} GB (simulated) data...")
    
    # This is where the Dask Scheduler assigns chunks to Workers
    result_future = ds['temperature'].mean().compute()
    
    end_time = time.time()


# Create main function to run
# Python example with basic script
# execution on cloudflow instead 
# of the dask example
def main():
    load_and_process_xarray_example(100)

# Run main when this file is run
if __name__ == "__main__":
    main()

