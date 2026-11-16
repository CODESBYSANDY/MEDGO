const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const { supabase } = require('../config/supabase');

class OrderService {
  /**
   * Create an order with backend price calculation, stock reservation, and prescription check
   */
  async createOrder({ customerId, pharmacyId, prescriptionId, items }) {
    if (!supabase) {
      const err = new Error('Database client is not initialized');
      err.statusCode = 500;
      throw err;
    }

    // Attempt PostgreSQL RPC first if available
    try {
      const { data: rpcData, error: rpcError } = await supabase.rpc('create_order_with_items_and_stock', {
        p_customer_id: customerId,
        p_pharmacy_id: pharmacyId,
        p_prescription_id: prescriptionId || null,
        p_items: items,
      });

      if (!rpcError && rpcData) {
        return {
          id: rpcData.id,
          status: rpcData.status,
          total_amount: Number(rpcData.total_amount),
          pharmacy_id: rpcData.pharmacy_id,
        };
      }
    } catch (rpcEx) {
      console.warn('[RPC Info]: Function create_order_with_items_and_stock not invoked or not found, using transactional service flow.');
    }

    // Transactional application-level flow
    // 1. Verify pharmacy exists and is open
    const { data: pharmacy, error: pharmErr } = await supabase
      .from('pharmacies')
      .select('id, name, is_open')
      .eq('id', pharmacyId)
      .maybeSingle();

    if (pharmErr) throw pharmErr;
    if (!pharmacy) {
      const err = new Error('Pharmacy not found');
      err.statusCode = 404;
      throw err;
    }

    if (!pharmacy.is_open) {
      const err = new Error('Pharmacy is currently closed');
      err.statusCode = 400;
      throw err;
    }

    // 2. If prescription_id provided, verify customer owns prescription
    let prescription = null;
    if (prescriptionId) {
      const { data: rxData, error: rxErr } = await supabase
        .from('prescriptions')
        .select('id, customer_id, status')
        .eq('id', prescriptionId)
        .eq('customer_id', customerId)
        .maybeSingle();

      if (rxErr) throw rxErr;
      if (!rxData) {
        const err = new Error('Prescription not found or unauthorized');
        err.statusCode = 403;
        throw err;
      }
      prescription = rxData;
    }

    // 3. Verify each medicine, stock, belonging to pharmacy, prescription requirement
    const medicineIds = items.map((i) => i.medicine_id);
    const { data: medicines, error: medErr } = await supabase
      .from('medicines')
      .select('id, pharmacy_id, name, price, stock, requires_prescription')
      .in('id', medicineIds);

    if (medErr) throw medErr;

    const medMap = new Map();
    (medicines || []).forEach((m) => medMap.set(m.id, m));

    let calculatedTotal = 0;
    let requiresPrescription = false;
    const validatedItems = [];

    for (const item of items) {
      const medicine = medMap.get(item.medicine_id);
      if (!medicine) {
        const err = new Error(`Medicine not found: ${item.medicine_id}`);
        err.statusCode = 404;
        throw err;
      }

      if (medicine.pharmacy_id !== pharmacyId) {
        const err = new Error(`Medicine ${medicine.name} does not belong to selected pharmacy`);
        err.statusCode = 400;
        throw err;
      }

      if (medicine.stock < item.quantity) {
        const err = new Error(`Insufficient stock for medicine ${medicine.name} (Available: ${medicine.stock}, Requested: ${item.quantity})`);
        err.statusCode = 400;
        throw err;
      }

      if (medicine.requires_prescription) {
        requiresPrescription = true;
      }

      const itemPrice = Number(medicine.price);
      calculatedTotal += itemPrice * item.quantity;

      validatedItems.push({
        medicine,
        quantity: item.quantity,
        price: itemPrice,
      });
    }

    // Check prescription requirement
    if (requiresPrescription && !prescriptionId) {
      const err = new Error('Order contains medicines requiring a prescription, but no prescription was provided');
      err.statusCode = 400;
      throw err;
    }

    // 4. Create Order
    const orderId = uuidv4();
    const newOrder = {
      id: orderId,
      customer_id: customerId,
      pharmacy_id: pharmacyId,
      prescription_id: prescriptionId || null,
      status: 'ORDER_PLACED',
      total_amount: Math.round(calculatedTotal * 100) / 100,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    const { data: createdOrder, error: orderInsertErr } = await supabase
      .from('orders')
      .insert([newOrder])
      .select('id, status, total_amount, pharmacy_id')
      .single();

    if (orderInsertErr) throw orderInsertErr;

    // 5. Insert order items & deduct stock
    for (const vItem of validatedItems) {
      const orderItemId = uuidv4();
      const { error: itemInsertErr } = await supabase.from('order_items').insert([
        {
          id: orderItemId,
          order_id: orderId,
          medicine_id: vItem.medicine.id,
          quantity: vItem.quantity,
          price: vItem.price,
        },
      ]);

      if (itemInsertErr) throw itemInsertErr;

      // Deduct stock
      const updatedStock = vItem.medicine.stock - vItem.quantity;
      const { error: stockErr } = await supabase
        .from('medicines')
        .update({ stock: updatedStock })
        .eq('id', vItem.medicine.id);

      if (stockErr) throw stockErr;
    }

    return {
      id: createdOrder.id,
      status: createdOrder.status,
      total_amount: Number(createdOrder.total_amount),
      pharmacy_id: createdOrder.pharmacy_id,
    };
  }

  /**
   * Get order details by ID with authorization checks
   */
  async getOrderById({ user, id }) {
    if (!supabase) {
      const err = new Error('Database client is not initialized');
      err.statusCode = 500;
      throw err;
    }

    const { data: order, error } = await supabase
      .from('orders')
      .select(`
        id,
        customer_id,
        pharmacy_id,
        prescription_id,
        status,
        total_amount,
        created_at,
        updated_at,
        pharmacies (
          id,
          name,
          owner_id
        ),
        order_items (
          id,
          quantity,
          price,
          medicines (
            id,
            name
          )
        )
      `)
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    if (!order) {
      const err = new Error('Order not found');
      err.statusCode = 404;
      throw err;
    }

    // Authorization:
    // Customer can only view their own orders
    if (user.role === 'CUSTOMER' && order.customer_id !== user.id) {
      const err = new Error('Access forbidden: You can only view your own orders');
      err.statusCode = 403;
      throw err;
    }

    // Pharmacy owner can only view orders belonging to their pharmacy
    if (user.role === 'PHARMACY_OWNER') {
      const pharmacyOwnerId = order.pharmacies?.owner_id;
      if (pharmacyOwnerId !== user.id) {
        const err = new Error('Access forbidden: You can only view orders for your own pharmacy');
        err.statusCode = 403;
        throw err;
      }
    }

    const items = (order.order_items || []).map((item) => ({
      id: item.id,
      medicine_id: item.medicines?.id,
      medicine_name: item.medicines?.name,
      quantity: item.quantity,
      price: Number(item.price),
    }));

    return {
      id: order.id,
      status: order.status,
      total_amount: Number(order.total_amount),
      pharmacy_name: order.pharmacies ? order.pharmacies.name : '',
      items,
      prescription_id: order.prescription_id,
      created_at: order.created_at,
    };
  }

  /**
   * Update order status with strict lifecycle transition validation and stock restoration
   */
  async updateOrderStatus({ user, orderId, newStatus }) {
    if (!supabase) {
      const err = new Error('Database client is not initialized');
      err.statusCode = 500;
      throw err;
    }

    // 1. Fetch current order with pharmacy and items
    const { data: order, error } = await supabase
      .from('orders')
      .select(`
        id,
        customer_id,
        pharmacy_id,
        prescription_id,
        status,
        pharmacies (
          owner_id
        ),
        order_items (
          medicine_id,
          quantity
        )
      `)
      .eq('id', orderId)
      .maybeSingle();

    if (error) throw error;
    if (!order) {
      const err = new Error('Order not found');
      err.statusCode = 404;
      throw err;
    }

    const currentStatus = order.status;

    // Terminal statuses cannot transition
    if (['DELIVERED', 'REJECTED', 'CANCELLED'].includes(currentStatus)) {
      const err = new Error(`Cannot change status of an order that is already ${currentStatus}`);
      err.statusCode = 400;
      throw err;
    }

    // 2. Validate actor authorization & transition flow
    const isOwner = user.role === 'PHARMACY_OWNER' && order.pharmacies?.owner_id === user.id;
    const isCustomer = user.role === 'CUSTOMER' && order.customer_id === user.id;
    const isDelivery = user.role === 'DELIVERY_PARTNER';

    if (newStatus === 'CANCELLED') {
      if (!isCustomer && !isOwner) {
        const err = new Error('Only the customer or pharmacy owner can cancel the order');
        err.statusCode = 403;
        throw err;
      }
      if (currentStatus !== 'ORDER_PLACED') {
        const err = new Error('Orders can only be cancelled while in ORDER_PLACED status');
        err.statusCode = 400;
        throw err;
      }
    } else if (newStatus === 'REJECTED') {
      if (!isOwner) {
        const err = new Error('Only the pharmacy owner can reject an order');
        err.statusCode = 403;
        throw err;
      }
    } else if (newStatus === 'PHARMACY_ACCEPTED') {
      if (!isOwner) {
        const err = new Error('Only the pharmacy owner can accept an order');
        err.statusCode = 403;
        throw err;
      }
      if (currentStatus !== 'ORDER_PLACED') {
        const err = new Error(`Cannot transition from ${currentStatus} to PHARMACY_ACCEPTED`);
        err.statusCode = 400;
        throw err;
      }
    } else if (newStatus === 'PRESCRIPTION_VERIFIED') {
      if (!isOwner) {
        const err = new Error('Only the pharmacy owner / qualified pharmacist can verify prescriptions');
        err.statusCode = 403;
        throw err;
      }
      if (currentStatus !== 'PHARMACY_ACCEPTED' && currentStatus !== 'ORDER_PLACED') {
        const err = new Error(`Cannot transition from ${currentStatus} to PRESCRIPTION_VERIFIED`);
        err.statusCode = 400;
        throw err;
      }
      if (!order.prescription_id) {
        const err = new Error('Order does not have an attached prescription to verify');
        err.statusCode = 400;
        throw err;
      }

      // Also update prescription record status to VERIFIED
      await supabase
        .from('prescriptions')
        .update({ status: 'VERIFIED' })
        .eq('id', order.prescription_id);
    } else if (newStatus === 'MEDICINES_PACKED') {
      if (!isOwner) {
        const err = new Error('Only the pharmacy owner can mark medicines packed');
        err.statusCode = 403;
        throw err;
      }

      // If order has prescription, check it was verified
      if (order.prescription_id && currentStatus !== 'PRESCRIPTION_VERIFIED') {
        // Check if the prescription itself is verified
        const { data: rx } = await supabase
          .from('prescriptions')
          .select('status')
          .eq('id', order.prescription_id)
          .maybeSingle();

        if (rx?.status !== 'VERIFIED') {
          const err = new Error('Prescription verification is mandatory before packing medicines');
          err.statusCode = 400;
          throw err;
        }
      }

      const validPrevious = ['PHARMACY_ACCEPTED', 'PRESCRIPTION_VERIFIED'];
      if (!validPrevious.includes(currentStatus)) {
        const err = new Error(`Cannot transition from ${currentStatus} to MEDICINES_PACKED`);
        err.statusCode = 400;
        throw err;
      }
    } else if (newStatus === 'READY_FOR_PICKUP') {
      if (!isOwner) {
        const err = new Error('Only the pharmacy owner can mark order ready for pickup');
        err.statusCode = 403;
        throw err;
      }
      if (currentStatus !== 'MEDICINES_PACKED') {
        const err = new Error(`Cannot transition from ${currentStatus} to READY_FOR_PICKUP`);
        err.statusCode = 400;
        throw err;
      }
    } else if (newStatus === 'PICKED_UP' || newStatus === 'DELIVERED') {
      if (!isDelivery && !isOwner) {
        const err = new Error('Only delivery partners or authorized personnel can update delivery status');
        err.statusCode = 403;
        throw err;
      }
    } else {
      const err = new Error(`Invalid status transition to ${newStatus}`);
      err.statusCode = 400;
      throw err;
    }

    // 3. Handle stock restoration if order is REJECTED or CANCELLED
    if (['REJECTED', 'CANCELLED'].includes(newStatus)) {
      let rpcSucceeded = false;
      try {
        const { error: rpcErr } = await supabase.rpc('restore_order_stock_atomic', {
          p_order_id: orderId,
          p_new_status: newStatus,
        });
        if (!rpcErr) {
          rpcSucceeded = true;
        }
      } catch (rpcEx) {
        // Fall through to manual fallback
      }

      if (!rpcSucceeded) {
        // Fallback: restore stock manually
        for (const item of order.order_items || []) {
          const { data: med } = await supabase
            .from('medicines')
            .select('stock')
            .eq('id', item.medicine_id)
            .single();

          if (med) {
            await supabase
              .from('medicines')
              .update({ stock: med.stock + item.quantity })
              .eq('id', item.medicine_id);
          }
        }
      }
    }

    // 4. Update order status
    const { data: updatedOrder, error: updateErr } = await supabase
      .from('orders')
      .update({
        status: newStatus,
        updated_at: new Date().toISOString(),
      })
      .eq('id', orderId)
      .select('id, status, total_amount, pharmacy_id')
      .single();

    if (updateErr) throw updateErr;

    return {
      id: updatedOrder.id,
      status: updatedOrder.status,
      total_amount: Number(updatedOrder.total_amount),
      pharmacy_id: updatedOrder.pharmacy_id,
    };
  }

  /**
   * Generate one-time parcel QR token for packed order (Pharmacy Owner only)
   */
  async generateParcelToken({ user, orderId }) {
    if (!supabase) {
      const err = new Error('Database client is not initialized');
      err.statusCode = 500;
      throw err;
    }

    if (user.role !== 'PHARMACY_OWNER') {
      const err = new Error('Only an authorized pharmacy owner can generate a delivery token');
      err.statusCode = 403;
      throw err;
    }

    // Fetch order with pharmacy owner check
    const { data: order, error } = await supabase
      .from('orders')
      .select(`
        id,
        status,
        pharmacies (
          owner_id
        )
      `)
      .eq('id', orderId)
      .maybeSingle();

    if (error) throw error;
    if (!order) {
      const err = new Error('Order not found');
      err.statusCode = 404;
      throw err;
    }

    if (order.pharmacies?.owner_id !== user.id) {
      const err = new Error('Access forbidden: You do not own this order\'s pharmacy');
      err.statusCode = 403;
      throw err;
    }

    // Eligible only if MEDICINES_PACKED or READY_FOR_PICKUP
    if (!['MEDICINES_PACKED', 'READY_FOR_PICKUP'].includes(order.status)) {
      const err = new Error(`Cannot generate token for unprepared, rejected, or completed order (Current status: ${order.status})`);
      err.statusCode = 400;
      throw err;
    }

    // Generate cryptographically secure random token
    const qrToken = crypto.randomBytes(32).toString('hex');
    const qrTokenHash = crypto.createHash('sha256').update(qrToken).digest('hex');
    const qrExpiresAt = new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(); // 2 hours validity

    // Upsert delivery record
    const { data: existingDelivery } = await supabase
      .from('deliveries')
      .select('id')
      .eq('order_id', orderId)
      .maybeSingle();

    if (existingDelivery) {
      const { error: delUpErr } = await supabase
        .from('deliveries')
        .update({
          qr_token_hash: qrTokenHash,
          partner_status: 'READY_FOR_PICKUP',
          qr_expires_at: qrExpiresAt,
          is_redeemed: false,
        })
        .eq('order_id', orderId);

      if (delUpErr) throw delUpErr;
    } else {
      const { error: delInErr } = await supabase.from('deliveries').insert([
        {
          id: uuidv4(),
          order_id: orderId,
          qr_token_hash: qrTokenHash,
          partner_status: 'READY_FOR_PICKUP',
          qr_expires_at: qrExpiresAt,
          is_redeemed: false,
          created_at: new Date().toISOString(),
        },
      ]);

      if (delInErr) throw delInErr;
    }

    // Update order status to READY_FOR_PICKUP
    await supabase
      .from('orders')
      .update({
        status: 'READY_FOR_PICKUP',
        updated_at: new Date().toISOString(),
      })
      .eq('id', orderId);

    return {
      qr_token: qrToken,
      order_id: orderId,
      status: 'READY_FOR_PICKUP',
    };
  }
}

module.exports = new OrderService();
