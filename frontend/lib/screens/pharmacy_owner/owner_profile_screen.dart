import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/demo_mode_banner.dart';
import '../welcome/welcome_screen.dart';

class OwnerProfileScreen extends StatelessWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pharmacy Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Owner Card
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
                      backgroundColor: const Color(0xFFE0F2FE),
                      child: Text(
                        user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'P',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Dr. Rajesh Sundaram',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.pharmacyName ?? 'Apollo Pharmacy & Wellness',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'apollo@gmail.com',
                            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Server and Configuration
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: const Icon(Icons.dns_rounded, color: AppColors.secondary),
                  title: const Text('Backend Server & API Config', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    ApiConfig.isDemoMode ? 'Active: Separated Demo Mock Mode' : 'Connected: ${ApiConfig.baseUrl}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ApiConfigDialog.show(context),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
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
                  label: const Text('Log Out of Pharmacy Portal', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
