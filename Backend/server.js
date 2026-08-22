require('dotenv').config();
const express = require('express');
const cors = require('cors');
const apiRoutes = require('./src/routes/api');
const errorHandler = require('./src/middleware/error');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// API Routes
app.use('/api', apiRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'UP',
    service: 'Maxion Wheels Dispatch Backend API',
    timestamp: new Date().toISOString(),
    version: '2.0.0'
  });
});

// Global Error Handler
app.use(errorHandler);

app.listen(PORT, () => {
  console.log(`=======================================================`);
  console.log(` Maxion Wheels Dispatch Operations Digitalization API `);
  console.log(` Server running on http://localhost:${PORT} `);
  console.log(` Environment: ${process.env.NODE_ENV || 'development'} `);
  console.log(`=======================================================`);
});
