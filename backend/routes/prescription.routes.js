const express = require('express');
const { prescriptionController, upload } = require('../controllers/prescription.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { requireRole } = require('../middleware/role.middleware');

const router = express.Router();

// Upload prescription (Customer only)
router.post(
  '/',
  authenticate,
  requireRole('CUSTOMER'),
  upload.single('image'),
  prescriptionController.uploadPrescription
);

// Get prescription details
router.get('/:id', authenticate, prescriptionController.getPrescriptionById);

// Update prescription verification status (Pharmacy Owner only)
router.patch(
  '/:id/status',
  authenticate,
  requireRole('PHARMACY_OWNER'),
  prescriptionController.updatePrescriptionStatus
);

module.exports = router;
