const express = require('express');
const medicineController = require('../controllers/medicine.controller');

const router = express.Router();

router.get('/', medicineController.getMedicines);

module.exports = router;
