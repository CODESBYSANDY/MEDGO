const express = require('express');
const { deliveryController, authenticateDeliveryPartner } = require('../controllers/delivery.controller');

const router = express.Router();

// Demo auth endpoint to get a delivery JWT
router.post('/auth', deliveryController.getDemoToken);

// Verify QR token (Delivery partner only)
router.post('/verify', authenticateDeliveryPartner, deliveryController.verifyQr);

// Update delivery status (Delivery partner only)
router.patch('/:orderId/status', authenticateDeliveryPartner, deliveryController.updateStatus);

module.exports = router;
