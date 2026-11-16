-- ============================================================================
-- MEDGO - COMPLETE DATABASE SCHEMA (Supabase PostgreSQL)
-- ============================================================================

-- Enable pgcrypto extension for UUID generation if not already enabled
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. USERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('CUSTOMER', 'PHARMACY_OWNER')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- ============================================================================
-- 2. PHARMACIES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS pharmacies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    opening_time TIME NOT NULL,
    closing_time TIME NOT NULL,
    is_open BOOLEAN DEFAULT TRUE,
    phone TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pharmacies_owner_id ON pharmacies(owner_id);
CREATE INDEX IF NOT EXISTS idx_pharmacies_location ON pharmacies(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_pharmacies_is_open ON pharmacies(is_open);

-- ============================================================================
-- 3. MEDICINES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS medicines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pharmacy_id UUID NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    requires_prescription BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_medicines_pharmacy_id ON medicines(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_medicines_name ON medicines(name);
CREATE INDEX IF NOT EXISTS idx_medicines_stock ON medicines(stock);

-- ============================================================================
-- 4. PATIENTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS patients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id TEXT UNIQUE NOT NULL,
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    doctor_name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_patients_customer_id ON patients(customer_id);
CREATE INDEX IF NOT EXISTS idx_patients_patient_id ON patients(patient_id);

-- ============================================================================
-- 5. PRESCRIPTIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS prescriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'VERIFIED', 'REJECTED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_prescriptions_patient_id ON prescriptions(patient_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_customer_id ON prescriptions(customer_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_status ON prescriptions(status);

-- ============================================================================
-- 6. PRESCRIPTION_ITEMS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS prescription_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
    medicine_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0)
);

CREATE INDEX IF NOT EXISTS idx_prescription_items_prescription_id ON prescription_items(prescription_id);

