"""
s3bucket_boto_interaction.py 

PURPOSE : interact with s3 bucket using boto3
Will read and push data to s3 bucket

"""

#%%
class CloudDataHandler:
    def __init__(self, s3_bucket, s3_key, aws_access_key=None, aws_secret_key=None):
        """
        Initialize with S3 bucket details for in-situ data access.
        Args:
            s3_bucket (str): S3 bucket name
            s3_key (str): S3 object key (e.g., path to NetCDF file)
            aws_access_key (str, optional): AWS access key
            aws_secret_key (str, optional): AWS secret key
        """
        self.s3_bucket = s3_bucket
        self.s3_key = s3_key
        self.s3_path = f"s3://{s3_bucket}/{s3_key}"
        self.fs = fsspec.filesystem('s3', anon=False, 
                                   key=aws_access_key, secret=aws_secret_key)

    def inSituLoad(self, variables=None, time_slice=None, lat_slice=None, lon_slice=None):
        """
        Load specific data subsets in-situ using xarray and kerchunk.
        Args:
            variables (list, optional): Variables to load (e.g., ['temperature'])
            time_slice (slice, optional): Time range to subset
            lat_slice (slice, optional): Latitude range
            lon_slice (slice, optional): Longitude range
        Returns:
            xarray.Dataset: Subsetted dataset
        """
        # Create kerchunk reference for in-situ access
        with self.fs.open(self.s3_path) as infile:
            h5chunks = SingleHdf5ToZarr(infile, 'reference.json')
        ds = xr.open_dataset('reference.json', engine='kerchunk')
        
        # Apply filters
        if variables:
            ds = ds[variables]
        if time_slice:
            ds = ds.isel(time=time_slice)
        if lat_slice:
            ds = ds.isel(lat=lat_slice)
        if lon_slice:
            ds = ds.isel(lon=lon_slice)
        
        return ds

    def integrityCheck(self, ds):
        """
        Basic integrity check for dataset dimensions and completeness.
        Args:
            ds (xarray.Dataset): Dataset to check
        Returns:
            bool: True if intact, False otherwise
        """
        return all(dim > 0 for dim in ds.dims.values()) and not ds.isnull().all().all()

    def filterData(self, ds, time_range=None, lat_range=None, lon_range=None):
        """
        Apply user-defined filters to the dataset.
        Args:
            ds (xarray.Dataset): Dataset to filter
            time_range (tuple, optional): (start, end) time indices
            lat_range (tuple, optional): (start, end) latitude indices
            lon_range (tuple, optional): (start, end) longitude indices
        Returns:
            xarray.Dataset: Filtered dataset
        """
        if time_range:
            ds = ds.isel(time=slice(*time_range))
        if lat_range:
            ds = ds.isel(lat=slice(*lat_range))
        if lon_range:
            ds = ds.isel(lon=slice(*lon_range))
        return ds


# %%
