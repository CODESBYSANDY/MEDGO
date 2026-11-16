import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../utils/constants.dart';

class ApiConfigDialog extends StatefulWidget {
  const ApiConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ApiConfigDialog(),
    );
  }

  @override
  State<ApiConfigDialog> createState() => _ApiConfigDialogState();
}

class _ApiConfigDialogState extends State<ApiConfigDialog> {
  late TextEditingController _urlController;
  late bool _demoMode;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiConfig.baseUrl);
    _demoMode = ApiConfig.isDemoMode;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.dns_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Server Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure the MEDGO Node.js backend endpoint or toggle Demo Mode for standalone testing.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              'API Base URL',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'http://YOUR_SERVER_IP:5000/api/v1',
                prefixIcon: const Icon(Icons.link, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ActionChip(
                  label: const Text('Live Production (Render)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    _urlController.text = 'https://medgo-8pig.onrender.com/api/v1';
                  },
                ),
                ActionChip(
                  label: const Text('10.0.2.2 (Emulator)', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    _urlController.text = 'http://10.0.2.2:5000/api/v1';
                  },
                ),
                ActionChip(
                  label: const Text('localhost:5000', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    _urlController.text = 'http://localhost:5000/api/v1';
                  },
                ),
                ActionChip(
                  label: const Text('YOUR_SERVER_IP', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    _urlController.text = 'http://YOUR_SERVER_IP:5000/api/v1';
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _demoMode ? AppColors.primaryLight : AppColors.cardAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _demoMode ? AppColors.primary : AppColors.border,
                ),
              ),
              child: SwitchListTile(
                value: _demoMode,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                title: const Text(
                  'Demo / Mock Mode',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  _demoMode
                      ? 'Using separated local mock data (No backend required).'
                      : 'Connecting to live Node.js REST API.',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                onChanged: (val) {
                  setState(() {
                    _demoMode = val;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              ApiConfig.baseUrl = _urlController.text.trim();
              ApiConfig.isDemoMode = _demoMode;
            });
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _demoMode
                      ? 'Demo mode active. Simulated data enabled.'
                      : 'Connecting to ${ApiConfig.baseUrl}',
                ),
                backgroundColor: AppColors.primaryDark,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }
}
