const multer = require('multer');
const prescriptionService = require('../services/prescription.service');
const { prescriptionStatusSchema, validate } = require('../utils/validators');
const { sendSuccess, sendError } = require('../utils/response');

// Configure Multer for memory storage with MIME type and size validation
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedMimeTypes = ['image/jpeg', 'image/jpg', 'image/png'];
    if (allowedMimeTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only JPG, JPEG, and PNG images are allowed.'), false);
    }
  },
});

class PrescriptionController {
  /**
   * POST /api/v1/prescriptions
   * Multipart form-data: patient_id, image
   */
  async uploadPrescription(req, res, next) {
    try {
      const { patient_id } = req.body;
      const file = req.file;

      if (!patient_id) {
        return sendError(res, 'patient_id is required', 400);
      }

      if (!file) {
        return sendError(res, 'Prescription image is required (field name: image)', 400);
      }

      const result = await prescriptionService.uploadPrescription({
        customerId: req.user.id,
        patientIdentifier: patient_id,
        file,
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
   * GET /api/v1/patients/:patientId/prescriptions
   */
  async getPatientPrescriptions(req, res, next) {
    try {
      const { patientId } = req.params;

      const result = await prescriptionService.getPatientPrescriptions({
        user: req.user,
        patientIdentifier: patientId,
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
   * GET /api/v1/prescriptions/:id
   */
  async getPrescriptionById(req, res, next) {
    try {
      const { id } = req.params;

      const result = await prescriptionService.getPrescriptionById({
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
   * PATCH /api/v1/prescriptions/:id/status
   */
  async updatePrescriptionStatus(req, res, next) {
    try {
      const { id } = req.params;

      const val = validate(prescriptionStatusSchema, req.body);
      if (!val.success) {
        return sendError(res, val.error, 400);
      }

      const result = await prescriptionService.updatePrescriptionStatus({
        user: req.user,
        id,
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
  prescriptionController: new PrescriptionController(),
  upload,
};
