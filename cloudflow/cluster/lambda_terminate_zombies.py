import json
import os
import time
import boto3
from botocore.exceptions import ClientError

#TABLE_NAME = os.environ["TABLE_NAME"]
#AWS_REGION = os.environ["AWS_REGION"]

TABLE_NAME = "IOOS-Sandbox-Compute-Nodes"
AWS_REGION = "us-east-2"
ORG_MAX_MINUTES = 5

ddb = boto3.resource("dynamodb", region_name=AWS_REGION)
table = ddb.Table(TABLE_NAME)
ec2 = boto3.client("ec2", region_name=AWS_REGION)

#def lambda_handler(event, context):
def lambda_handler():
    now = int(time.time())

    expired_ids = []

    # Only fetch what we need
    scan_kwargs = {
        "ProjectionExpression": "#iid, #st, #mm",
        "ExpressionAttributeNames": {
            "#iid": "instance-id",
            "#st": "start-time",
            "#mm": "minutes-max",
        },
    }

    while True:
        resp = table.scan(**scan_kwargs)

        if not resp.get("Items", []):
            print("No instances found in database")

        for item in resp.get("Items", []):
            print(f"Item: {item}")
            try:
                start_time = int(item["start-time"])
                minutes_max = int(item["minutes-max"])
            except (KeyError, ValueError, TypeError):
                # Skip malformed items; optionally log/metrics here
                continue

            # Or if start_time + ORG_MAX
            #if (start_time + minutes_max * 60) <= now:
            if (start_time + ORG_MAX_MINUTES * 60) <= now:
                print(f"Found expired instance, {item}")
                expired_ids.append(item["instance-id"])

        last_key = resp.get("LastEvaluatedKey")
        if not last_key:
            break
        scan_kwargs["ExclusiveStartKey"] = last_key

    if not expired_ids:
        return {"expired": 0, "terminated": 0, "deleted": 0}

    print(f"expired_ids: {expired_ids}")

    # Terminate instances (you are far below the 1000 ID limit)
    try:
        print(f"Terminating instances: {expired_ids}")
        ec2.terminate_instances(InstanceIds=expired_ids)
    except ClientError:
        # You may choose to continue to deletion anyway
        raise

    # Delete the records so the table reflects "currently running only"
    print(f"removing items from database: {expired_ids}")
    with table.batch_writer() as batch:
        for iid in expired_ids:
            batch.delete_item(Key={"instance-id": iid})

    return {"expired": len(expired_ids), "terminated": len(expired_ids), "deleted": len(expired_ids)}


if __name__ == '__main__':
    lambda_handler() 



