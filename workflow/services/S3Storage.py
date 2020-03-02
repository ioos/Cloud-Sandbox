import logging

import boto3
from botocore.exceptions import ClientError

from services.StorageService import StorageService

__copyright__ = "Copyright © 2020 RPS Group. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "Kenny Ells, Brian McKenna, Patrick Tripp"

debug = False

log = logging.getLogger('workflow')
log.setLevel(logging.DEBUG)


class S3Storage(StorageService):

    def __init__(self):
        print('init stub')

    def uploadFile(self, filename: str, bucket: str, key: str, public: bool = False):

        if debug:
            print("DEBUG: filename: ", filename)
            print("DEBUG: key: ", key)
            print("DEBUG: bucket: ", bucket)

        s3 = boto3.client('s3')
        try:
            if public:
                s3.upload_file(filename, bucket, key, ExtraArgs={'ACL': 'public-read'})
            else:
                s3.upload_file(filename, bucket, key)
        except ClientError as e:
            log.error(e)
            raise Exception from e


if __name__ == '__main__':
    pass
