const express = require('express');
const app = express();

const healthResponse = () => ({
  service: 'KijaniKiosk Payments',
  status: 'running',
  message: 'KijaniKiosk payments service is healthy',
  version: process.env.APP_VERSION || '1.0.0'
});

app.get('/', (req, res) => {
  res.json(healthResponse());
});

app.get('/health', (req, res) => {
  res.status(200).json(healthResponse());
});

const PORT = process.env.PORT || 3000;

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

module.exports = app;