-- ============================================================================
-- 7. ORDERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    pharmacy_id UUID NOT NULL REFERENCES pharmacies(id) ON DELETE RESTRICT,
    prescription_id UUID REFERENCES prescriptions(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'ORDER_PLACED' CHECK (
        status IN (
            'ORDER_PLACED',
            'PHARMACY_ACCEPTED',
            'PRESCRIPTION_VERIFIED',
            'MEDICINES_PACKED',
            'READY_FOR_PICKUP',
            'PICKED_UP',
            'DELIVERED',
            'REJECTED',
            'CANCELLED'
        )
    ),
    total_amount NUMERIC(10,2) NOT NULL CHECK (total_amount >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_pharmacy_id ON orders(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_orders_prescription_id ON orders(prescription_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- ============================================================================
-- 8. ORDER_ITEMS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    medicine_id UUID NOT NULL REFERENCES medicines(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0)
);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_medicine_id ON order_items(medicine_id);

-- ============================================================================
-- 9. DELIVERIES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID UNIQUE NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    qr_token_hash TEXT,
    partner_status TEXT DEFAULT 'PENDING',
    qr_expires_at TIMESTAMPTZ,
    is_redeemed BOOLEAN DEFAULT FALSE,
    picked_up_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_deliveries_order_id ON deliveries(order_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_qr_token_hash ON deliveries(qr_token_hash);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacies ENABLE ROW LEVEL SECURITY;
ALTER TABLE medicines ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescription_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;

-- Notice: The Node.js Express backend communicates with Supabase using the
-- SUPABASE_SERVICE_ROLE_KEY, which automatically bypasses RLS on the server side.
-- For clients connecting directly with anon or user JWTs, the policies below apply:

-- Users: Read own profile
CREATE POLICY users_read_own ON users
    FOR SELECT TO authenticated
    USING (auth.uid() = id);

-- Pharmacies: Anyone can read open pharmacies
CREATE POLICY pharmacies_read_all ON pharmacies
    FOR SELECT TO public
    USING (true);

-- Pharmacies: Owners can update their own pharmacy
CREATE POLICY pharmacies_owner_update ON pharmacies
    FOR UPDATE TO authenticated
    USING (auth.uid() = owner_id);

-- Medicines: Anyone can view medicines
CREATE POLICY medicines_read_all ON medicines
    FOR SELECT TO public
    USING (true);

-- Patients: Customers can view their own patients
CREATE POLICY patients_customer_all ON patients
    FOR ALL TO authenticated
    USING (auth.uid() = customer_id);

-- Prescriptions: Customer can view their own; Pharmacy owner can view if order placed
CREATE POLICY prescriptions_customer_select ON prescriptions
    FOR SELECT TO authenticated
    USING (
        auth.uid() = customer_id OR
        EXISTS (
            SELECT 1 FROM orders o
            JOIN pharmacies p ON o.pharmacy_id = p.id
            WHERE o.prescription_id = prescriptions.id AND p.owner_id = auth.uid()
        )
    );

-- Orders: Customer can view own orders; Pharmacy owner can view pharmacy orders
CREATE POLICY orders_select_authorized ON orders
    FOR SELECT TO authenticated
    USING (
        auth.uid() = customer_id OR
        EXISTS (
            SELECT 1 FROM pharmacies p
            WHERE p.id = orders.pharmacy_id AND p.owner_id = auth.uid()
        )
    );

-- ============================================================================
-- DATABASE PROCEDURES / RPC FUNCTIONS FOR ATOMIC TRANSACTIONS
-- ============================================================================

-- Function: create_order_with_items_and_stock
-- Description: Creates an order, validates inventory, calculates total, reserves stock atomically
CREATE OR REPLACE FUNCTION create_order_with_items_and_stock(
    p_customer_id UUID,
    p_pharmacy_id UUID,
    p_prescription_id UUID,
    p_items JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_pharmacy RECORD;
    v_item JSONB;
    v_medicine RECORD;
    v_order_id UUID;
    v_total_amount NUMERIC(10,2) := 0;
    v_requires_rx BOOLEAN := FALSE;
    v_prescription RECORD;
    v_med_id UUID;
    v_quantity INT;
BEGIN
    -- 1. Check pharmacy exists and is open
    SELECT * INTO v_pharmacy FROM pharmacies WHERE id = p_pharmacy_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pharmacy not found';
    END IF;

    IF v_pharmacy.is_open = FALSE THEN
        RAISE EXCEPTION 'Pharmacy is currently closed';
    END IF;

    -- 2. Validate items array
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'Order must contain at least one item';
    END IF;

    -- 3. If prescription_id provided, verify customer owns prescription
    IF p_prescription_id IS NOT NULL THEN
        SELECT * INTO v_prescription FROM prescriptions
        WHERE id = p_prescription_id AND customer_id = p_customer_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Prescription not found or unauthorized';
        END IF;
    END IF;

    -- 4. First pass: Lock rows, check belonging, stock, and prescription rules
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_med_id := (v_item->>'medicine_id')::UUID;
        v_quantity := (v_item->>'quantity')::INT;

        IF v_quantity <= 0 THEN
            RAISE EXCEPTION 'Item quantity must be greater than 0';
        END IF;

        -- Lock medicine row FOR UPDATE to prevent concurrency race conditions
        SELECT * INTO v_medicine FROM medicines
        WHERE id = v_med_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Medicine % not found', v_med_id;
        END IF;

        IF v_medicine.pharmacy_id != p_pharmacy_id THEN
            RAISE EXCEPTION 'Medicine % does not belong to selected pharmacy', v_medicine.name;
        END IF;

        IF v_medicine.stock < v_quantity THEN
            RAISE EXCEPTION 'Insufficient stock for medicine % (Available: %, Requested: %)', 
                v_medicine.name, v_medicine.stock, v_quantity;
        END IF;

        IF v_medicine.requires_prescription THEN
            v_requires_rx := TRUE;
        END IF;

        -- Accumulate backend-calculated total amount
        v_total_amount := v_total_amount + (v_medicine.price * v_quantity);
    END LOOP;

    -- 5. If any medicine requires prescription, prescription_id is mandatory
    IF v_requires_rx AND p_prescription_id IS NULL THEN
        RAISE EXCEPTION 'Order contains medicines requiring a prescription, but no prescription was provided';
    END IF;

    -- 6. Insert order record
    v_order_id := gen_random_uuid();
    INSERT INTO orders (id, customer_id, pharmacy_id, prescription_id, status, total_amount, created_at, updated_at)
    VALUES (v_order_id, p_customer_id, p_pharmacy_id, p_prescription_id, 'ORDER_PLACED', v_total_amount, NOW(), NOW());

    -- 7. Second pass: Deduct stock and insert order_items
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_med_id := (v_item->>'medicine_id')::UUID;
        v_quantity := (v_item->>'quantity')::INT;

        SELECT * INTO v_medicine FROM medicines WHERE id = v_med_id;

        -- Deduct stock
        UPDATE medicines
        SET stock = stock - v_quantity
        WHERE id = v_med_id;

        -- Insert order item with server-side price
        INSERT INTO order_items (id, order_id, medicine_id, quantity, price)
        VALUES (gen_random_uuid(), v_order_id, v_med_id, v_quantity, v_medicine.price);
    END LOOP;

    -- 8. Return created order summary
    RETURN jsonb_build_object(
        'id', v_order_id,
        'status', 'ORDER_PLACED',
        'total_amount', v_total_amount,
        'pharmacy_id', p_pharmacy_id
    );
END;
$$;

-- Function: restore_order_stock_atomic
-- Description: Restores medicine stock when an order is REJECTED or CANCELLED
CREATE OR REPLACE FUNCTION restore_order_stock_atomic(
    p_order_id UUID,
    p_new_status TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_item RECORD;
BEGIN
    -- Verify status is either REJECTED or CANCELLED
    IF p_new_status NOT IN ('REJECTED', 'CANCELLED') THEN
        RAISE EXCEPTION 'Invalid target status for stock restoration';
    END IF;

    -- Lock order row
    PERFORM id FROM orders WHERE id = p_order_id FOR UPDATE;

    -- Restore stock for each item in the order
    FOR v_item IN SELECT medicine_id, quantity FROM order_items WHERE order_id = p_order_id
    LOOP
        UPDATE medicines
        SET stock = stock + v_item.quantity
        WHERE id = v_item.medicine_id;
    END LOOP;

    -- Update order status
    UPDATE orders
    SET status = p_new_status, updated_at = NOW()
    WHERE id = p_order_id;
END;
$$;
