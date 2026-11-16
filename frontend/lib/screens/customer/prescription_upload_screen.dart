import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/prescription_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'patient_prescriptions_screen.dart';

class PrescriptionUploadScreen extends StatefulWidget {
  const PrescriptionUploadScreen({super.key});

  @override
  State<PrescriptionUploadScreen> createState() => _PrescriptionUploadScreenState();
}

class _PrescriptionUploadScreenState extends State<PrescriptionUploadScreen> {
  final PrescriptionService _prescriptionService = PrescriptionService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _patientIdController = TextEditingController(text: 'PAT1001');

  XFile? _selectedImage;
  bool _isUploading = false;
  String? _uploadError;
  bool _uploadSuccess = false;
  String? _uploadedPrescriptionId;

  @override
  void dispose() {
    _patientIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _selectedImage = picked;
          _uploadError = null;
        });
      }
    } catch (e) {
      setState(() {
        _uploadError = 'Error picking image: ${e.toString()}';
      });
    }
  }

  Future<void> _submitPrescription() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      setState(() {
        _uploadError = 'Please capture or select a prescription image to proceed.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      final result = await _prescriptionService.uploadPrescription(
        patientId: _patientIdController.text.trim(),
        imageFilePath: _selectedImage!.path,
      );

      final rxId = result['id']?.toString() ?? 'prescription-${DateTime.now().millisecondsSinceEpoch}';

      if (mounted) {
        // Automatically attach to cart if prescription needed
        context.read<CartProvider>().attachPrescription(
          rxId,
          patientId: _patientIdController.text.trim(),
        );

        setState(() {
          _isUploading = false;
          _uploadSuccess = true;
          _uploadedPrescriptionId = rxId;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Upload Prescription'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _uploadSuccess
              ? _buildSuccessView()
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Instructions banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, color: AppColors.primaryDark, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'A valid prescription with doctor details, clinic seal, and date is required by law for Schedule H & X medicines.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryDark,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Patient ID field
                      CustomTextField(
                        controller: _patientIdController,
                        label: 'Patient Hospital / Clinical ID',
                        hint: 'e.g. PAT-8801',
                        prefixIcon: Icons.badge_outlined,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter Patient ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Prescription Image',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Image Preview or Placeholder
                      Container(
                        height: 240,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedImage != null ? AppColors.primary : AppColors.border,
                            width: _selectedImage != null ? 1.5 : 1,
                          ),
                        ),
                        child: _selectedImage != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: kIsWeb
                                        ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                                        : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.white),
                                        onPressed: () {
                                          setState(() {
                                            _selectedImage = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: AppColors.cardAlt,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'No prescription image selected',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Capture clearly via Camera or choose from Gallery',
                                        style: TextStyle(fontSize: 12, color: AppColors.textLight),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Image Source Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_outlined, size: 18),
                              label: const Text('Capture Camera'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined, size: 18),
                              label: const Text('Select Gallery'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (_uploadError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.error.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _uploadError!,
                                  style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Submit Button
                      CustomButton(
                        text: 'Upload Prescription (Multipart)',
                        icon: Icons.cloud_upload_outlined,
                        isLoading: _isUploading,
                        onPressed: _submitPrescription,
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PatientPrescriptionsScreen()),
                            );
                          },
                          icon: const Icon(Icons.badge_outlined, size: 16),
                          label: const Text('View Prescriptions by Patient ID'),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, size: 48, color: AppColors.success),
            ),
            const SizedBox(height: 20),
            const Text(
              'Prescription Uploaded Successfully',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Prescription ID: $_uploadedPrescriptionId\nPatient ID: ${_patientIdController.text.trim()}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Prescription automatically attached to your current Cart',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'View Authorized Prescriptions',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PatientPrescriptionsScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Back to Home',
              isOutlined: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
