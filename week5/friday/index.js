const express = require('express');
const crypto = require('crypto');
const {
  S3Client,
  PutObjectCommand
} = require('@aws-sdk/client-s3');

const app = express();

app.use(express.json());

const healthResponse = () => ({
  service: 'KijaniKiosk Payments',
  status: 'running',
  message: 'KijaniKiosk payments service is healthy',
  version: process.env.APP_VERSION || '1.0.0'
});

const createS3Client = () => {
  const configuration = {
    region: process.env.AWS_REGION || 'us-east-1',
    forcePathStyle: process.env.S3_FORCE_PATH_STYLE === 'true'
  };

  if (process.env.S3_ENDPOINT) {
    configuration.endpoint = process.env.S3_ENDPOINT;
  }

  if (
    process.env.AWS_ACCESS_KEY_ID &&
    process.env.AWS_SECRET_ACCESS_KEY
  ) {
    configuration.credentials = {
      accessKeyId: process.env.AWS_ACCESS_KEY_ID,
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
    };
  }

  return new S3Client(configuration);
};

app.get('/', (req, res) => {
  res.json(healthResponse());
});

app.get('/health', (req, res) => {
  res.status(200).json(healthResponse());
});

app.post('/payments', async (req, res) => {
  const amount = Number(req.body.amount);
  const currency = req.body.currency || 'KES';
  const customer = req.body.customer || 'UNKNOWN';

  if (!Number.isFinite(amount) || amount <= 0) {
    return res.status(400).json({
      error: 'amount must be a positive number'
    });
  }

  const paymentId =
    req.body.payment_id ||
    `PAY-${crypto.randomUUID()}`;

  const bucket = process.env.RECEIPT_BUCKET;

  if (!bucket) {
    return res.status(500).json({
      error: 'RECEIPT_BUCKET is not configured'
    });
  }

  const receipt = {
    payment_id: paymentId,
    amount,
    currency,
    customer,
    environment: process.env.NODE_ENV || 'unknown',
    created_at: new Date().toISOString()
  };

  const key = `${paymentId}.json`;

  try {
    const s3 = createS3Client();

    await s3.send(
      new PutObjectCommand({
        Bucket: bucket,
        Key: key,
        Body: JSON.stringify(receipt),
        ContentType: 'application/json'
      })
    );

    return res.status(202).json({
      status: 'accepted',
      payment_id: paymentId,
      receipt_bucket: bucket,
      receipt_key: key
    });
  } catch (error) {
    console.error(
      'Failed to write payment receipt:',
      error.message
    );

    return res.status(503).json({
      error: 'receipt storage unavailable',
      payment_id: paymentId
    });
  }
});

const PORT = process.env.PORT || 3000;

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

module.exports = app;
