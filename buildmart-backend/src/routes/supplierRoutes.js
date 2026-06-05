const express = require('express');
const router = express.Router();
const supplierController = require('../controllers/supplierController');
const { authenticate, authorize } = require('../middlewares/auth');

// Apply auth + role verification to all supplier routes
router.use(authenticate);
router.use(authorize(['supplier']));

// Dashboard Stats
router.get('/dashboard', supplierController.getDashboardStats);

// Profile Management
router.put('/profile', supplierController.updateProfile);

// Product CRUD
router.get('/products', supplierController.getProducts);
router.post('/products', supplierController.addProduct);
router.put('/products/:id', supplierController.updateProduct);
router.delete('/products/:id', supplierController.deleteProduct);

// Service CRUD
router.get('/services', supplierController.getServices);
router.post('/services', supplierController.addService);
router.delete('/services/:id', supplierController.deleteService);

// Leads Management
router.get('/leads', supplierController.getLeads);
router.put('/leads/:id/status', supplierController.updateLeadStatus);

module.exports = router;
