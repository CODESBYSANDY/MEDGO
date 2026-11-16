const orderService = require('../services/order.service');
const { createOrderSchema, updateOrderStatusSchema, validate } = require('../utils/validators');
const { sendSuccess, sendError } = require('../utils/response');

class OrderController {
  /**
   * POST /api/v1/orders
   */
  async createOrder(req, res, next) {
    try {
      const val = validate(createOrderSchema, req.body);
      if (!val.success) {
        return sendError(res, val.error, 400);
      }

      const { pharmacy_id, prescription_id, items } = val.data;

      const result = await orderService.createOrder({
        customerId: req.user.id,
        pharmacyId: pharmacy_id,
        prescriptionId: prescription_id,
        items,
      });

      return sendSuccess(res, result, 201);
    } catch (err) {
      if (err.statusCode) {
        return sendError(res, err.message, err.statusCode);
      }
      next(err);
    }
  }

  /**
   * GET /api/v1/orders/:id
   */
  async getOrderById(req, res, next) {
    try {
      const { id } = req.params;

      const result = await orderService.getOrderById({
        user: req.user,
        id,
      });

      return sendSuccess(res, result, 200);
    } catch (err) {
      if (err.statusCode) {
        return sendError(res, err.message, err.statusCode);
      }
      next(err);
    }
  }

  /**
   * PATCH /api/v1/orders/:id/status
   */
  async updateOrderStatus(req, res, next) {
    try {
      const { id } = req.params;

      const val = validate(updateOrderStatusSchema, req.body);
      if (!val.success) {
        return sendError(res, val.error, 400);
      }

      const result = await orderService.updateOrderStatus({
        user: req.user,
        orderId: id,
        newStatus: val.data.status,
      });

      return sendSuccess(res, result, 200);
    } catch (err) {
      if (err.statusCode) {
        return sendError(res, err.message, err.statusCode);
      }
      next(err);
    }
  }

  /**
   * POST /api/v1/orders/:id/qr
   */
  async generateParcelToken(req, res, next) {
    try {
      const { id } = req.params;

      const result = await orderService.generateParcelToken({
        user: req.user,
        orderId: id,
      });

      return sendSuccess(res, result, 200);
    } catch (err) {
      if (err.statusCode) {
        return sendError(res, err.message, err.statusCode);
      }
      next(err);
    }
  }
}

module.exports = new OrderController();
