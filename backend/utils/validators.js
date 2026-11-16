const { z } = require('zod');

// Regex for 10-15 digit phone numbers
const phoneRegex = /^\+?[0-9]{10,15}$/;

// Auth validation schemas
const registerSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters long'),
  email: z.string().email('Invalid email address'),
  phone: z.string().regex(phoneRegex, 'Invalid phone number format (must be 10-15 digits)'),
  password: z.string().min(6, 'Password must be at least 6 characters long'),
  role: z.enum(['CUSTOMER', 'PHARMACY_OWNER'], {
    errorMap: () => ({ message: "Role must be either 'CUSTOMER' or 'PHARMACY_OWNER'" }),
  }),
});

const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
});

// Pharmacy validation schemas
const nearbyPharmaciesSchema = z.object({
  lat: z.coerce.number().min(-90).max(90, 'Latitude must be between -90 and 90'),
  lng: z.coerce.number().min(-180).max(180, 'Longitude must be between -180 and 180'),
  radius_km: z.coerce.number().positive('Radius must be positive').optional(),
});

const pharmacyAvailabilitySchema = z.object({
  is_open: z.boolean({ required_error: 'is_open is required and must be a boolean' }),
});

// Medicine validation schema
const medicineQuerySchema = z.object({
  search: z.string().optional(),
  pharmacy_id: z.string().uuid('Invalid pharmacy ID format').optional(),
});

// Prescription validation schemas
const prescriptionStatusSchema = z.object({
  status: z.enum(['PENDING', 'VERIFIED', 'REJECTED'], {
    errorMap: () => ({ message: "Status must be 'PENDING', 'VERIFIED', or 'REJECTED'" }),
  }),
});

// Order validation schemas
const createOrderItemSchema = z.object({
  medicine_id: z.string().uuid('Invalid medicine ID format'),
  quantity: z.number().int().positive('Quantity must be an integer greater than 0'),
});

const createOrderSchema = z.object({
  pharmacy_id: z.string().uuid('Invalid pharmacy ID format'),
  prescription_id: z.string().uuid('Invalid prescription ID format').optional().nullable(),
  items: z.array(createOrderItemSchema).min(1, 'Order must contain at least one item'),
});

const orderStatusEnum = z.enum([
  'ORDER_PLACED',
  'PHARMACY_ACCEPTED',
  'PRESCRIPTION_VERIFIED',
  'MEDICINES_PACKED',
  'READY_FOR_PICKUP',
  'PICKED_UP',
  'DELIVERED',
  'REJECTED',
  'CANCELLED',
], {
  errorMap: () => ({ message: 'Invalid order status' }),
});

const updateOrderStatusSchema = z.object({
  status: orderStatusEnum,
});

// Delivery validation schemas
const verifyQrSchema = z.object({
  qr_token: z.string().min(1, 'qr_token is required'),
});

const updateDeliveryStatusSchema = z.object({
  status: z.enum(['PICKED_UP', 'DELIVERED'], {
    errorMap: () => ({ message: "Delivery status must be 'PICKED_UP' or 'DELIVERED'" }),
  }),
});

/**
 * Helper to validate request payload against a Zod schema
 * @param {z.ZodSchema} schema - Zod schema
 * @param {Object} data - Input data
 * @returns {{ success: boolean, data?: any, error?: string }}
 */
const validate = (schema, data) => {
  const result = schema.safeParse(data);
  if (!result.success) {
    const errorMsg = result.error.errors.map((e) => e.message).join(', ');
    return { success: false, error: errorMsg };
  }
  return { success: true, data: result.data };
};

module.exports = {
  registerSchema,
  loginSchema,
  nearbyPharmaciesSchema,
  pharmacyAvailabilitySchema,
  medicineQuerySchema,
  prescriptionStatusSchema,
  createOrderSchema,
  updateOrderStatusSchema,
  verifyQrSchema,
  updateDeliveryStatusSchema,
  validate,
};
