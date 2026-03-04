import time
import json
import logging
import math
import inspect
import getpass

from pathlib import Path

import boto3
from botocore.exceptions import ClientError

def put_instance_records(instance_ids: list[str]):

        print("PT in put_instance_records")
        table_name = "IOOS-Sandbox-Compute-Nodes"

        region='us-east-2'
        ddb = boto3.resource("dynamodb", region_name=region)
        table = ddb.Table(table_name)

        now = int(time.time())
        name_tag="Testing tag"

        with table.batch_writer() as batch:
            for iid in instance_ids:
                batch.put_item(Item={
                    "instance-id": iid,
                    "name-tag": name_tag,
                    "start-time": now,
                    "minutes-max": 120,
                    "username": "patrick"
                })


if __name__ == '__main__':
    instance_ids = [ "a12345", "b678910"]
    put_instance_records(instance_ids)
