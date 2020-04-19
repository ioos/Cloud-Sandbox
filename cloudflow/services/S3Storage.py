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

    def __init__(self):
        print('init stub')


    def uploadFile(self, filename: str, bucket: str, key: str, public: bool = False):

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

        s3 = boto3.client('s3')
        try:
            s3.download_file(bucket, key, filename)
        except ClientError as e:
            log.error(e)
            raise Exception from e


    def file_exists(self, bucket: str, key: str) -> bool:

        s3 = boto3.client('s3')
        try:
            response = s3.head_object(Bucket=bucket,Key=key)
        except ClientError as e:
            log.error(e)
            return False

        return True



if __name__ == '__main__':
    pass
