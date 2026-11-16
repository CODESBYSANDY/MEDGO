const express = require('express');
const ownerController = require('../controllers/owner.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { requireRole } = require('../middleware/role.middleware');

const router = express.Router();

// All owner routes require authentication and PHARMACY_OWNER role
router.use(authenticate, requireRole('PHARMACY_OWNER'));

// Owner dashboard metrics
router.get('/dashboard', ownerController.getDashboard);

// Owner incoming orders
router.get('/orders', ownerController.getOwnerOrders);

// Pharmacy availability toggle (default owner pharmacy or specific id)
router.patch('/pharmacy/availability', ownerController.updateAvailability);
router.patch('/pharmacies/:id/availability', ownerController.updateAvailability);

module.exports = router;
