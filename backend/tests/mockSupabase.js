const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');

/**
 * In-Memory Mock Supabase Client for End-to-End API Test Suite
 * Faithfully mirrors Supabase PostgREST table queries and transactions for hermetic verification.
 */
class MockSupabase {
  constructor() {
    this.reset();
  }

  reset() {
    // Password hash for 123456
    const pwdHash = '$2a$10$gNy6Q.kOIrv00YlepBHBWu1xGwy2IdO3XpvHfb5QK6P6t7fJ.Sgyy';

    this.tables = {
      users: [
        {
          id: 'a1111111-1111-1111-1111-111111111111',
          name: 'Arun Kumar',
          email: 'arun@gmail.com',
          phone: '9876543210',
          password_hash: pwdHash,
          role: 'CUSTOMER',
          created_at: new Date().toISOString(),
        },
        {
          id: 'a2222222-2222-2222-2222-222222222222',
          name: 'Priya Sharma',
          email: 'priya@gmail.com',
          phone: '9876543212',
          password_hash: pwdHash,
          role: 'CUSTOMER',
          created_at: new Date().toISOString(),
        },
        {
          id: 'b1111111-1111-1111-1111-111111111111',
          name: 'Ramesh',
          email: 'ramesh@gmail.com',
          phone: '9876543211',
          password_hash: pwdHash,
          role: 'PHARMACY_OWNER',
          created_at: new Date().toISOString(),
        },
        {
          id: 'b2222222-2222-2222-2222-222222222222',
          name: 'Suresh Patel',
          email: 'suresh@gmail.com',
          phone: '9876543214',
          password_hash: pwdHash,
          role: 'PHARMACY_OWNER',
          created_at: new Date().toISOString(),
        },
      ],

      pharmacies: [
        {
          id: 'c1111111-1111-1111-1111-111111111111',
          owner_id: 'b1111111-1111-1111-1111-111111111111',
          name: 'Sri Medicals',
          address: 'Anna Nagar, Madurai',
          latitude: 9.9252,
          longitude: 78.1198,
          opening_time: '09:00:00',
          closing_time: '22:00:00',
          is_open: true,
          phone: '9876543210',
          created_at: new Date().toISOString(),
        },
        {
          id: 'c2222222-2222-2222-2222-222222222222',
          owner_id: 'b2222222-2222-2222-2222-222222222222',
          name: 'City Pharmacy',
          address: 'KK Nagar, Madurai',
          latitude: 9.92,
          longitude: 78.13,
          opening_time: '08:00:00',
          closing_time: '23:00:00',
          is_open: true,
          phone: '9876543220',
          created_at: new Date().toISOString(),
        },
        {
          id: 'c3333333-3333-3333-3333-333333333333',
          owner_id: 'b2222222-2222-2222-2222-222222222222',
          name: 'HealthCare Medicals',
          address: 'Simmakkal, Madurai',
          latitude: 9.932,
          longitude: 78.121,
          opening_time: '10:00:00',
          closing_time: '21:00:00',
          is_open: true,
          phone: '9876543230',
          created_at: new Date().toISOString(),
        },
      ],

      patients: [
        {
          id: 'd1111111-1111-1111-1111-111111111111',
          patient_id: 'PAT1001',
          customer_id: 'a1111111-1111-1111-1111-111111111111',
          doctor_name: 'Dr. Kumar',
          created_at: new Date().toISOString(),
        },
        {
          id: 'd2222222-2222-2222-2222-222222222222',
          patient_id: 'PAT1002',
          customer_id: 'a2222222-2222-2222-2222-222222222222',
          doctor_name: 'Dr. Meena',
          created_at: new Date().toISOString(),
        },
      ],

      prescriptions: [
        {
          id: 'e1111111-1111-1111-1111-111111111111',
          patient_id: 'd1111111-1111-1111-1111-111111111111',
          customer_id: 'a1111111-1111-1111-1111-111111111111',
          image_url: 'https://demo-storage.supabase.co/prescriptions/demo_rx_1.png',
          status: 'PENDING',
          created_at: new Date().toISOString(),
        },
        {
          id: 'e2222222-2222-2222-2222-222222222222',
          patient_id: 'd2222222-2222-2222-2222-222222222222',
          customer_id: 'a2222222-2222-2222-2222-222222222222',
          image_url: 'https://demo-storage.supabase.co/prescriptions/demo_rx_2.png',
          status: 'VERIFIED',
          created_at: new Date().toISOString(),
        },
      ],

      prescription_items: [
        {
          id: 'f1111111-1111-1111-1111-111111111101',
          prescription_id: 'e1111111-1111-1111-1111-111111111111',
          medicine_name: 'Paracetamol 500mg',
          quantity: 10,
        },
        {
          id: 'f1111111-1111-1111-1111-111111111102',
          prescription_id: 'e1111111-1111-1111-1111-111111111111',
          medicine_name: 'Amoxicillin 500mg',
          quantity: 6,
        },
        {
          id: 'f2222222-2222-2222-2222-222222222201',
          prescription_id: 'e2222222-2222-2222-2222-222222222222',
          medicine_name: 'Azithromycin 500mg',
          quantity: 3,
        },
        {
          id: 'f2222222-2222-2222-2222-222222222202',
          prescription_id: 'e2222222-2222-2222-2222-222222222222',
          medicine_name: 'Cetirizine 10mg',
          quantity: 10,
        },
      ],

      medicines: [
        {
          id: '11111111-0000-0000-0000-000000000001',
          pharmacy_id: 'c1111111-1111-1111-1111-111111111111',
          name: 'Paracetamol 500mg',
          price: 25.0,
          stock: 100,
          requires_prescription: false,
          created_at: new Date().toISOString(),
        },
        {
          id: '11111111-0000-0000-0000-000000000002',
          pharmacy_id: 'c1111111-1111-1111-1111-111111111111',
          name: 'Amoxicillin 500mg',
          price: 85.0,
          stock: 50,
          requires_prescription: true,
          created_at: new Date().toISOString(),
        },
        {
          id: '11111111-0000-0000-0000-000000000003',
          pharmacy_id: 'c1111111-1111-1111-1111-111111111111',
          name: 'Cetirizine 10mg',
          price: 35.0,
          stock: 80,
          requires_prescription: false,
          created_at: new Date().toISOString(),
        },
        {
          id: '11111111-0000-0000-0000-000000000004',
          pharmacy_id: 'c1111111-1111-1111-1111-111111111111',
          name: 'Pantoprazole 40mg',
          price: 65.0,
          stock: 60,
          requires_prescription: false,
          created_at: new Date().toISOString(),
        },
        {
          id: '22222222-0000-0000-0000-000000000001',
          pharmacy_id: 'c2222222-2222-2222-2222-222222222222',
          name: 'Paracetamol 500mg',
          price: 24.0,
          stock: 120,
          requires_prescription: false,
          created_at: new Date().toISOString(),
        },
        {
          id: '22222222-0000-0000-0000-000000000002',
          pharmacy_id: 'c2222222-2222-2222-2222-222222222222',
          name: 'Azithromycin 500mg',
          price: 120.0,
          stock: 40,
          requires_prescription: true,
          created_at: new Date().toISOString(),
        },
        {
          id: '22222222-0000-0000-0000-000000000003',
          pharmacy_id: 'c2222222-2222-2222-2222-222222222222',
          name: 'Metformin 500mg',
          price: 45.0,
          stock: 90,
          requires_prescription: true,
          created_at: new Date().toISOString(),
        },
        {
          id: '33333333-0000-0000-0000-000000000001',
          pharmacy_id: 'c3333333-3333-3333-3333-333333333333',
          name: 'Ibuprofen 400mg',
          price: 30.0,
          stock: 75,
          requires_prescription: false,
          created_at: new Date().toISOString(),
        },
        {
          id: '33333333-0000-0000-0000-000000000002',
          pharmacy_id: 'c3333333-3333-3333-3333-333333333333',
          name: 'Atorvastatin 10mg',
          price: 95.0,
          stock: 45,
          requires_prescription: true,
          created_at: new Date().toISOString(),
        },
        {
          id: '33333333-0000-0000-0000-000000000003',
          pharmacy_id: 'c3333333-3333-3333-3333-333333333333',
          name: 'Cough Syrup 100ml',
          price: 70.0,
          stock: 35,
          requires_prescription: false,
          created_at: new Date().toISOString(),
        },
      ],

      orders: [],
      order_items: [],
      deliveries: [],
    };

    this.storage = {
      from: (bucket) => ({
        upload: async (fileName, buffer, options) => {
          return { data: { path: `${bucket}/${fileName}` }, error: null };
        },
        getPublicUrl: (fileName) => ({
          data: {
            publicUrl: `https://demo-storage.supabase.co/${bucket}/${fileName}`,
          },
        }),
      }),
    };
  }

