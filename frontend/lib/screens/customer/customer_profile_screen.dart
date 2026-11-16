import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/demo_mode_banner.dart';
import '../welcome/welcome_screen.dart';
import 'patient_prescriptions_screen.dart';
import 'prescription_upload_screen.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // User Avatar Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Customer',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'customer@medgo.com',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          if (user?.phone != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              user!.phone!,
                              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'CUSTOMER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Health Records Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.document_scanner_outlined, color: AppColors.primary),
                      title: const Text('Upload New Prescription', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PrescriptionUploadScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    ListTile(
                      leading: const Icon(Icons.badge_outlined, color: AppColors.primary),
                      title: const Text('Authorized Clinical Records (Patient ID)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PatientPrescriptionsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Application & Backend Configuration
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.dns_rounded, color: AppColors.primary),
                      title: const Text('Backend Server IP / Demo Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                        ApiConfig.isDemoMode ? 'Active: Separated Demo Mock Mode' : 'Connected: ${ApiConfig.baseUrl}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => ApiConfigDialog.show(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    context.read<CartProvider>().clearCart();
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: const Text('Log Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
