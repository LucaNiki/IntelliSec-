const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => res.json({status: 'ok', service: 'intellisec-backend'}));

app.get('/api/info', (req, res) => {
  res.json({
    name: 'IntelliSec',
    version: '0.1.0',
    description: 'AI-driven Security Platform - backend'
  });
});

// Simple LLM adapter stub (replace with real integration)
app.post('/api/llm/scan', async (req, res) => {
  const {text} = req.body;
  // stub response
  res.json({summary: `Scanned text length=${text ? text.length : 0}`, findings: []});
});

const port = process.env.PORT || 4000;
app.listen(port, () => console.log(`IntelliSec backend listening on ${port}`));