  from(tableName) {
    return new MockQueryBuilder(this, tableName);
  }

  async rpc(fnName, args) {
    return { data: null, error: { message: 'RPC fallback' } };
  }
}

class MockQueryBuilder {
  constructor(db, tableName) {
    this.db = db;
    this.tableName = tableName;
    this.filters = [];
    this.selectFields = null;
    this.isSingle = false;
    this.isMaybeSingle = false;
    this.orderConfig = null;
    this.limitCount = null;
    this.operation = 'select';
    this.payload = null;
  }

  select(fields = '*') {
    this.selectFields = fields;
    return this;
  }

  insert(rows) {
    this.operation = 'insert';
    this.payload = Array.isArray(rows) ? rows : [rows];
    return this;
  }

  update(values) {
    this.operation = 'update';
    this.payload = values;
    return this;
  }

  eq(field, value) {
    this.filters.push((row) => {
      if (field.includes('.')) {
        return true;
      }
      return row[field] === value;
    });
    return this;
  }

  in(field, values) {
    this.filters.push((row) => values.includes(row[field]));
    return this;
  }

  or(expr) {
    const parts = expr.split(',');
    const matchers = parts.map((p) => {
      const [col, op, val] = p.split('.');
      return (row) => row[col] === val;
    });
    this.filters.push((row) => matchers.some((m) => m(row)));
    return this;
  }

