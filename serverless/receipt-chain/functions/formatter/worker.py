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

SOURCE_BUCKET = "kk-payments-validated-staging"
TARGET_BUCKET = "kk-payments-formatted-staging"

processed = set()

print("formatter started", flush=True)

while True:
    response = s3.list_objects_v2(Bucket=SOURCE_BUCKET)

    for item in response.get("Contents", []):
        key = item["Key"]

        if key in processed:
            continue

        obj = s3.get_object(Bucket=SOURCE_BUCKET, Key=key)
        receipt = json.loads(obj["Body"].read())

        formatted = {
            "receipt_id": receipt["payment_id"],
            "amount": receipt["amount"],
            "currency": receipt.get("currency", "KES"),
            "status": "VALIDATED",
            "message": f"Payment {receipt['payment_id']} received successfully",
        }

        s3.put_object(
            Bucket=TARGET_BUCKET,
            Key=key,
            Body=json.dumps(formatted).encode(),
            ContentType="application/json",
        )

        print(f"formatter processed {key}", flush=True)
        processed.add(key)

    time.sleep(2)
