const { sendError } = require('../utils/response');

/**
 * Role-Based Access Control Middleware
 * @param  {...string} allowedRoles - List of permitted roles (e.g. 'CUSTOMER', 'PHARMACY_OWNER')
 */
const requireRole = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return sendError(res, 'Authentication required', 401);
    }

    if (!allowedRoles.includes(req.user.role)) {
      return sendError(
        res,
        `Access forbidden: requires one of the following roles: ${allowedRoles.join(', ')}`,
        403
      );
    }

    next();
  };
};

module.exports = {
  requireRole,
};