  gt(field, value) {
    this.filters.push((row) => row[field] > value);
    return this;
  }

  ilike(field, pattern) {
    const clean = pattern.replace(/%/g, '').toLowerCase();
    this.filters.push((row) => (row[field] || '').toLowerCase().includes(clean));
    return this;
  }

  order(field, { ascending = true } = {}) {
    this.orderConfig = { field, ascending };
    return this;
  }

  limit(count) {
    this.limitCount = count;
    return this;
  }

  single() {
    this.isSingle = true;
    return this.execute();
  }

  maybeSingle() {
    this.isMaybeSingle = true;
    return this.execute();
  }

  then(resolve, reject) {
    return this.execute().then(resolve, reject);
  }

  async execute() {
    const table = this.db.tables[this.tableName];
    if (!table) {
      return { data: null, error: { message: `Table ${this.tableName} not found` } };
    }

    if (this.operation === 'insert') {
      const insertedRows = this.payload.map((r) => ({
        ...r,
        id: r.id || uuidv4(),
      }));
      table.push(...insertedRows);
      const res = this.isSingle ? insertedRows[0] : insertedRows;
      return { data: res, error: null };
    }

    if (this.operation === 'update') {
      const matched = table.filter((row) => this.filters.every((f) => f(row)));
      matched.forEach((row) => Object.assign(row, this.payload));
      const res = this.isSingle || this.isMaybeSingle ? matched[0] || null : matched;
      return { data: res, error: null };
    }

    // SELECT
    let result = table.filter((row) => this.filters.every((f) => f(row)));

    // Handle Joins
    result = result.map((row) => {
      const copy = { ...row };

      if (this.tableName === 'pharmacies') {
        const owner = this.db.tables.users.find((u) => u.id === row.owner_id);
        copy.users = owner ? { name: owner.name } : null;
      }

      if (this.tableName === 'prescriptions') {
        const pat = this.db.tables.patients.find((p) => p.id === row.patient_id);
        copy.patients = pat ? { patient_id: pat.patient_id, doctor_name: pat.doctor_name } : null;
        copy.prescription_items = this.db.tables.prescription_items.filter(
          (pi) => pi.prescription_id === row.id
        );
      }

      if (this.tableName === 'orders') {
        const pharm = this.db.tables.pharmacies.find((p) => p.id === row.pharmacy_id);
        copy.pharmacies = pharm ? { id: pharm.id, name: pharm.name, owner_id: pharm.owner_id } : null;
        const cust = this.db.tables.users.find((u) => u.id === row.customer_id);
        copy.users = cust ? { name: cust.name } : null;
        const items = this.db.tables.order_items.filter((oi) => oi.order_id === row.id);
        copy.order_items = items.map((oi) => {
          const med = this.db.tables.medicines.find((m) => m.id === oi.medicine_id);
          return {
            ...oi,
            medicines: med ? { id: med.id, name: med.name } : null,
          };
        });
      }

      if (this.tableName === 'deliveries') {
        const ord = this.db.tables.orders.find((o) => o.id === row.order_id);
        if (ord) {
          const pharm = this.db.tables.pharmacies.find((p) => p.id === ord.pharmacy_id);
          copy.orders = {
            id: ord.id,
            status: ord.status,
            pharmacies: pharm ? { name: pharm.name } : null,
          };
        } else {
          copy.orders = null;
        }
      }

      return copy;
    });

    if (this.orderConfig) {
      const { field, ascending } = this.orderConfig;
      result.sort((a, b) => {
        if (a[field] < b[field]) return ascending ? -1 : 1;
        if (a[field] > b[field]) return ascending ? 1 : -1;
        return 0;
      });
    }

    if (this.limitCount !== null) {
      result = result.slice(0, this.limitCount);
    }

    if (this.isSingle) {
      if (result.length === 0) {
        return { data: null, error: { message: 'Row not found' } };
      }
      return { data: result[0], error: null };
    }

    if (this.isMaybeSingle) {
      return { data: result.length > 0 ? result[0] : null, error: null };
    }

    return { data: result, error: null };
  }
}

module.exports = {
  MockSupabase,
};
