const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');
require('dotenv').config();

const authRoutes = require('./routes/authRoutes');
const buyerRoutes = require('./routes/buyerRoutes');
const supplierRoutes = require('./routes/supplierRoutes');
const adminRoutes = require('./routes/adminRoutes');

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));
app.use(express.static(path.join(__dirname, '../public')));

// Simple rate limiter simulation
const ipRequestCounts = new Map();
app.use((req, res, next) => {
  const ip = req.ip;
  const now = Date.now();
  const timeframe = 60 * 1000; // 1 minute
  const maxRequests = 100; // max 100 requests per minute

  if (!ipRequestCounts.has(ip)) {
    ipRequestCounts.set(ip, []);
  }

  const requests = ipRequestCounts.get(ip).filter(time => now - time < timeframe);
  requests.push(now);
  ipRequestCounts.set(ip, requests);

  if (requests.length > maxRequests) {
    return res.status(429).json({ success: false, message: 'Too many requests, please try again later.' });
  }

  next();
});

// Root check API
app.get('/api/health', (req, res) => {
  const db = require('./config/db');
  res.status(200).json({
    success: true,
    message: 'BuildMart B2B Marketplace API is running successfully',
    timestamp: new Date(),
    dbMode: db.dbMode()
  });
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/buyer', buyerRoutes);
app.use('/api/supplier', supplierRoutes);
app.use('/api/admin', adminRoutes);

// Catch-all route to serve index.html for SPA (React Router client side routing)
app.get('*', (req, res, next) => {
  if (req.path.startsWith('/api')) {
    return next();
  }
  res.sendFile(path.join(__dirname, '../public/index.html'));
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('[GLOBAL ERROR HANDLER]:', err.stack);
  res.status(500).json({
    success: false,
    message: 'An unexpected internal error occurred on the server',
    error: process.env.NODE_ENV === 'development' ? err.message : {}
  });
});

module.exports = app;
