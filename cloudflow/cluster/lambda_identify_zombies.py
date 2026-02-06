import json
import os
import time
import boto3
from botocore.exceptions import ClientError

TABLE_NAME = os.environ["TABLE_NAME"]
AWS_REGION = os.environ["AWS_REGION"]
ORG_MAX_MINUTES = int(os.environ["ORG_MAX_MINUTES"])
TERMINABLE_STATES = {"pending", "running", "stopping", "stopped"}

s3_client = boto3.client('s3')
ddb = boto3.resource("dynamodb", region_name=AWS_REGION)
table = ddb.Table(TABLE_NAME)
ec2 = boto3.client("ec2", region_name=AWS_REGION)
time_string = time.strftime('%Y-%m-%d-%H')
file_name = filename = f"IOOS_Coastal_Sandbox_Suspect_Report_{time_string}.html"

html_content = f"""
<!DOCTYPE html>
<html>
<head>
    <title>IOOS Coastal Sandbox Instance Monitor</title>
</head>
<body>
    <h1>Instances</h1>
    <p>Instances past their user alotted time: {expired_ids}</p>
    <p>Suspected Zombies: {suspect_ids}</p>
    <p>Successful shutdowns: {invalid_ids}</p>
    <p>Unsuccessful shutdowns i.e. failed to terminate: {failed_ids}</p>
    <p>Report Generated on: {time.strftime('%Y-%m-%d %H:%M:%S')}</p>
</body>
</html>
"""

def lambda_handler(event, context):
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

            #Can modify this later and base it on idle time from a cloudwatch monitor
            #Terminate instance if it has been running longer than max minutes
            #Or if start_time + ORG_MAX
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

    suspect_ids = []
    invalid_ids = []
    failed_ids = []

    for instance_id in expired_ids:

        try:
            print(f"Suspected instances: {expired_ids}")
            suspect_ids.append(instance_id)
        except ClientError as e:
            error_code = e.response["Error"].get("Code", "Unknown")

            if error_code == "InvalidInstanceID.NotFound":
                # Instance no longer exists — safe to clean up DB record
                print(f"Instance not found: {instance_id}")
                invalid_ids.append(instance_id)
            else:
                # Unexpected error — log and continue, should terminate next time around
                print(f"Failed to terminate {instance_id}: {error_code}")
                failed_ids.append(instance_id)

    instance_ids_to_delete = terminated_ids + invalid_ids

    # Delete the records from the database so the table reflects "currently running only"
    print(f"removing items from database: {instance_ids_to_delete}")
    with table.batch_writer() as batch:
        for iid in instance_ids_to_delete:
            batch.delete_item(Key={"instance-id": iid})

    print(f"Expired candidates: {len(expired_ids)}")
    print(f"Suspected: {len(suspect_ids)}")
    print(f"Invalid (already gone): {len(invalid_ids)}")
    print(f"Other failures: {len(failed_ids)}")
    
    #Write to HTML then push HTML to S3
    bucket_name = 'your-bucket-name'
    s3_key = f"monitoring/{file_name}"    
    s3_client.put_object(
        Bucket=bucket_name,
        Key=s3_key,
        Body=html_content,
        ContentType='text/html'
    )

    return {"expired": len(expired_ids), "terminated": len(terminated_ids), "deleted DB items": len(instance_ids_to_delete)}


if __name__ == '__main__':
    lambda_handler() 



