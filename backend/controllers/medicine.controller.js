const { supabase } = require('../config/supabase');
const { medicineQuerySchema, validate } = require('../utils/validators');
const { sendSuccess, sendError } = require('../utils/response');

class MedicineController {
  /**
   * GET /api/v1/medicines
   * Query params: search, pharmacy_id
   */
  async getMedicines(req, res, next) {
    try {
      if (!supabase) {
        return sendError(res, 'Database client is not initialized', 500);
      }

      const val = validate(medicineQuerySchema, req.query);
      if (!val.success) {
        return sendError(res, val.error, 400);
      }

      const { search, pharmacy_id } = val.data;

      let query = supabase
        .from('medicines')
        .select('id, pharmacy_id, name, price, stock, requires_prescription')
        .gt('stock', 0); // Return only valid active stock

      if (pharmacy_id) {
        query = query.eq('pharmacy_id', pharmacy_id);
      }

      if (search && search.trim() !== '') {
        query = query.ilike('name', `%${search.trim()}%`);
      }

      const { data: medicines, error } = await query.order('name', { ascending: true });

      if (error) {
        throw error;
      }

      const formatted = (medicines || []).map((m) => ({
        id: m.id,
        pharmacy_id: m.pharmacy_id,
        name: m.name,
        price: Number(m.price),
        stock: m.stock,
        requires_prescription: m.requires_prescription,
      }));

      return sendSuccess(res, formatted, 200);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new MedicineController();
