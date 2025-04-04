"""
s3bucket_boto_interaction.py 

PURPOSE : interact with s3 bucket using boto3
Will read and push data to s3 bucket

"""

#%%
import boto3
s3bucket = boto3.resource('s3')

#%%
bucket = s3bucket.Bucket('ioostestbucket')
for obj in bucket.objects.all():
    print(obj)
# %%
# ensuring the ownership of account

# Create an STS client
sts_client = boto3.client('sts')

# Call get_caller_identity to get the AWS account ID
response = sts_client.get_caller_identity()
account_id = response['Account']
print(f"Connected to AWS Account ID: {account_id}")
print(f"User ARN: {response['Arn']}")
# %%

# uploading a file to bucket
s3bucket2 = boto3.client('s3')
response =s3bucket2.upload_file(
            Filename='../Example Data/test.txt',
            Bucket='ioostestbucket',
            Key='test.txt')
        
# %%

# Printing all files from a bucket
print(s3bucket2.list_objects(Bucket='ioostestbucket'))

# reading a file 

s3bucket2.download_file('ioostestbucket', 'test.txt', 'test.txt')
# %%
