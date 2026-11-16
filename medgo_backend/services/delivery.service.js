const crypto = require('crypto');
const { supabase } = require('../config/supabase');

class DeliveryService {
  /**
   * Verify delivery QR token presented by delivery partner
   */
  async verifyQrToken({ qrToken }) {
    if (!supabase) {
      const err = new Error('Database client is not initialized');
      err.statusCode = 500;
      throw err;
    }

    if (!qrToken) {
      const err = new Error('qr_token is required');
      err.statusCode = 400;
      throw err;
    }

    // Compute SHA-256 hash of provided token
    const tokenHash = crypto.createHash('sha256').update(qrToken.trim()).digest('hex');

    // Look up delivery record
    const { data: delivery, error: delErr } = await supabase
      .from('deliveries')
      .select(`
        id,
        order_id,
        qr_token_hash,
        partner_status,
        qr_expires_at,
        is_redeemed,
        orders (
          id,
          status,
          pharmacies (
            name
          )
        )
      `)
      .eq('qr_token_hash', tokenHash)
      .maybeSingle();

    if (delErr) throw delErr;

    if (!delivery) {
      const err = new Error('Invalid or unrecognized QR token');
      err.statusCode = 400;
      throw err;
    }

    // Check replay attack / already redeemed
    if (delivery.is_redeemed) {
      const err = new Error('QR token has already been redeemed. Replay attacks are prohibited.');
      err.statusCode = 400;
      throw err;
    }

    // Check expiration
    if (delivery.qr_expires_at && new Date(delivery.qr_expires_at) < new Date()) {
      const err = new Error('QR token has expired');
      err.statusCode = 400;
      throw err;
    }

    // Check order readiness
    const order = delivery.orders;
    if (!order) {
      const err = new Error('Associated order not found');
      err.statusCode = 404;
      throw err;
    }

    if (order.status !== 'READY_FOR_PICKUP') {
      const err = new Error(`Parcel is not ready for pickup. Order status: ${order.status}`);
      err.statusCode = 400;
      throw err;
    }

    // Mark token as redeemed to prevent replay attacks
    const { error: markErr } = await supabase
      .from('deliveries')
      .update({
        is_redeemed: true,
      })
      .eq('id', delivery.id);

    if (markErr) throw markErr;

    return {
      order_id: delivery.order_id,
      pharmacy_name: order.pharmacies ? order.pharmacies.name : '',
      status: 'READY_FOR_PICKUP',
      verified: true,
    };
  }

  /**
   * Update delivery status (PICKED_UP or DELIVERED)
   */
  async updateDeliveryStatus({ orderId, status }) {
    if (!supabase) {
      const err = new Error('Database client is not initialized');
      err.statusCode = 500;
      throw err;
    }

    // Fetch delivery and order records
    const { data: delivery, error: delErr } = await supabase
      .from('deliveries')
      .select('id, order_id, partner_status, is_redeemed, picked_up_at, delivered_at')
      .eq('order_id', orderId)
      .maybeSingle();

    if (delErr) throw delErr;

    const { data: order, error: orderErr } = await supabase
      .from('orders')
      .select('id, status')
      .eq('id', orderId)
      .maybeSingle();

    if (orderErr) throw orderErr;

    if (!order) {
      const err = new Error('Order not found');
      err.statusCode = 404;
      throw err;
    }

    const currentOrderStatus = order.status;
    const nowIso = new Date().toISOString();

    if (status === 'PICKED_UP') {
      if (currentOrderStatus !== 'READY_FOR_PICKUP') {
        const err = new Error(`Cannot mark PICKED_UP when order status is ${currentOrderStatus}. Must be READY_FOR_PICKUP.`);
        err.statusCode = 400;
        throw err;
      }

      if (delivery && delivery.picked_up_at) {
        const err = new Error('Order has already been marked as picked up');
        err.statusCode = 400;
        throw err;
      }

      // Update delivery record
      if (delivery) {
        await supabase
          .from('deliveries')
          .update({
            partner_status: 'PICKED_UP',
            picked_up_at: nowIso,
          })
          .eq('id', delivery.id);
      }

      // Update order status
      await supabase
        .from('orders')
        .update({
          status: 'PICKED_UP',
          updated_at: nowIso,
        })
        .eq('id', orderId);

      return {
        order_id: orderId,
        status: 'PICKED_UP',
      };
    } else if (status === 'DELIVERED') {
      if (currentOrderStatus !== 'PICKED_UP') {
        const err = new Error(`Cannot mark DELIVERED when order status is ${currentOrderStatus}. Must be PICKED_UP.`);
        err.statusCode = 400;
        throw err;
      }

      if (delivery && delivery.delivered_at) {
        const err = new Error('Order has already been marked as delivered');
        err.statusCode = 400;
        throw err;
      }

      // Update delivery record
      if (delivery) {
        await supabase
          .from('deliveries')
          .update({
            partner_status: 'DELIVERED',
            delivered_at: nowIso,
          })
          .eq('id', delivery.id);
      }

      // Update order status
      await supabase
        .from('orders')
        .update({
          status: 'DELIVERED',
          updated_at: nowIso,
        })
        .eq('id', orderId);

      return {
        order_id: orderId,
        status: 'DELIVERED',
      };
    } else {
      const err = new Error(`Invalid delivery status: ${status}. Must be PICKED_UP or DELIVERED.`);
      err.statusCode = 400;
      throw err;
    }
  }
}

module.exports = new DeliveryService();
