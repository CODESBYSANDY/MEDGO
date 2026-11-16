require('dotenv').config();
const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth.routes');
const pharmacyRoutes = require('./routes/pharmacy.routes');
const medicineRoutes = require('./routes/medicine.routes');
const prescriptionRoutes = require('./routes/prescription.routes');
const orderRoutes = require('./routes/order.routes');
const deliveryRoutes = require('./routes/delivery.routes');
const ownerRoutes = require('./routes/owner.routes');

const { prescriptionController } = require('./controllers/prescription.controller');
const { authenticate } = require('./middleware/auth.middleware');
const { errorHandler } = require('./middleware/error.middleware');
const { sendSuccess, sendError } = require('./utils/response');

const app = express();
const PORT = process.env.PORT || 5000;
const HOST = '0.0.0.0';

// Enable CORS for Flutter mobile/web/desktop development
app.use(
  cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'x-delivery-key'],
  })
);

// Body parsers
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health Check Endpoint
app.get('/health', (req, res) => {
  return sendSuccess(res, { status: 'healthy', timestamp: new Date().toISOString() }, 200);
});

app.get('/api/v1/health', (req, res) => {
  return sendSuccess(res, { status: 'healthy', timestamp: new Date().toISOString() }, 200);
});

// Mount Routes with /api/v1 prefix
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/pharmacies', pharmacyRoutes);
app.use('/api/v1/medicines', medicineRoutes);
app.use('/api/v1/prescriptions', prescriptionRoutes);

// Patient prescriptions route as specified in API contract
app.get('/api/v1/patients/:patientId/prescriptions', authenticate, prescriptionController.getPatientPrescriptions);

app.use('/api/v1/orders', orderRoutes);
app.use('/api/v1/delivery', deliveryRoutes);
app.use('/api/v1/owner', ownerRoutes);

// 404 Catch-All Handler
app.use('*', (req, res) => {
  return sendError(res, `Route ${req.originalUrl} not found`, 404);
});

// Centralized Error Handling Middleware
app.use(errorHandler);

// Only listen if not imported by test runner
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, HOST, () => {
    console.log(`====================================================`);
    console.log(` MEDGO Backend API Server running on http://${HOST}:${PORT}`);
    console.log(` API Base URL: http://${HOST}:${PORT}/api/v1`);
    console.log(` Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`====================================================`);
  });
}

module.exports = app;
