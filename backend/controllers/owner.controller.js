const { supabase } = require('../config/supabase');
const { pharmacyAvailabilitySchema, validate } = require('../utils/validators');
const { sendSuccess, sendError } = require('../utils/response');

class OwnerController {
  /**
   * GET /api/v1/owner/dashboard
   */
  async getDashboard(req, res, next) {
    try {
      if (!supabase) {
        return sendError(res, 'Database client is not initialized', 500);
      }

      const ownerId = req.user.id;

      // Find pharmacies owned by user
      const { data: pharmacies, error: pharmErr } = await supabase
        .from('pharmacies')
        .select('id')
        .eq('owner_id', ownerId);

      if (pharmErr) throw pharmErr;

      if (!pharmacies || pharmacies.length === 0) {
        return sendError(res, 'No pharmacy found registered to this owner', 404);
      }

      const pharmacyIds = pharmacies.map((p) => p.id);

      // Fetch all orders for this owner's pharmacies
      const { data: orders, error: ordersErr } = await supabase
        .from('orders')
        .select('status')
        .in('pharmacy_id', pharmacyIds);

      if (ordersErr) throw ordersErr;

      let new_orders = 0;
      let accepted_orders = 0;
      let preparing_orders = 0;
      let completed_orders = 0;

      (orders || []).forEach((o) => {
        if (o.status === 'ORDER_PLACED') {
          new_orders++;
        } else if (['PHARMACY_ACCEPTED', 'PRESCRIPTION_VERIFIED'].includes(o.status)) {
          accepted_orders++;
        } else if (['MEDICINES_PACKED', 'READY_FOR_PICKUP'].includes(o.status)) {
          preparing_orders++;
        } else if (o.status === 'DELIVERED') {
          completed_orders++;
        }
      });

      return sendSuccess(
        res,
        {
          new_orders,
          accepted_orders,
          preparing_orders,
          completed_orders,
        },
        200
      );
    } catch (err) {
      if (err.statusCode) {
        return sendError(res, err.message, err.statusCode);
      }
      next(err);
    }
  }

  /**
   * GET /api/v1/owner/orders
   */
  async getOwnerOrders(req, res, next) {
    try {
      if (!supabase) {
        return sendError(res, 'Database client is not initialized', 500);
      }

      const ownerId = req.user.id;

      // Find pharmacies owned by user
      const { data: pharmacies, error: pharmErr } = await supabase
        .from('pharmacies')
        .select('id')
        .eq('owner_id', ownerId);

      if (pharmErr) throw pharmErr;

      if (!pharmacies || pharmacies.length === 0) {
        return sendSuccess(res, [], 200);
      }

      const pharmacyIds = pharmacies.map((p) => p.id);

      // Fetch orders
      const { data: orders, error: ordersErr } = await supabase
        .from('orders')
        .select(`
          id,
          customer_id,
          pharmacy_id,
          prescription_id,
          total_amount,
          status,
          created_at,
          users!customer_id (
            name
          ),
          order_items (
            medicine_id,
            quantity,
            price,
            medicines (
              name
            )
          )
        `)
        .in('pharmacy_id', pharmacyIds)
        .order('created_at', { ascending: false });

      if (ordersErr) throw ordersErr;

      const formatted = (orders || []).map((o) => ({
        id: o.id,
        customer_name: o.users?.name || 'Unknown',
        pharmacy_id: o.pharmacy_id,
        prescription_id: o.prescription_id,
        items: (o.order_items || []).map((item) => ({
          medicine_id: item.medicine_id,
          medicine_name: item.medicines?.name || 'Unknown Medicine',
          quantity: item.quantity,
          price: Number(item.price),
        })),
        total_amount: Number(o.total_amount),
        status: o.status,
        created_at: o.created_at,
      }));

      return sendSuccess(res, formatted, 200);
    } catch (err) {
      if (err.statusCode) {
        return sendError(res, err.message, err.statusCode);
      }
      next(err);
    }
  }

  /**
   * PATCH /api/v1/owner/pharmacy/availability
   * Or PATCH /api/v1/owner/pharmacies/:id/availability
   */
  async updateAvailability(req, res, next) {
    try {
      if (!supabase) {
        return sendError(res, 'Database client is not initialized', 500);
      }

      const val = validate(pharmacyAvailabilitySchema, req.body);
      if (!val.success) {
        return sendError(res, val.error, 400);
      }

      const ownerId = req.user.id;
      const pharmacyIdParam = req.params.id;

      let query = supabase.from('pharmacies').select('id, name, is_open').eq('owner_id', ownerId);
      if (pharmacyIdParam) {
        query = query.eq('id', pharmacyIdParam);
      }

      const { data: pharmacy, error: pharmErr } = await query.maybeSingle();

      if (pharmErr) throw pharmErr;
      if (!pharmacy) {
        return sendError(res, 'Pharmacy not found or unauthorized', 404);
      }

      const { data: updated, error: updateErr } = await supabase
        .from('pharmacies')
        .update({ is_open: val.data.is_open })
        .eq('id', pharmacy.id)
        .select('id, name, is_open')
        .single();

      if (updateErr) throw updateErr;

      return sendSuccess(
        res,
        {
          id: updated.id,
          name: updated.name,
          is_open: updated.is_open,
        },
        200
      );
    } catch (err) {
      if (err.statusCode) {
        return sendError(res, err.message, err.statusCode);
      }
      next(err);
    }
  }
}

module.exports = new OwnerController();
