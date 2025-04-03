"""
Plotting_data.py
Purpose: Plot the combined data created in TimeSeries_Data_Exploration.py 
Explore multiple plotting functions for gridded data

"""

#%%# Import necessary libraries
import xarray as xr
import numpy as np
import matplotlib.pyplot as plt
import os
import scipy
import cartopy 
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from cartopy.mpl.ticker import LongitudeFormatter, LatitudeFormatter
import cmocean


# %%


# Loading the combined data
data = xr.load_dataset(r'Example Data/combined_data.nc') # load the combined data


# %%

combined_data = data.copy() #create a copy of the data
# Set up the map projection (Mercator is good for ocean data)
projection = ccrs.PlateCarree()

# Create a figure with subplots for each time step
fig, axes = plt.subplots(nrows=3, ncols=1, figsize=(10, 15), 
                         subplot_kw={'projection': projection})

# Plot surface temperature for each time step
for t in range(len(combined_data.ocean_time)):
    ax = axes[t]
    
    # Select surface temperature at this time step
    surface_temp = combined_data.temp.isel(ocean_time=t,s_rho=10)

    print(surface_temp.shape)
    print(surface_temp.to_dataframe())
    # Create the map
    ax.coastlines(resolution='110m')
    ax.add_feature(cfeature.LAND)
    ax.add_feature(cfeature.OCEAN)
    ax.gridlines(draw_labels=True)
    
    # Plot the temperature data
    p = ax.pcolormesh(combined_data.lon_rho, combined_data.lat_rho, surface_temp,
                      transform=ccrs.PlateCarree(),  # Data is in lat/lon coordinates
                      cmap=cmocean.cm.thermal,  # Use cmocean's thermal colormap
                      vmin=surface_temp.min(), vmax=surface_temp.max())
    
    # Add a colorbar
    plt.colorbar(p, ax=ax, label='Temperature (°C)')
    
    # Set title
    ax.set_title(f'Surface Temperature at {combined_data.ocean_time[t].values}')

plt.tight_layout()
plt.show()
# %%

import numpy as np
from scipy.ndimage import gaussian_filter1d

# Compute the spatially averaged surface temperature
surface_temp = combined_data.temp.isel(s_rho=19).mean(dim=['eta_rho', 'xi_rho'])

# Convert to numpy for smoothing
temp_values = surface_temp.values
time_values = combined_data.ocean_time.values

# Smooth the temperature data using a Gaussian filter
smoothed_temp = gaussian_filter1d(temp_values, sigma=1)  # Adjust sigma for more/less smoothing

# Plot the original and smoothed time series
plt.figure(figsize=(8, 4))
plt.plot(time_values, temp_values, marker='o', label='Original', color='blue')
plt.plot(time_values, smoothed_temp, label='Smoothed (Gaussian)', color='red')
plt.xlabel('Time')
plt.ylabel('Temperature (°C)')
plt.title('Spatially Averaged Surface Temperature (Smoothed)')
plt.grid(True)
plt.legend()
plt.show()
# %%

# Some data preprocessing to plot on curve
df = combined_data.temp.isel(ocean_time=0,s_rho=0).to_dataframe().reset_index()
df
print(df['lat_rho'].min(),df['lat_rho'].max())
print(df['lon_rho'].min(),df['lon_rho'].max())
# %%
# %%
# %%

# plot to highlight regions of data in the US MAP

# intializing figure
plt.figure(figsize=(10, 6))
m1= plt.axes(projection=ccrs.PlateCarree())

# adding features to the map
m1.add_feature(cfeature.LAND)
m1.add_feature(cfeature.OCEAN)
m1.gridlines(draw_labels=True)
m1.add_feature(cfeature.COASTLINE)
m1.add_feature(cfeature.BORDERS, linestyle=':')
m1.add_feature(cfeature.LAKES, color='lightblue')
m1.add_feature(cfeature.RIVERS, color='blue')
m1.add_feature(cfeature.STATES, linestyle=':')

# adding subset to see in the map 
m1.set_extent([-130,-60,20,35])

# plotting the data as a scatter plot to see the regions covered by the data
for i in df.itertuples():
    m1.plot(i.lon_rho,i.lat_rho,color='red',marker='o')
m1.stock_img()



# %%
