"""
TimeSeries_Data_Exploration.py
Purpose: Load and explore the data of different time steps to get a flavour of timeseries data 
Handling multiple time periods data ,plotting and saving it

"""

#%%%%

# Import necessary libraries
import xarray as xr
import numpy as np
import matplotlib.pyplot as plt
import os

#%%%
# LOADING DATA 

loc = "../Example Data"  # specify folder where data will be loaded
files=  os.listdir(loc)  # list all files in the folder
print(files) # print the list of files
"""
we have 3 files for the same day but executed at gap of 6 hrs
these files are :
1.  nos.cbofs.fields.f001.20231127.t00z.nc
2.  nos.cbofs.fields.f001.20231127.t06z.nc
3 . nos.cbofs.fields.f001.20231127.t12z.nc
"""

data1  = xr.open_dataset(f"{files[0]}",engine='netcdf4')
data2  = xr.open_dataset(f"{files[1]}",engine='netcdf4')
data3  = xr.open_dataset(f"{files[2]}",engine='netcdf4')


# %%

"""
We would append temp data for all time-steps and create a combined data

Then we would slice data to create timeseries data for a specific location

Then we would try to plot the same

"""

datasets = [data1, data2, data3]

# Combine along the ocean_time dimension
combined_data = xr.concat(datasets, dim='ocean_time')

# Check the combined dataset
print(combined_data)


""" PLOTTING TEMP AT A SPECIFIC LOCATION """
specific_point_temp = combined_data.temp.isel(eta_rho=100, xi_rho=100, s_rho=19)

# Plot
plt.figure(figsize=(8, 4))
plt.plot(combined_data.ocean_time, specific_point_temp, marker='o', label='Temp at (eta_rho=100, xi_rho=100, s_rho=19)')
plt.xlabel('Time')
plt.ylabel('Temperature (°C)')
plt.title('Temperature Time Series at (eta_rho=100, xi_rho=100, s_rho=19 Surface)')
plt.grid(True)
plt.legend()
plt.show()

combined_data.to_netcdf('combined_data.nc') # save the combined data/

#%%
