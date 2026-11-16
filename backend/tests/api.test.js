process.env.NODE_ENV = 'test';
process.env.PORT = '5001';
process.env.JWT_SECRET = 'test_jwt_secret_medgo_2026';
process.env.DELIVERY_API_KEY = 'medgo-delivery-demo-key-2026';

const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const crypto = require('crypto');

const { MockSupabase } = require('./mockSupabase');
const { setSupabaseClientForTesting } = require('../config/supabase');

// Set up mock DB
const mockDb = new MockSupabase();
setSupabaseClientForTesting(mockDb);

const app = require('../server');

test('MEDGO Complete Backend End-to-End Test Suite', async (t) => {
  let customerToken = '';
  let customerUser = null;
  let ownerToken = '';
  let ownerUser = null;
  let deliveryKey = 'medgo-delivery-demo-key-2026';

  let testPharmacyId = 'c1111111-1111-1111-1111-111111111111'; // Sri Medicals
  let testMedicineId = '11111111-0000-0000-0000-000000000001'; // Paracetamol 500mg
  let rxMedicineId = '11111111-0000-0000-0000-000000000002';   // Amoxicillin 500mg (requires prescription)
  let testPrescriptionId = 'e1111111-1111-1111-1111-111111111111'; // PENDING rx for PAT1001
  let createdOrderId = '';
  let generatedQrToken = '';

  // --------------------------------------------------------------------------
  // 1. Customer registration
  // --------------------------------------------------------------------------
  await t.test('1. Customer registration - POST /api/v1/auth/register', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Kavitha Raj',
        email: 'kavitha@gmail.com',
        phone: '9876543299',
        password: 'password123',
        role: 'CUSTOMER',
      });

    if (res.status !== 201) {
      console.log('Test 10 Failure Details:', res.status, res.body);
    }
    assert.equal(res.status, 201);
    assert.equal(res.body.success, true);
    assert.ok(res.body.data.user.id);
    assert.equal(res.body.data.user.email, 'kavitha@gmail.com');
    assert.equal(res.body.data.user.role, 'CUSTOMER');
    assert.equal(res.body.data.user.password_hash, undefined, 'Must not expose password_hash');
  });

  // --------------------------------------------------------------------------
  // 2. Customer login
  // --------------------------------------------------------------------------
  await t.test('2. Customer login - POST /api/v1/auth/login', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'arun@gmail.com',
        password: '123456',
      });

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.ok(res.body.data.token);
    assert.equal(res.body.data.user.role, 'CUSTOMER');
    assert.equal(res.body.data.user.email, 'arun@gmail.com');

    customerToken = res.body.data.token;
    customerUser = res.body.data.user;
  });

  // --------------------------------------------------------------------------
  // 3. Pharmacy owner login
  // --------------------------------------------------------------------------
  await t.test('3. Pharmacy owner login - POST /api/v1/auth/login', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'ramesh@gmail.com',
        password: '123456',
      });

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.ok(res.body.data.token);
    assert.equal(res.body.data.user.role, 'PHARMACY_OWNER');

    ownerToken = res.body.data.token;
    ownerUser = res.body.data.user;
  });

  // --------------------------------------------------------------------------
  // 4. Get current user
  // --------------------------------------------------------------------------
  await t.test('4. Get current user - GET /api/v1/auth/me', async () => {
    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${customerToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(res.body.data.user.id, customerUser.id);
    assert.equal(res.body.data.user.email, 'arun@gmail.com');
  });

  // --------------------------------------------------------------------------
  // 5. Retrieve nearby pharmacies
  // --------------------------------------------------------------------------
  await t.test('5. Retrieve nearby pharmacies - GET /api/v1/pharmacies', async () => {
    const res = await request(app)
      .get('/api/v1/pharmacies?lat=9.9252&lng=78.1198&radius_km=5');

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.ok(Array.isArray(res.body.data));
    assert.ok(res.body.data.length > 0);

    const firstPharm = res.body.data[0];
    assert.ok(firstPharm.id);
    assert.ok(firstPharm.name);
    assert.ok(firstPharm.owner_name);
    assert.ok(typeof firstPharm.distance_km === 'number');
    assert.ok(typeof firstPharm.is_open === 'boolean');
  });

  // --------------------------------------------------------------------------
  // 6. Get pharmacy details
  // --------------------------------------------------------------------------
  await t.test('6. Get pharmacy details - GET /api/v1/pharmacies/:id', async () => {
    const res = await request(app).get(`/api/v1/pharmacies/${testPharmacyId}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(res.body.data.id, testPharmacyId);
    assert.equal(res.body.data.name, 'Sri Medicals');
    assert.equal(res.body.data.owner_name, 'Ramesh');
  });

  // --------------------------------------------------------------------------
  // 7. Search medicines
  // --------------------------------------------------------------------------
  await t.test('7. Search medicines - GET /api/v1/medicines', async () => {
    const res = await request(app).get(
      `/api/v1/medicines?search=paracetamol&pharmacy_id=${testPharmacyId}`
    );

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.ok(Array.isArray(res.body.data));
    assert.equal(res.body.data.length, 1);
    assert.equal(res.body.data[0].name, 'Paracetamol 500mg');
    assert.equal(res.body.data[0].price, 25);
    assert.equal(res.body.data[0].requires_prescription, false);
  });

  // --------------------------------------------------------------------------
  // 8. Upload prescription
  // --------------------------------------------------------------------------
  await t.test('8. Upload prescription - POST /api/v1/prescriptions', async () => {
    const buffer = Buffer.from('fake-image-bytes-png');

    const res = await request(app)
      .post('/api/v1/prescriptions')
      .set('Authorization', `Bearer ${customerToken}`)
      .field('patient_id', 'PAT1001')
      .attach('image', buffer, 'prescription.png');

    if (res.status !== 201) {
      console.log('Test 10 Failure Details:', res.status, res.body);
    }
    assert.equal(res.status, 201);
    assert.equal(res.body.success, true);
    assert.ok(res.body.data.id);
    assert.equal(res.body.data.patient_id, 'PAT1001');
    assert.equal(res.body.data.status, 'PENDING');
  });

  // --------------------------------------------------------------------------
  // 9. Retrieve authorized patient prescriptions
  // --------------------------------------------------------------------------
  await t.test('9. Retrieve patient prescriptions - GET /api/v1/patients/:patientId/prescriptions', async () => {
    const res = await request(app)
      .get('/api/v1/patients/PAT1001/prescriptions')
      .set('Authorization', `Bearer ${customerToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.ok(Array.isArray(res.body.data));
    assert.ok(res.body.data.length > 0);
    assert.equal(res.body.data[0].patient_id, 'PAT1001');
    assert.equal(res.body.data[0].doctor_name, 'Dr. Kumar');
    assert.ok(Array.isArray(res.body.data[0].medicines));
  });

  // --------------------------------------------------------------------------
  // 10. Create order
  // --------------------------------------------------------------------------
  await t.test('10. Create order - POST /api/v1/orders', async () => {
    const res = await request(app)
      .post('/api/v1/orders')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        pharmacy_id: testPharmacyId,
        prescription_id: testPrescriptionId,
        items: [
          { medicine_id: testMedicineId, quantity: 2 },
          { medicine_id: rxMedicineId, quantity: 1 },
        ],
      });

    if (res.status !== 201) {
      console.log('Test 10 Failure Details:', res.status, res.body);
    }
    assert.equal(res.status, 201);
    assert.equal(res.body.success, true);
    assert.ok(res.body.data.id);
    assert.equal(res.body.data.status, 'ORDER_PLACED');
    // Total: (25 * 2) + (85 * 1) = 135
    assert.equal(res.body.data.total_amount, 135);
    assert.equal(res.body.data.pharmacy_id, testPharmacyId);

    createdOrderId = res.body.data.id;
  });

  // --------------------------------------------------------------------------
  // 11. Owner retrieves incoming order
  // --------------------------------------------------------------------------
  await t.test('11. Owner retrieves incoming orders - GET /api/v1/owner/orders', async () => {
    const res = await request(app)
      .get('/api/v1/owner/orders')
      .set('Authorization', `Bearer ${ownerToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.ok(Array.isArray(res.body.data));
    const orderFound = res.body.data.find((o) => o.id === createdOrderId);
    assert.ok(orderFound, 'Owner must find the placed order');
    assert.equal(orderFound.customer_name, 'Arun Kumar');
    assert.equal(orderFound.status, 'ORDER_PLACED');
  });

  // --------------------------------------------------------------------------
  // 12. Owner accepts order
  // --------------------------------------------------------------------------
  await t.test('12. Owner accepts order - PATCH /api/v1/orders/:id/status', async () => {
    const res = await request(app)
      .patch(`/api/v1/orders/${createdOrderId}/status`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ status: 'PHARMACY_ACCEPTED' });

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(res.body.data.status, 'PHARMACY_ACCEPTED');
  });

  // --------------------------------------------------------------------------
  // 13. Owner verifies prescription
  // --------------------------------------------------------------------------
  await t.test('13. Owner verifies prescription - PATCH /api/v1/prescriptions/:id/status & order', async () => {
    // Verify prescription
    const rxRes = await request(app)
      .patch(`/api/v1/prescriptions/${testPrescriptionId}/status`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ status: 'VERIFIED' });

    assert.equal(rxRes.status, 200);
    assert.equal(rxRes.body.data.status, 'VERIFIED');

    // Transition order to PRESCRIPTION_VERIFIED
    const orderRes = await request(app)
      .patch(`/api/v1/orders/${createdOrderId}/status`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ status: 'PRESCRIPTION_VERIFIED' });

    assert.equal(orderRes.status, 200);
    assert.equal(orderRes.body.data.status, 'PRESCRIPTION_VERIFIED');
  });

  // --------------------------------------------------------------------------
  // 14. Owner marks medicines packed
  // --------------------------------------------------------------------------
  await t.test('14. Owner marks medicines packed - PATCH /api/v1/orders/:id/status', async () => {
    const res = await request(app)
      .patch(`/api/v1/orders/${createdOrderId}/status`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ status: 'MEDICINES_PACKED' });

    assert.equal(res.status, 200);
    assert.equal(res.body.data.status, 'MEDICINES_PACKED');
  });

  // --------------------------------------------------------------------------
  // 15. Generate QR token
  // --------------------------------------------------------------------------
  await t.test('15. Generate parcel QR token - POST /api/v1/orders/:id/qr', async () => {
    const res = await request(app)
      .post(`/api/v1/orders/${createdOrderId}/qr`)
      .set('Authorization', `Bearer ${ownerToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.ok(res.body.data.qr_token);
    assert.equal(res.body.data.order_id, createdOrderId);
    assert.equal(res.body.data.status, 'READY_FOR_PICKUP');

    generatedQrToken = res.body.data.qr_token;
  });

  // --------------------------------------------------------------------------
  // 16. Delivery partner verifies QR
  // --------------------------------------------------------------------------
  await t.test('16. Delivery partner verifies QR - POST /api/v1/delivery/verify', async () => {
    const res = await request(app)
      .post('/api/v1/delivery/verify')
      .set('x-delivery-key', deliveryKey)
      .send({ qr_token: generatedQrToken });

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(res.body.data.order_id, createdOrderId);
    assert.equal(res.body.data.status, 'READY_FOR_PICKUP');
    assert.equal(res.body.data.verified, true);
  });

  // --------------------------------------------------------------------------
  // 17. Delivery partner marks pickup
  // --------------------------------------------------------------------------
  await t.test('17. Delivery partner marks pickup - PATCH /api/v1/delivery/:orderId/status', async () => {
    const res = await request(app)
      .patch(`/api/v1/delivery/${createdOrderId}/status`)
      .set('x-delivery-key', deliveryKey)
      .send({ status: 'PICKED_UP' });

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(res.body.data.status, 'PICKED_UP');
  });

  // --------------------------------------------------------------------------
  // 18. Delivery partner marks delivered
  // --------------------------------------------------------------------------
  await t.test('18. Delivery partner marks delivered - PATCH /api/v1/delivery/:orderId/status', async () => {
    const res = await request(app)
      .patch(`/api/v1/delivery/${createdOrderId}/status`)
      .set('x-delivery-key', deliveryKey)
      .send({ status: 'DELIVERED' });

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(res.body.data.status, 'DELIVERED');
  });

  // --------------------------------------------------------------------------
  // 19. Customer retrieves final order status
  // --------------------------------------------------------------------------
  await t.test('19. Customer retrieves final order status - GET /api/v1/orders/:id', async () => {
    const res = await request(app)
      .get(`/api/v1/orders/${createdOrderId}`)
      .set('Authorization', `Bearer ${customerToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(res.body.data.id, createdOrderId);
    assert.equal(res.body.data.status, 'DELIVERED');
    assert.equal(res.body.data.total_amount, 135);
    assert.equal(res.body.data.pharmacy_name, 'Sri Medicals');
  });

  // --------------------------------------------------------------------------
  // INVALID REQUEST TESTS
  // --------------------------------------------------------------------------

  // 20. Wrong password
  await t.test('20. Wrong password returns 401', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'arun@gmail.com', password: 'wrongpassword' });

    assert.equal(res.status, 401);
    assert.equal(res.body.success, false);
    assert.equal(res.body.message, 'Invalid email or password');
  });

  // 21. Duplicate email
  await t.test('21. Duplicate email returns 409', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Arun Duplicate',
        email: 'arun@gmail.com',
        phone: '9876543210',
        password: 'password123',
        role: 'CUSTOMER',
      });

    assert.equal(res.status, 409);
    assert.equal(res.body.success, false);
    assert.equal(res.body.message, 'Email is already registered');
  });

  // 22. Missing JWT
  await t.test('22. Missing JWT returns 401', async () => {
    const res = await request(app).get('/api/v1/auth/me');

    assert.equal(res.status, 401);
    assert.equal(res.body.success, false);
  });

  // 23. Wrong role
  await t.test('23. Customer accessing owner dashboard returns 403', async () => {
    const res = await request(app)
      .get('/api/v1/owner/dashboard')
      .set('Authorization', `Bearer ${customerToken}`);

    assert.equal(res.status, 403);
    assert.equal(res.body.success, false);
  });

  // 24. Unauthorized prescription access
  await t.test('24. Customer accessing another customer patient records returns 403', async () => {
    const res = await request(app)
      .get('/api/v1/patients/PAT1002/prescriptions') // PAT1002 belongs to Priya
      .set('Authorization', `Bearer ${customerToken}`);

    assert.equal(res.status, 403);
    assert.equal(res.body.success, false);
  });

  // 25. Unauthorized order access
  await t.test('25. Unauthorized order access returns 403', async () => {
    // Login as second customer (Priya)
    const priyaRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'priya@gmail.com', password: '123456' });

    const priyaToken = priyaRes.body.data.token;

    // Priya tries to view Arun's order
    const res = await request(app)
      .get(`/api/v1/orders/${createdOrderId}`)
      .set('Authorization', `Bearer ${priyaToken}`);

    assert.equal(res.status, 403);
    assert.equal(res.body.success, false);
  });

  // 26. Invalid medicine ID
  await t.test('26. Invalid medicine ID returns 404', async () => {
    const res = await request(app)
      .post('/api/v1/orders')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        pharmacy_id: testPharmacyId,
        items: [{ medicine_id: '00000000-0000-0000-0000-000000000099', quantity: 1 }],
      });

    assert.equal(res.status, 404);
    assert.equal(res.body.success, false);
  });

  // 27. Insufficient stock
  await t.test('27. Insufficient stock returns 400', async () => {
    const res = await request(app)
      .post('/api/v1/orders')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        pharmacy_id: testPharmacyId,
        items: [{ medicine_id: testMedicineId, quantity: 999999 }],
      });

    assert.equal(res.status, 400);
    assert.equal(res.body.success, false);
    assert.ok(res.body.message.includes('Insufficient stock'));
  });

  // 28. Invalid status transition
  await t.test('28. Invalid status transition returns 400', async () => {
    // Create a new fresh order
    const newOrderRes = await request(app)
      .post('/api/v1/orders')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        pharmacy_id: testPharmacyId,
        items: [{ medicine_id: testMedicineId, quantity: 1 }],
      });

    const freshOrderId = newOrderRes.body.data.id;

    // Attempt illegal jump from ORDER_PLACED directly to READY_FOR_PICKUP
    const res = await request(app)
      .patch(`/api/v1/orders/${freshOrderId}/status`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ status: 'READY_FOR_PICKUP' });

    assert.equal(res.status, 400);
    assert.equal(res.body.success, false);
  });

  // 29. Expired QR token
  await t.test('29. Expired QR token returns 400', async () => {
    // Insert an expired token manually into mockDb
    const expiredToken = 'expired-token-123';
    const hash = crypto.createHash('sha256').update(expiredToken).digest('hex');

    mockDb.tables.deliveries.push({
      id: 'del-expired-uuid',
      order_id: 'order-expired-uuid',
      qr_token_hash: hash,
      partner_status: 'READY_FOR_PICKUP',
      qr_expires_at: new Date(Date.now() - 10000).toISOString(), // in the past
      is_redeemed: false,
    });
    mockDb.tables.orders.push({
      id: 'order-expired-uuid',
      status: 'READY_FOR_PICKUP',
      pharmacy_id: testPharmacyId,
    });

    const res = await request(app)
      .post('/api/v1/delivery/verify')
      .set('x-delivery-key', deliveryKey)
      .send({ qr_token: expiredToken });

    assert.equal(res.status, 400);
    assert.equal(res.body.success, false);
    assert.ok(res.body.message.includes('expired'));
  });

  // 30. Reused QR token
  await t.test('30. Reused QR token returns 400 (replay attack prevented)', async () => {
    const res = await request(app)
      .post('/api/v1/delivery/verify')
      .set('x-delivery-key', deliveryKey)
      .send({ qr_token: generatedQrToken });

    assert.equal(res.status, 400);
    assert.equal(res.body.success, false);
    assert.ok(res.body.message.includes('already been redeemed'));
  });

  // --------------------------------------------------------------------------
  // ADDITIONAL FEATURE & RESILIENCE TESTS
  // --------------------------------------------------------------------------

  // 31. Owner updates pharmacy availability
  await t.test('31. Owner updates pharmacy availability - PATCH /api/v1/owner/pharmacy/availability', async () => {
    const res = await request(app)
      .patch('/api/v1/owner/pharmacy/availability')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ is_open: false });

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(res.body.data.is_open, false);

    // Toggle back to true
    const resBack = await request(app)
      .patch('/api/v1/owner/pharmacy/availability')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ is_open: true });

    assert.equal(resBack.status, 200);
    assert.equal(resBack.body.data.is_open, true);
  });

  // 32. Owner dashboard metrics
  await t.test('32. Owner dashboard metrics - GET /api/v1/owner/dashboard', async () => {
    const res = await request(app)
      .get('/api/v1/owner/dashboard')
      .set('Authorization', `Bearer ${ownerToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.ok(typeof res.body.data.new_orders === 'number');
    assert.ok(typeof res.body.data.accepted_orders === 'number');
    assert.ok(typeof res.body.data.preparing_orders === 'number');
    assert.ok(typeof res.body.data.completed_orders === 'number');
  });

  // 33. Order cancellation and stock restoration
  await t.test('33. Order cancellation restores stock', async () => {
    // Check initial stock
    const initialMed = mockDb.tables.medicines.find((m) => m.id === testMedicineId);
    const initialStock = initialMed.stock;

    // Customer places order for 5 units
    const orderRes = await request(app)
      .post('/api/v1/orders')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        pharmacy_id: testPharmacyId,
        items: [{ medicine_id: testMedicineId, quantity: 5 }],
      });

    assert.equal(orderRes.status, 201);
    const cancelOrderId = orderRes.body.data.id;

    // Stock should now be deducted by 5
    assert.equal(initialMed.stock, initialStock - 5);

    // Customer cancels order while in ORDER_PLACED
    const cancelRes = await request(app)
      .patch(`/api/v1/orders/${cancelOrderId}/status`)
      .set('Authorization', `Bearer ${customerToken}`)
      .send({ status: 'CANCELLED' });

    assert.equal(cancelRes.status, 200);
    assert.equal(cancelRes.body.data.status, 'CANCELLED');

    // Stock must be restored back!
    assert.equal(initialMed.stock, initialStock);
  });

  // 34. Health check endpoint
  await t.test('34. Health check endpoint - GET /health & /api/v1/health', async () => {
    const res = await request(app).get('/health');
    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
    assert.equal(res.body.data.status, 'healthy');

    const resV1 = await request(app).get('/api/v1/health');
    assert.equal(resV1.status, 200);
    assert.equal(resV1.body.data.status, 'healthy');
  });
});
