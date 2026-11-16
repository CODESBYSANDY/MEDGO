import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme_config.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/customer/customer_main_nav.dart';
import 'screens/pharmacy_owner/owner_dashboard_screen.dart';
import 'screens/welcome/welcome_screen.dart';
import 'utils/constants.dart';
import 'widgets/loading_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations and system overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MedgoApp());
}

class MedgoApp extends StatelessWidget {
  const MedgoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initAuth()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'MEDGO',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // While reading stored token
    if (!auth.isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_hospital_rounded, size: 50, color: AppColors.primary),
              SizedBox(height: 16),
              LoadingIndicator(message: 'Initializing MEDGO...'),
            ],
          ),
        ),
      );
    }

    if (auth.isAuthenticated) {
      if (auth.isPharmacyOwner) {
        return const OwnerDashboardScreen();
      } else {
        return const CustomerMainNav();
      }
    }

    return const WelcomeScreen();
  }
}
