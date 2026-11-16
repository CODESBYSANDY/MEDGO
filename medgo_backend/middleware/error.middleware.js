const { sendError } = require('../utils/response');

/**
 * Global Error Handling Middleware
 */
const errorHandler = (err, req, res, next) => {
  // Handle JSON parsing errors in body
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    return sendError(res, 'Malformed JSON payload', 400);
  }

  // Handle Multer upload errors
  if (err.name === 'MulterError') {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return sendError(res, 'File size exceeds maximum allowed limit (5MB)', 400);
    }
    return sendError(res, `File upload error: ${err.message}`, 400);
  }

  // Custom client errors
  if (err.statusCode && err.statusCode < 500) {
    return sendError(res, err.message, err.statusCode);
  }

  // Unhandled / Internal errors
  console.error('[Unhandled Error]:', err);
  return sendError(
    res,
    process.env.NODE_ENV === 'production' ? 'Internal server error' : err.message || 'Internal server error',
    500
  );
};

module.exports = {
  errorHandler,
};
