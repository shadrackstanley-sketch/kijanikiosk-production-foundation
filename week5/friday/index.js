const express = require('express');

const app = express();

app.get('/', (req, res) => {
  res.json({
    service: 'KijaniKiosk Payments',
    status: 'running',
    version: process.env.APP_VERSION || '1.0.0'
  });
});

const PORT = process.env.PORT || 3000;

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

module.exports = app;
