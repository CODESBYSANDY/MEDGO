const authService = require('../services/auth.service');
const { registerSchema, loginSchema, validate } = require('../utils/validators');
const { sendSuccess, sendError } = require('../utils/response');

class AuthController {
  /**
   * POST /api/v1/auth/register
   */
  async register(req, res, next) {
    try {
      const validation = validate(registerSchema, req.body);
      if (!validation.success) {
        return sendError(res, validation.error, 400);
      }

      const result = await authService.register(validation.data);
      return sendSuccess(res, result, 201);
    } catch (err) {
      if (err.statusCode) {
        return sendError(res, err.message, err.statusCode);
      }
      next(err);
    }
  }

  /**
   * POST /api/v1/auth/login
   */
  async login(req, res, next) {
    try {
      const validation = validate(loginSchema, req.body);
      if (!validation.success) {
        return sendError(res, validation.error, 400);
      }

      const result = await authService.login(validation.data);
      return sendSuccess(res, result, 200);
    } catch (err) {
      if (err.statusCode) {
        return sendError(res, err.message, err.statusCode);
      }
      next(err);
    }
  }

  /**
   * GET /api/v1/auth/me
   */
  async me(req, res, next) {
    try {
      const result = await authService.getCurrentUser(req.user.id);
      return sendSuccess(res, result, 200);
    } catch (err) {
      if (err.statusCode) {
        return sendError(res, err.message, err.statusCode);
      }
      next(err);
    }
  }
}

module.exports = new AuthController();
