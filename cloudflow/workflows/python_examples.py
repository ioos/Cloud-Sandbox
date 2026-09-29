import time
import numpy as np
import dask.array as da
import xarray as xr
import s3fs
import logging
import os
import pandas as pd

# Get the specific logger that Dask is already watching
log = logging.getLogger("distributed.worker")

def dask_data_parallelism_example(file_path, output_root):
    """
    Dask data parallelism example: Demonstrates using
    isolated dataframes for each dask worker to read 
    in data, peform a task, and then save the data

    Args:
        file_path: The file name for a dasker worker to
        either read in data or save data to.

        output_root: The output directory to save data
        for each given dask worker dataframe

    Returns:
        The file output pathway that was saved by a 
        given dask worker
    """

    # A single dask worker will read and
    # process the data for a specific file
    time.sleep(1)
    file_name = os.path.basename(file_path)

    # Create dummy data dataframe for
    # a given dask worker to save the data
    df = pd.DataFrame({
        "source": [file_name],
        "processed_at": [time.ctime()],
        "status": ["Completed"]
    })

    # Define the output directory
    # Ensure the path exists (Workers can create directories on EFS)
    if not os.path.exists(output_root):
        os.makedirs(output_root, exist_ok=True)

    output_path = os.path.join(output_root, f"result_{file_name}.csv")

    # Dask worker writes from the AWS Worker directly to the EFS hardware
    # with its own dataframe it has read/constructed
    df.to_csv(output_path, index=False)

    log.info(f"Successfully wrote csv file {output_path}")

    return output_path


def dask_task_parallelism_example(aorc_year : int):
    """
    Dask task parallelism example: Demonstrates dask
    workers working together with the dask Client to load 
    a dataframe by chunks from a given s3 bucket, perform
    calculations on that dataframe, and return the final
    computed dataframe back to the dask Client to save the 
    output to the EFS hardware

    Args:
        aorc_year: A integer argument for which year to
        load the hourly AORC 1km CONUS data fields for

    Returns:
        The computed AORC grid field that yields boolean
        flags indicating missing or continuous temporal
        data for a given AORC grid cell
    """
    
    # Get s3 bucket path for AORC data fields
    # that are organized by annual chunks
    fs = s3fs.S3FileSystem(anon=True)
    s3_path = f"s3://noaa-nws-aorc-v1-1-1km/{aorc_year}.zarr"
    s3map = s3fs.S3Map(root=s3_path, s3=fs)
         
    log.info(f"Loading AORC data for year {aorc_year}")

    # Open the dataset lazily on the worker
    # Aggressive rechunking in time (1 week)
    ds = xr.open_zarr(s3map, chunks={'time': 168})

    # Select the first month of data to perform
    # computations just to speed up the example script
    ds = ds.isel(time=slice(0,744))

    # Convert to a single DataArray to check all 8 variables simultaneously
    # Select only data variables to keep the graph small
    data_vars = [v for v in ds.data_vars]
    da = ds[data_vars].to_array(dim='variable')

    # Compute boolean flags for each variable in dataframe
    # indicating where values are masked
    nan_mask_3d = None
    for var in ds.data_vars:
        m = ds[var].isnull()
        nan_mask_3d = m if nan_mask_3d is None else nan_mask_3d | m

    # Sum along time to see how many gappy hours exist per pixel
    nan_count_2d = nan_mask_3d.sum(dim='time')

    # Get total time steps for this specific year
    total_time = ds.sizes['time']

    # Calculate boolean fields that indicate if any variables
    # with the AORC dataframe contained missing data throughout
    # the entire timeseries 
    partial_gap_mask = (nan_count_2d > 0) & (nan_count_2d < total_time)

    log.info("Starting computation on dask workers for AORC data")

    # Return the dask computed fields by the workers to the dask Client
    # where we will then save the dataframe on the EFS hardware
    return partial_gap_mask.compute()

def load_and_process_xarray_example(chunk_size: int = 500):
    """
    A simple test case that generates synthetic data and
    performs a simple calculation. This function exists
    to just demonstrate a basic Python script execution
    on cloudflow for users
    """
    start_time = time.time()
    log.info(f"Starting test case with chunk_size: {chunk_size}")

    # Generate Synthetic 3D Data (e.g., Temperature over a grid)
    # Total size: (2000, 2000, 100)
    grid_lat = 2000
    grid_lon = 2000
    time_steps = 100

    # Create chunked dask array
    # This defines HOW the work is split across your AWS nodes
    data_points = da.random.random(
        (grid_lat, grid_lon, time_steps),
        chunks=(chunk_size, chunk_size, time_steps)
    )

    # Create Xarray Dataset
    ds = xr.Dataset(
        {"temperature": (("lat", "lon", "time"), data_points)},
        coords={
            "lat": np.linspace(-90, 90, grid_lat),
            "lon": np.linspace(-180, 180, grid_lon),
            "time": np.arange(time_steps),
        },
    )

    # Distributed Computation
    log.info("Calculating mean across time and finding global maximum...")
    
    
    # Global temperature maximum calculations
    result = ds.temperature.mean(dim="time").max().compute()

    duration = time.time() - start_time

    log.info("--------------------------------------------------")
    log.info(f"COMPUTATION COMPLETE")
    log.info(f"Final Result (Max Mean Temp): {result:.6f}")
    log.info(f"Total Execution Time: {duration:.2f} seconds")
    log.info("--------------------------------------------------")


# Main function defined here to run
# the basic Python script example
# as a proof of concept for users
def main():
    load_and_process_xarray_example(500)

# Run main when this Python script is 
# explicitly called by a Python executable
if __name__ == "__main__":
    main()

