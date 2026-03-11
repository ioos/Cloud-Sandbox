#! /usr/bin/python
import os
import time

import boto3

TABLE_NAME = os.environ["TABLE_NAME"]
AWS_REGION = os.environ["AWS_REGION"]
ORG_MAX_MINUTES = int(os.environ["ORG_MAX_MINUTES"])

s3_client = boto3.client("s3")
ddb = boto3.resource("dynamodb", region_name=AWS_REGION)
table = ddb.Table(TABLE_NAME)


def build_html_report(expired_ids, suspect_ids, terminated_ids, invalid_ids, failed_ids):
    """Build HTML report content for a single Lambda invocation.

    Parameters
    ----------
    expired_ids : list[str]
        Instance IDs that exceeded the allowed runtime.
    suspect_ids : list[str]
        Instance IDs identified as candidates.
    terminated_ids : list[str]
        Instance IDs successfully terminated.
    invalid_ids : list[str]
        Instance IDs already missing.
    failed_ids : list[str]
        Instance IDs that failed processing.

    Returns
    -------
    str
        HTML report body.
    """
    return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>IOOS Coastal Sandbox Instance Monitor</title>
        </head>
        <body>
            <h1>Instances</h1>
            <p>Instances past their user allotted time: {expired_ids}</p>
            <p>Suspected Zombies: {suspect_ids}</p>
            <p>Successful shutdowns: {terminated_ids}</p>
            <p>Already missing instances: {invalid_ids}</p>
            <p>Unsuccessful shutdowns i.e. failed to terminate: {failed_ids}</p>
            <p>Report Generated on: {time.strftime('%Y-%m-%d %H:%M:%S')}</p>
        </body>
        </html>
        """

def lambda_handler(event, context):
    """Scan records, identify expired instances, and upload an HTML report.

    Parameters
    ----------
    event : dict | None
        Lambda invocation event payload.
    context : object | None
        Lambda runtime context.

    Returns
    -------
    dict
        Counts for expired candidates, terminated instances, and deleted records.
    """
    now = int(time.time())

    expired_ids = []

    # Only fetch what we need
    scan_kwargs = {
        "ProjectionExpression": "#iid, #st",
        "ExpressionAttributeNames": {
            "#iid": "instance-id",
            "#st": "start-time",
        },
    }

    while True:
        resp = table.scan(**scan_kwargs)

        if not resp.get("Items", []):
            print("No instances found in database")

        for item in resp.get("Items", []):
            print(f"Item: {item}")
            try:
                instance_id = item["instance-id"]
                start_time = int(item["start-time"])
            except (KeyError, ValueError, TypeError):
                # Skip malformed items; optionally log/metrics here
                continue

            #Can modify this later and base it on idle time from a cloudwatch monitor
            #Terminate instance if it has been running longer than max minutes
            #Or if start_time + ORG_MAX
            #if (start_time + minutes_max * 60) <= now:
            if (start_time + ORG_MAX_MINUTES * 60) <= now:
                print(f"Found expired instance, {item}")
                expired_ids.append(instance_id)

        last_key = resp.get("LastEvaluatedKey")
        if not last_key:
            break
        scan_kwargs["ExclusiveStartKey"] = last_key

    if not expired_ids:
        return {"expired": 0, "terminated": 0, "deleted": 0}

    print(f"expired_ids: {expired_ids}")

    suspect_ids = []
    terminated_ids = []
    invalid_ids = []
    failed_ids = []

    for instance_id in expired_ids:
        # Termination is intentionally not performed in this function.
        print(f"Suspected instances: {expired_ids}")
        suspect_ids.append(instance_id)

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
    bucket_name = "ioos-transfers"
    time_string = time.strftime("%Y-%m-%d-%H")
    file_name = f"IOOS_Coastal_Sandbox_Suspect_Report_{time_string}.html"
    s3_key = f"monitoring/{file_name}"
    html_content = build_html_report(
        expired_ids=expired_ids,
        suspect_ids=suspect_ids,
        terminated_ids=terminated_ids,
        invalid_ids=invalid_ids,
        failed_ids=failed_ids,
    )

    s3_client.put_object(
        Bucket=bucket_name,
        Key=s3_key,
        Body=html_content,
        ContentType="text/html",
    )

    print(f"File uploaded successfully as {s3_key}")

    return {
        "expired": len(expired_ids),
        "terminated": len(terminated_ids),
        "deleted": len(instance_ids_to_delete),
    }


if __name__ == "__main__":
    lambda_handler(None, None)