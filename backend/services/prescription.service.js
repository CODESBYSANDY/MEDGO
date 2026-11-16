const { v4: uuidv4 } = require('uuid');
const path = require('path');
const { supabase, storageBucket } = require('../config/supabase');

class PrescriptionService {
  /**
   * Upload a prescription image and create prescription record
   */
  async uploadPrescription({ customerId, patientIdentifier, file }) {
    if (!supabase) {
      const err = new Error('Database client is not initialized');
      err.statusCode = 500;
      throw err;
    }

    if (!file) {
      const err = new Error('Prescription image file is required');
      err.statusCode = 400;
      throw err;
    }

    if (!patientIdentifier) {
      const err = new Error('patient_id is required');
      err.statusCode = 400;
      throw err;
    }

    // 1. Verify patient belongs to the authenticated customer
    // Check both by patient_id (e.g. PAT1001) or id (UUID)
    let patientQuery = supabase
      .from('patients')
      .select('id, patient_id, customer_id, doctor_name')
      .eq('customer_id', customerId);

    const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(patientIdentifier);
    if (isUUID) {
      patientQuery = patientQuery.or(`id.eq.${patientIdentifier},patient_id.eq.${patientIdentifier}`);
    } else {
      patientQuery = patientQuery.eq('patient_id', patientIdentifier);
    }

    const { data: patient, error: patientError } = await patientQuery.maybeSingle();

    if (patientError) {
      throw patientError;
    }

    if (!patient) {
      const err = new Error('Patient not found or unauthorized. Patient ID must belong to authenticated customer');
      err.statusCode = 403;
      throw err;
    }

    // 2. Upload file to Supabase Storage
    const fileExt = path.extname(file.originalname).toLowerCase() || '.png';
    const fileName = `${customerId}/${uuidv4()}${fileExt}`;

    let imageUrl = '';
    const { error: uploadError } = await supabase.storage
      .from(storageBucket)
      .upload(fileName, file.buffer, {
        contentType: file.mimetype,
        upsert: true,
      });

    if (uploadError) {
      console.warn('[Storage Upload Warning]:', uploadError.message);
      // Fallback URL if bucket is not configured or in restricted network
      imageUrl = `${process.env.SUPABASE_URL || 'https://storage.medgo.local'}/storage/v1/object/public/${storageBucket}/${fileName}`;
    } else {
      // Get signed or public URL
      const { data: urlData } = supabase.storage
        .from(storageBucket)
        .getPublicUrl(fileName);
      imageUrl = urlData?.publicUrl || '';
    }

    // 3. Create prescription record in database
    const prescriptionId = uuidv4();
    const newPrescription = {
      id: prescriptionId,
      patient_id: patient.id,
      customer_id: customerId,
      image_url: imageUrl,
      status: 'PENDING',
      created_at: new Date().toISOString(),
    };

    const { data: createdRx, error: rxInsertError } = await supabase
      .from('prescriptions')
      .insert([newPrescription])
      .select('id, status, image_url')
      .single();

    if (rxInsertError) {
      throw rxInsertError;
    }

    return {
      id: createdRx.id,
      patient_id: patient.patient_id, // Return the patient string identifier PAT1001
      image_url: createdRx.image_url,
      status: createdRx.status,
    };
  }

