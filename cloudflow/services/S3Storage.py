import logging

import boto3
from botocore.exceptions import ClientError

from cloudflow.services.StorageService import StorageService

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

debug = False

log = logging.getLogger('workflow')
log.setLevel(logging.DEBUG)


class S3Storage(StorageService):
    """ Concrete implementation of the StorageService class """

    def __init__(self):
        return


    def uploadFile(self, filename: str, bucket: str, key: str, public: bool = False):
        """ Upload a file to S3

        Parameters
        ----------
        filename : str
            The path and filename to upload

        bucket : str
            The S3 bucket to use

        key : str
            The key to store the file as

        public : bool
            If file should be made publicly accessible or not

        Raises
        ------
        ClientError if unable to upload file

        """

        s3 = boto3.client('s3')
        try:
            if public:
                s3.upload_file(filename, bucket, key, ExtraArgs={'ACL': 'public-read'})
            else:
                s3.upload_file(filename, bucket, key)
        except ClientError as e:
            log.error(e)
            raise Exception from e


    def downloadFile(self, bucket: str, key: str, filename: str):
        """ Download a file from S3

        Parameters
        ----------
        bucket : str
            The S3 bucket to use

        key : str
            The key for the file

        filename : str
            The path and filename to save the file as

        Raises
        ------
        ClientError if unable to download file or file does not exist
        """

        s3 = boto3.client('s3')
        try:
            s3.download_file(bucket, key, filename)
        except ClientError as e:
            log.error(e)
            raise Exception from e


    def file_exists(self, bucket: str, key: str) -> bool:
        """ Test if the specified file exists in the S3 bucket

        Parameters
        ----------
        bucket : str
            The S3 bucket to use

        key : str
            The S3 key for the file to check

        Returns
        -------
        bool
            True if file exists
            False if file does not exist

        """
        s3 = boto3.client('s3')
        try:
            response = s3.head_object(Bucket=bucket,Key=key)
        except ClientError as e:
            log.error(e)
            return False

        return True



if __name__ == '__main__':
    pass
