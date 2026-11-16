import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../pharmacy_owner/owner_dashboard_screen.dart';

class PharmacyRegisterScreen extends StatefulWidget {
  const PharmacyRegisterScreen({super.key});

  @override
  State<PharmacyRegisterScreen> createState() => _PharmacyRegisterScreenState();
}

class _PharmacyRegisterScreenState extends State<PharmacyRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerNameController = TextEditingController(text: 'Dr. Rajesh Sundaram');
  final _pharmacyNameController = TextEditingController(text: 'Apollo Pharmacy');
  final _emailController = TextEditingController(text: 'apollo@gmail.com');
  final _phoneController = TextEditingController(text: '9876543210');
  final _addressController = TextEditingController(text: '142 Bypass Road, Madurai');
  final _passwordController = TextEditingController(text: '123456');

  @override
  void dispose() {
    _ownerNameController.dispose();
    _pharmacyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.registerPharmacyOwner(
      ownerName: _ownerNameController.text.trim(),
      pharmacyName: _pharmacyNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const OwnerDashboardScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Pharmacy'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Onboard Your Pharmacy',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Register your pharmacy to receive and fulfill digital orders on MEDGO',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                if (auth.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            auth.errorMessage!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Owner Name
                CustomTextField(
                  controller: _ownerNameController,
                  label: 'Owner / Head Pharmacist Name',
                  hint: 'e.g. Dr. Rajesh Kumar',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter owner name' : null,
                ),
                const SizedBox(height: 16),

                // Pharmacy Name
                CustomTextField(
                  controller: _pharmacyNameController,
                  label: 'Pharmacy / Medical Shop Name',
                  hint: 'e.g. Apollo Pharmacy & Wellness',
                  prefixIcon: Icons.local_pharmacy_outlined,
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter pharmacy name' : null,
                ),
                const SizedBox(height: 16),

                // Email
                CustomTextField(
                  controller: _emailController,
                  label: 'Registered Business Email',
                  hint: 'pharmacy@domain.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter business email';
                    if (!val.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                CustomTextField(
                  controller: _phoneController,
                  label: 'Contact Phone Number',
                  hint: '10-digit pharmacy contact number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter phone number';
                    if (val.trim().length < 10) return 'Enter a valid 10-digit number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Address
                CustomTextField(
                  controller: _addressController,
                  label: 'Pharmacy Physical Address',
                  hint: 'Full physical shop address with landmark',
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 2,
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter address' : null,
                ),
                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  controller: _passwordController,
                  label: 'Portal Password',
                  hint: 'Minimum 6 characters',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter password';
                    if (val.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                CustomButton(
                  text: 'Complete Pharmacy Registration',
                  backgroundColor: AppColors.secondary,
                  isLoading: auth.isLoading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
