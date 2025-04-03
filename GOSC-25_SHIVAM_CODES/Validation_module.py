"""
Validation_module.py 
Purpose: Create RMSE error between 2 different NETCDF Files  
Assuming 2 model prediction files(at 6 hrs assuming one is predicted and one is observed) create a module for creating RMSE

"""

#%%%%

# Import necessary libraries
import xarray as xr
import numpy as np
import matplotlib.pyplot as plt
import os

# %%

# creating a class to preprocess data and evaluation code using RMSE after slicing entered by user
class Eval():
    def __init__(self, data1, data2):
        self.pred = data1
        self.actual = data2


# create a function taking preproceess data and calculate RMSE 
    def rmse(self,filter):
        
        # the dictionary passed will have key value pairs of {features:columns} for data sclicing
        if self.pred is None:
            print("Error: Dataset not loaded.")
            return None
        
        keys=list(filter.keys())
        values=list(filter.values())

        for i in range(len(keys)):
            pred_subset = self.pred['temp'].sel(**{keys[i]:slice(values[i][0], values[i][1])})
            actual_subset = self.actual['temp'].sel(**{keys[i]:slice(values[i][0], values[i][1])})
        # convert temp column to numpy array 
        
        pred_subset_df= pred_subset.to_dataframe().reset_index()
        actual_subset_df =actual_subset.to_dataframe().reset_index()

        pred_subset_df= pred_subset_df[~(pred_subset_df['temp'].isna())]['temp']
        actual_subset_df= actual_subset_df[~(actual_subset_df['temp'].isna())]['temp']
        
        # Calculate RMSE
        return np.sqrt(((pred_subset_df - actual_subset_df) ** 2).mean())
        


# %%

pred = xr.open_dataset("../Example Data/nos.cbofs.fields.f001.20231127.t00z.nc") # load predicted data for now
actual = xr.open_dataset("../Example Data/nos.cbofs.fields.f001.20231127.t06z.nc") # load actual data for now

#%%
eval = Eval(pred, actual)
filter= {"s_rho":[-0.975,-0.875]}
rmse = eval.rmse(filter)
print("RMSE extracted successfully")
print(f"RMSE is :{rmse}")
# %%
