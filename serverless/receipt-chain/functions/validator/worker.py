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

SOURCE_BUCKET = "kk-payments-receipts-staging"
TARGET_BUCKET = "kk-payments-validated-staging"

processed = set()

print("validator started", flush=True)

while True:
    response = s3.list_objects_v2(Bucket=SOURCE_BUCKET)

    for item in response.get("Contents", []):
        key = item["Key"]

        if key in processed:
            continue

        obj = s3.get_object(Bucket=SOURCE_BUCKET, Key=key)
        receipt = json.loads(obj["Body"].read())

        if not receipt.get("payment_id") or not receipt.get("amount"):
            print(f"validator rejected {key}", flush=True)
            processed.add(key)
            continue

        receipt["validated"] = True

        s3.put_object(
            Bucket=TARGET_BUCKET,
            Key=key,
            Body=json.dumps(receipt).encode(),
            ContentType="application/json",
        )

        print(f"validator processed {key}", flush=True)
        processed.add(key)

    time.sleep(2)