  /**
   * Get prescriptions for a specific patient with authorization checks
   */
  async getPatientPrescriptions({ user, patientIdentifier }) {
    if (!supabase) {
      const err = new Error('Database client is not initialized');
      err.statusCode = 500;
      throw err;
    }

    // 1. Find patient by id or patient_id
    const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(patientIdentifier);
    let patientQuery = supabase.from('patients').select('id, patient_id, customer_id, doctor_name');

    if (isUUID) {
      patientQuery = patientQuery.or(`id.eq.${patientIdentifier},patient_id.eq.${patientIdentifier}`);
    } else {
      patientQuery = patientQuery.eq('patient_id', patientIdentifier);
    }

    const { data: patient, error: patientError } = await patientQuery.maybeSingle();

    if (patientError) {
      throw patientError;
    }

    if (!patient) {
      const err = new Error('Patient record not found');
      err.statusCode = 404;
      throw err;
    }

    // 2. Authorization check
    if (user.role === 'CUSTOMER') {
      if (patient.customer_id !== user.id) {
        const err = new Error('Access forbidden: You can only access your own patient prescriptions');
        err.statusCode = 403;
        throw err;
      }
    } else if (user.role === 'PHARMACY_OWNER') {
      // Pharmacy owner can access only records associated with their authorized orders
      const { data: authorizedOrder, error: orderCheckErr } = await supabase
        .from('orders')
        .select(`
          id,
          prescription_id,
          pharmacies!inner (
            owner_id
          ),
          prescriptions!inner (
            patient_id
          )
        `)
        .eq('pharmacies.owner_id', user.id)
        .eq('prescriptions.patient_id', patient.id)
        .limit(1);

      if (orderCheckErr) {
        throw orderCheckErr;
      }

      if (!authorizedOrder || authorizedOrder.length === 0) {
        const err = new Error('Access forbidden: Pharmacy owner can only access prescriptions for orders placed at their pharmacy');
        err.statusCode = 403;
        throw err;
      }
    } else {
      const err = new Error('Access forbidden: Unauthorized role');
      err.statusCode = 403;
      throw err;
    }

    // 3. Fetch prescriptions with medicines (prescription_items)
    const { data: prescriptions, error: rxError } = await supabase
      .from('prescriptions')
      .select(`
        id,
        status,
        image_url,
        prescription_items (
          medicine_name,
          quantity
        )
      `)
      .eq('patient_id', patient.id)
      .order('created_at', { ascending: false });

    if (rxError) {
      throw rxError;
    }

    const formatted = (prescriptions || []).map((rx) => ({
      id: rx.id,
      patient_id: patient.patient_id,
      doctor_name: patient.doctor_name,
      medicines: (rx.prescription_items || []).map((item) => ({
        name: item.medicine_name,
        quantity: item.quantity,
      })),
      status: rx.status,
    }));

    return formatted;
  }

  /**
   * Get prescription details by ID
   */
  async getPrescriptionById({ user, id }) {
    if (!supabase) {
      const err = new Error('Database client is not initialized');
      err.statusCode = 500;
      throw err;
    }

    const { data: rx, error: rxError } = await supabase
      .from('prescriptions')
      .select(`
        id,
        customer_id,
        patient_id,
        status,
        image_url,
        created_at,
        patients (
          patient_id,
          doctor_name
        ),
        prescription_items (
          medicine_name,
          quantity
        )
      `)
      .eq('id', id)
      .maybeSingle();

    if (rxError) {
      throw rxError;
    }

    if (!rx) {
      const err = new Error('Prescription not found');
      err.statusCode = 404;
      throw err;
    }

    // Authorization
    if (user.role === 'CUSTOMER' && rx.customer_id !== user.id) {
      const err = new Error('Access forbidden: You do not own this prescription');
      err.statusCode = 403;
      throw err;
    }

    if (user.role === 'PHARMACY_OWNER') {
      // Check if this prescription is tied to an order at owner's pharmacy
      const { data: authCheck, error: authCheckErr } = await supabase
        .from('orders')
        .select(`
          id,
          pharmacies!inner (
            owner_id
          )
        `)
        .eq('prescription_id', id)
        .eq('pharmacies.owner_id', user.id)
        .limit(1);

      if (authCheckErr) {
        throw authCheckErr;
      }

      if (!authCheck || authCheck.length === 0) {
        const err = new Error('Access forbidden: Prescription not associated with any orders at your pharmacy');
        err.statusCode = 403;
        throw err;
      }
    }

    return {
      id: rx.id,
      patient_id: rx.patients ? rx.patients.patient_id : null,
      doctor_name: rx.patients ? rx.patients.doctor_name : null,
      image_url: rx.image_url,
      status: rx.status,
      medicines: (rx.prescription_items || []).map((m) => ({
        name: m.medicine_name,
        quantity: m.quantity,
      })),
      created_at: rx.created_at,
    };
  }

  /**
   * Update prescription verification status (Pharmacy Owner only)
   */
  async updatePrescriptionStatus({ user, id, status }) {
    if (!supabase) {
      const err = new Error('Database client is not initialized');
      err.statusCode = 500;
      throw err;
    }

    if (user.role !== 'PHARMACY_OWNER') {
      const err = new Error('Only an authorized pharmacy owner can update verification status');
      err.statusCode = 403;
      throw err;
    }

    // Check prescription exists
    const { data: rx, error: checkError } = await supabase
      .from('prescriptions')
      .select('id, status')
      .eq('id', id)
      .maybeSingle();

    if (checkError) {
      throw checkError;
    }

    if (!rx) {
      const err = new Error('Prescription not found');
      err.statusCode = 404;
      throw err;
    }

    // Update status
    const { data: updated, error: updateError } = await supabase
      .from('prescriptions')
      .update({ status })
      .eq('id', id)
      .select('id, status, image_url')
      .single();

    if (updateError) {
      throw updateError;
    }

    return updated;
  }
}

module.exports = new PrescriptionService();
