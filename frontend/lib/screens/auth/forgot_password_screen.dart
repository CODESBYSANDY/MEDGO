import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final bool isOwner;

  const ForgotPasswordScreen({super.key, this.isOwner = false});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _submitted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: _submitted
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: AppColors.successBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mark_email_read_rounded, size: 36, color: AppColors.success),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Password Reset Link Sent',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We have sent instructions to ${_emailController.text.trim()}. Please check your inbox.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Back to Login',
                      backgroundColor: widget.isOwner ? AppColors.secondary : AppColors.primary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'Forgot Your Password?',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enter your registered email address and we will send you instructions to reset your password.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 28),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Registered Email',
                        hint: 'name@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Please enter your email';
                          if (!val.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      CustomButton(
                        text: 'Send Reset Link',
                        backgroundColor: widget.isOwner ? AppColors.secondary : AppColors.primary,
                        isLoading: _isLoading,
                        onPressed: _handleSubmit,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
