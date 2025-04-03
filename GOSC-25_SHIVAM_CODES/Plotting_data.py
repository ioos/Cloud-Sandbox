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

# %%

# Loading the combined data
data = xr.load_dataset(r'Example Data/combined_data.nc') # load the combined data
data

# %%
