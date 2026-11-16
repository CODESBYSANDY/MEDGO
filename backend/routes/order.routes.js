const express = require('express');
const orderController = require('../controllers/order.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { requireRole } = require('../middleware/role.middleware');

const router = express.Router();

// Create order (Customer only)
router.post('/', authenticate, requireRole('CUSTOMER'), orderController.createOrder);

// Get order details (Customer or Pharmacy Owner)
router.get('/:id', authenticate, orderController.getOrderById);

// Update order status
router.patch('/:id/status', authenticate, orderController.updateOrderStatus);

// Generate parcel QR token (Pharmacy Owner only)
router.post(
  '/:id/qr',
  authenticate,
  requireRole('PHARMACY_OWNER'),
  orderController.generateParcelToken
);

module.exports = router;
