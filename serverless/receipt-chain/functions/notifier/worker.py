import json
import os
import time
import boto3

s3 = boto3.client(
    "s3",
    endpoint_url=os.environ["S3_ENDPOINT"],
    aws_access_key_id=os.environ["AWS_ACCESS_KEY_ID"],
    aws_secret_access_key=os.environ["AWS_SECRET_ACCESS_KEY"],
    region_name="us-east-1",
)

SOURCE_BUCKET = "kk-payments-formatted-staging"
TARGET_BUCKET = "kk-payments-notifications-staging"

processed = set()

print("notifier started", flush=True)

while True:
    response = s3.list_objects_v2(Bucket=SOURCE_BUCKET)

    for item in response.get("Contents", []):
        key = item["Key"]

        if key in processed:
            continue

        obj = s3.get_object(Bucket=SOURCE_BUCKET, Key=key)
        receipt = json.loads(obj["Body"].read())

        notification = {
            "receipt_id": receipt["receipt_id"],
            "status": "NOTIFIED",
            "message": receipt["message"],
        }

        s3.put_object(
            Bucket=TARGET_BUCKET,
            Key=key,
            Body=json.dumps(notification).encode(),
            ContentType="application/json",
        )

        print(f"notifier processed {key}", flush=True)
        processed.add(key)

    time.sleep(2)
