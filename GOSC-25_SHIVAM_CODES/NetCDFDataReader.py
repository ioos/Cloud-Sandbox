"""
NetCDFDataReader.py
Purpose: Load and manipulate netCDF data (e.g., CBOFS) using xarray for ocean model analysis. 
Explore data attributes, variables, and perform basic data manipulation.

"""
#%%%%

# Import necessary libraries
import xarray as xr
import numpy as np
import matplotlib.pyplot as plt

#%%%

class NetCDFDataReader:
    """
     Create class to load netcdf file and explore its functionalities
    """
    def __init__(self, file_path): # constructor for initializing the class
        
        
        self.file_path = file_path
        self.dataset = None

    def load_data(self):      # fucntion for reading a netcdf file from specified file path

        try:
            self.dataset = xr.open_dataset(self.file_path, decode_times=True)  #load the dataset 
            print("Dataset loaded successfully.")
            return self.dataset
        except Exception as e:
            print(f"Error loading dataset: {e}")
            return None

    def get_subset(self, **kwargs): # function for extracting a subset of the dataset based on time, latitude, and longitude ranges
        
        # the dictionary passed will have key value pairs of {features:columns} for data sclicing
        if self.dataset is None:
            print("Error: Dataset not loaded.")
            return None
        try:
            keys=list(kwargs.get('features'))
            values=list(kwargs.get('columns'))
            subset = self.dataset.sel(**{keys[0]:slice(values[0], values[1])})
            subset = self.dataset.sel(
            
            print("Subset extracted successfully.")
            return subset
        except Exception as e:
            print(f"Error extracting subset: {e}")
            return None


# %%

# for demonstration purpose using a netcdf file hosted on opendap server
file_loc = 'https://opendap1.nodc.no/opendap/physics/point/cruise/nansen_legacy-single_profile/NMDC_Nansen-Legacy_PR_CT_58US_2021708/CTD_station_P1_NLEG01-1_-_Nansen_Legacy_Cruise_-_2021_Joint_Cruise_2-1.nc'
# create an instance of the NetCDFDataReader class
ncd = NetCDFDataReader(file_loc)
data =ncd.load_data() # load the data
print(data)
# %%
# exploring the dimenisons, variales and attrivutes of data

""" Dimensions"""
print(data.dims) # print the dimensions of the dataset 
# output is ({'PRES': 320}) so it has data across 320 values of pressure 


"""Exploring the Temp vars"""
print(data['TEMP']) # print the data of the dataset for TEMP variable
print(data['TEMP'].to_dataframe()) # print the data of the dataset for TEMP variable in pandas dataframe format


"""Attributes"""
print(data.attrs) # print the attributes of the dataset
# output is a dictionary of attributes of the dataset
# %%
