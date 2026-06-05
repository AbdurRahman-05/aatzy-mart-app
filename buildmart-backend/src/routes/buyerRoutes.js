const express = require('express');
const router = express.Router();
const buyerController = require('../controllers/buyerController');
const { authenticate } = require('../middlewares/auth');

// Public Product/Service Browsing
router.get('/categories', buyerController.getCategories);
router.get('/products', buyerController.getProducts);
router.get('/products/:id', buyerController.getProductDetail);
router.get('/services', buyerController.getServices);
router.get('/news', buyerController.getNews);

// Authenticated Buyer Actions
router.post('/inquiries', authenticate, buyerController.sendInquiry);
router.get('/inquiries', authenticate, buyerController.getInquiries);
router.get('/inquiries/:id', authenticate, buyerController.getInquiryDetail);
router.post('/favorites', authenticate, buyerController.toggleFavorite);

module.exports = router;
