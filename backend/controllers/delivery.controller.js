const jwt = require('jsonwebtoken');
const deliveryService = require('../services/delivery.service');
const { verifyQrSchema, updateDeliveryStatusSchema, validate } = require('../utils/validators');
const { sendSuccess, sendError } = require('../utils/response');
const { JWT_SECRET } = require('../config/jwt');

const DEMO_DELIVERY_KEY = process.env.DELIVERY_API_KEY || 'medgo-delivery-demo-key-2026';

/**
 * Delivery Partner Authentication Middleware
 * Validates either the dedicated x-delivery-key header or a DELIVERY_PARTNER role JWT.
 * Prevents customer or pharmacy_owner roles from accessing delivery partner functions.
 */
const authenticateDeliveryPartner = (req, res, next) => {
  const deliveryKey = req.headers['x-delivery-key'];
  if (deliveryKey && deliveryKey === DEMO_DELIVERY_KEY) {
    req.user = {
      id: 'demo-delivery-partner-id',
      role: 'DELIVERY_PARTNER',
      name: 'Demo Delivery Partner',
    };
    return next();
  }

  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const token = authHeader.split(' ')[1];
      const decoded = jwt.verify(token, JWT_SECRET);
      if (decoded.role === 'DELIVERY_PARTNER') {
        req.user = decoded;
        return next();
      }
    } catch (e) {
      // Fall through to 401
    }
  }

  return sendError(
    res,
    'Unauthorized: Valid delivery partner credentials required (use x-delivery-key header or delivery token)',
    401
  );
};

class DeliveryController {
  /**
   * Optional helper endpoint to obtain a demo delivery partner token
   * POST /api/v1/delivery/auth
   */
  async getDemoToken(req, res) {
    const { key } = req.body;
    if (key && key !== DEMO_DELIVERY_KEY) {
      return sendError(res, 'Invalid delivery key', 401);
    }
    const token = jwt.sign(
      {
        id: 'demo-delivery-partner-id',
        role: 'DELIVERY_PARTNER',
        name: 'Demo Delivery Partner',
      },
      JWT_SECRET,
      { expiresIn: '1d' }
    );
    return sendSuccess(res, { token }, 200);
  }

  /**
   * POST /api/v1/delivery/verify
   */
  async verifyQr(req, res, next) {
    try {
      const val = validate(verifyQrSchema, req.body);
      if (!val.success) {
        return sendError(res, val.error, 400);
      }

      const result = await deliveryService.verifyQrToken({
        qrToken: val.data.qr_token,
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
   * PATCH /api/v1/delivery/:orderId/status
   */
  async updateStatus(req, res, next) {
    try {
      const { orderId } = req.params;

      const val = validate(updateDeliveryStatusSchema, req.body);
      if (!val.success) {
        return sendError(res, val.error, 400);
      }

      const result = await deliveryService.updateDeliveryStatus({
        orderId,
        status: val.data.status,
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

module.exports = {
  deliveryController: new DeliveryController(),
  authenticateDeliveryPartner,
};
