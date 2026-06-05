const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// Auth Endpoints
router.post('/register', authController.register);
router.post('/verify-otp', authController.verifyOtp);
router.post('/login', authController.login);
router.post('/google', authController.googleAuth);

module.exports = router;
