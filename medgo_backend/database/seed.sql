-- ============================================================================
-- MEDGO - SEED DATA (FICTIONAL DEMO DATA)
-- All names, contacts, and prescriptions are strictly fictional for demonstration.
-- ============================================================================

-- Clean up existing demo data
DELETE FROM deliveries;
DELETE FROM order_items;
DELETE FROM orders;
DELETE FROM prescription_items;
DELETE FROM prescriptions;
DELETE FROM patients;
DELETE FROM medicines;
DELETE FROM pharmacies;
DELETE FROM users;

-- ============================================================================
-- 1. DEMO USERS (2 Customers, 2 Pharmacy Owners)
-- Password for all demo accounts: 123456
-- Bcrypt Hash: $2a$10$gNy6Q.kOIrv00YlepBHBWu1xGwy2IdO3XpvHfb5QK6P6t7fJ.Sgyy
-- ============================================================================

-- Customers
INSERT INTO users (id, name, email, phone, password_hash, role, created_at)
VALUES 
(
    'a1111111-1111-1111-1111-111111111111',
    'Arun Kumar',
    'arun@gmail.com',
    '9876543210',
    '$2a$10$gNy6Q.kOIrv00YlepBHBWu1xGwy2IdO3XpvHfb5QK6P6t7fJ.Sgyy',
    'CUSTOMER',
    NOW()
),
(
    'a2222222-2222-2222-2222-222222222222',
    'Priya Sharma',
    'priya@gmail.com',
    '9876543212',
    '$2a$10$gNy6Q.kOIrv00YlepBHBWu1xGwy2IdO3XpvHfb5QK6P6t7fJ.Sgyy',
    'CUSTOMER',
    NOW()
);

-- Pharmacy Owners
INSERT INTO users (id, name, email, phone, password_hash, role, created_at)
VALUES 
(
    'b1111111-1111-1111-1111-111111111111',
    'Ramesh',
    'ramesh@gmail.com',
    '9876543211',
    '$2a$10$gNy6Q.kOIrv00YlepBHBWu1xGwy2IdO3XpvHfb5QK6P6t7fJ.Sgyy',
    'PHARMACY_OWNER',
    NOW()
),
(
    'b2222222-2222-2222-2222-222222222222',
    'Suresh Patel',
    'suresh@gmail.com',
    '9876543214',
    '$2a$10$gNy6Q.kOIrv00YlepBHBWu1xGwy2IdO3XpvHfb5QK6P6t7fJ.Sgyy',
    'PHARMACY_OWNER',
    NOW()
);

-- ============================================================================
-- 2. DEMO PHARMACIES (3 Pharmacies)
-- ============================================================================
INSERT INTO pharmacies (id, owner_id, name, address, latitude, longitude, opening_time, closing_time, is_open, phone, created_at)
VALUES 
(
    'c1111111-1111-1111-1111-111111111111',
    'b1111111-1111-1111-1111-111111111111',
    'Sri Medicals',
    'Anna Nagar, Madurai',
    9.9252,
    78.1198,
    '09:00:00',
    '22:00:00',
    TRUE,
    '9876543210',
    NOW()
),
(
    'c2222222-2222-2222-2222-222222222222',
    'b2222222-2222-2222-2222-222222222222',
    'City Pharmacy',
    'KK Nagar, Madurai',
    9.9200,
    78.1300,
    '08:00:00',
    '23:00:00',
    TRUE,
    '9876543220',
    NOW()
),
(
    'c3333333-3333-3333-3333-333333333333',
    'b2222222-2222-2222-2222-222222222222',
    'HealthCare Medicals',
    'Simmakkal, Madurai',
    9.9320,
    78.1210,
    '10:00:00',
    '21:00:00',
    TRUE,
    '9876543230',
    NOW()
);

-- ============================================================================
-- 3. DEMO PATIENTS (2 Fictional Patients)
-- ============================================================================
INSERT INTO patients (id, patient_id, customer_id, doctor_name, created_at)
VALUES 
(
    'd1111111-1111-1111-1111-111111111111',
    'PAT1001',
    'a1111111-1111-1111-1111-111111111111',
    'Dr. Kumar',
    NOW()
),
(
    'd2222222-2222-2222-2222-222222222222',
    'PAT1002',
    'a2222222-2222-2222-2222-222222222222',
    'Dr. Meena',
    NOW()
);

