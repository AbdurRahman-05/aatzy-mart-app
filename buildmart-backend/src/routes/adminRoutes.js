const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authenticate, authorize } = require('../middlewares/auth');

// All Admin actions secure
router.use(authenticate);
router.use(authorize(['admin']));

// Dashboard overview
router.get('/overview', adminController.getOverviewStats);

// User management
router.get('/users', adminController.getUsers);
router.put('/users/:id/status', adminController.toggleUserStatus);
router.delete('/users/:id', adminController.deleteUser);

// Supplier verification
router.get('/suppliers', adminController.getSuppliers);
router.put('/suppliers/:id/verify', adminController.verifySupplier);

// Product listing moderation
router.get('/products/pending', adminController.getPendingProducts);
router.put('/products/:id/moderate', adminController.moderateProduct);

// Category CRUD
router.post('/categories', adminController.createCategory);
router.put('/categories/:id', adminController.updateCategory);
router.delete('/categories/:id', adminController.deleteCategory);

module.exports = router;
