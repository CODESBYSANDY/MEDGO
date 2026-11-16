const express = require('express');
const pharmacyController = require('../controllers/pharmacy.controller');

const router = express.Router();

router.get('/', pharmacyController.getNearbyPharmacies);
router.get('/:id', pharmacyController.getPharmacyById);

module.exports = router;
