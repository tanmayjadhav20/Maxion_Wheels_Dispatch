require('dotenv').config();
const express = require('express');
const cors = require('cors');
const compression = require('compression');
const apiRoutes = require('./src/routes/api');
const errorHandler = require('./src/middleware/error');

const app = express();
const PORT = process.env.PORT || 5000;

app.disable('x-powered-by');
app.use(compression({ level: 6, threshold: 512 }));
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 86400
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(express.static('public', { maxAge: '1d', etag: true }));

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
