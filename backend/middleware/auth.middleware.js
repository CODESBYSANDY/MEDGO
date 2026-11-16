const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../config/jwt');
const { sendError } = require('../utils/response');

/**
 * Authentication Middleware
 * Validates the JWT Bearer token in the Authorization header
 */
const authenticate = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return sendError(res, 'Authorization token required in Bearer format', 401);
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      return sendError(res, 'Token missing from authorization header', 401);
    }

    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return sendError(res, 'Token has expired', 401);
    }
    return sendError(res, 'Invalid authorization token', 401);
  }
};

module.exports = {
  authenticate,
};