-- ============================================================================
-- 4. DEMO PRESCRIPTIONS (2 Sample Prescription Records)
-- ============================================================================
INSERT INTO prescriptions (id, patient_id, customer_id, image_url, status, created_at)
VALUES 
(
    'e1111111-1111-1111-1111-111111111111',
    'd1111111-1111-1111-1111-111111111111',
    'a1111111-1111-1111-1111-111111111111',
    'https://demo-storage.supabase.co/prescriptions/demo_prescription_pat1001.png',
    'PENDING',
    NOW()
),
(
    'e2222222-2222-2222-2222-222222222222',
    'd2222222-2222-2222-2222-222222222222',
    'a2222222-2222-2222-2222-222222222222',
    'https://demo-storage.supabase.co/prescriptions/demo_prescription_pat1002.png',
    'VERIFIED',
    NOW()
);

-- Prescription Items
INSERT INTO prescription_items (id, prescription_id, medicine_name, quantity)
VALUES 
('f1111111-1111-1111-1111-111111111101', 'e1111111-1111-1111-1111-111111111111', 'Paracetamol 500mg', 10),
('f1111111-1111-1111-1111-111111111102', 'e1111111-1111-1111-1111-111111111111', 'Amoxicillin 500mg', 6),
('f2222222-2222-2222-2222-222222222201', 'e2222222-2222-2222-2222-222222222222', 'Azithromycin 500mg', 3),
('f2222222-2222-2222-2222-222222222202', 'e2222222-2222-2222-2222-222222222222', 'Cetirizine 10mg', 10);

-- ============================================================================
-- 5. DEMO MEDICINES (10 Medicines across 3 Pharmacies)
-- ============================================================================
-- Sri Medicals (c1111111-1111-1111-1111-111111111111)
INSERT INTO medicines (id, pharmacy_id, name, price, stock, requires_prescription, created_at)
VALUES 
(
    '11111111-0000-0000-0000-000000000001',
    'c1111111-1111-1111-1111-111111111111',
    'Paracetamol 500mg',
    25.00,
    100,
    FALSE,
    NOW()
),
(
    '11111111-0000-0000-0000-000000000002',
    'c1111111-1111-1111-1111-111111111111',
    'Amoxicillin 500mg',
    85.00,
    50,
    TRUE,
    NOW()
),
(
    '11111111-0000-0000-0000-000000000003',
    'c1111111-1111-1111-1111-111111111111',
    'Cetirizine 10mg',
    35.00,
    80,
    FALSE,
    NOW()
),
(
    '11111111-0000-0000-0000-000000000004',
    'c1111111-1111-1111-1111-111111111111',
    'Pantoprazole 40mg',
    65.00,
    60,
    FALSE,
    NOW()
),

-- City Pharmacy (c2222222-2222-2222-2222-222222222222)
(
    '22222222-0000-0000-0000-000000000001',
    'c2222222-2222-2222-2222-222222222222',
    'Paracetamol 500mg',
    24.00,
    120,
    FALSE,
    NOW()
),
(
    '22222222-0000-0000-0000-000000000002',
    'c2222222-2222-2222-2222-222222222222',
    'Azithromycin 500mg',
    120.00,
    40,
    TRUE,
    NOW()
),
(
    '22222222-0000-0000-0000-000000000003',
    'c2222222-2222-2222-2222-222222222222',
    'Metformin 500mg',
    45.00,
    90,
    TRUE,
    NOW()
),

-- HealthCare Medicals (c3333333-3333-3333-3333-333333333333)
(
    '33333333-0000-0000-0000-000000000001',
    'c3333333-3333-3333-3333-333333333333',
    'Ibuprofen 400mg',
    30.00,
    75,
    FALSE,
    NOW()
),
(
    '33333333-0000-0000-0000-000000000002',
    'c3333333-3333-3333-3333-333333333333',
    'Atorvastatin 10mg',
    95.00,
    45,
    TRUE,
    NOW()
),
(
    '33333333-0000-0000-0000-000000000003',
    'c3333333-3333-3333-3333-333333333333',
    'Cough Syrup 100ml',
    70.00,
    35,
    FALSE,
    NOW()
);
