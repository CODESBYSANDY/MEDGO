import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/prescription_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/prescription_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import 'prescription_upload_screen.dart';

class PatientPrescriptionsScreen extends StatefulWidget {
  final String? initialPatientId;

  const PatientPrescriptionsScreen({super.key, this.initialPatientId});

  @override
  State<PatientPrescriptionsScreen> createState() => _PatientPrescriptionsScreenState();
}

class _PatientPrescriptionsScreenState extends State<PatientPrescriptionsScreen> {
  final PrescriptionService _prescriptionService = PrescriptionService();
  final _patientIdController = TextEditingController(text: 'PAT1001');

  List<PrescriptionModel> _prescriptions = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialPatientId != null && widget.initialPatientId!.isNotEmpty) {
      _patientIdController.text = widget.initialPatientId!;
    }
    _fetchPrescriptions();
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchPrescriptions() async {
    final patientId = _patientIdController.text.trim();
    if (patientId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final records = await _prescriptionService.getPatientPrescriptions(patientId);
      if (mounted) {
        setState(() {
          _prescriptions = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Authorized Prescriptions'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Patient ID search box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search Patient Hospital Record',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter your Patient ID to load authorized digital prescriptions from the backend.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _patientIdController,
                          label: '',
                          hint: 'Enter Patient ID (e.g. PAT-8801)',
                          prefixIcon: Icons.badge_outlined,
                          onSubmitted: (_) => _fetchPrescriptions(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _fetchPrescriptions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Fetch', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const LoadingIndicator(message: 'Querying authorized prescription records...')
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 40, color: AppColors.error),
                                const SizedBox(height: 12),
                                Text(_errorMessage!, textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchPrescriptions,
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : !_hasSearched
                          ? const EmptyStateWidget(
                              icon: Icons.person_search_outlined,
                              title: 'Enter Patient ID',
                              description: 'Type your Patient ID and tap Fetch to view your prescription history.',
                            )
                          : _prescriptions.isEmpty
                              ? EmptyStateWidget(
                                  icon: Icons.medical_services_outlined,
                                  title: 'No Prescriptions Found',
                                  description: 'No authorized prescription records found for "${_patientIdController.text.trim()}".',
                                  buttonText: 'Upload New Prescription',
                                  onButtonPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const PrescriptionUploadScreen()),
                                    );
                                  },
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _prescriptions.length,
                                  itemBuilder: (context, index) {
                                    final rx = _prescriptions[index];
                                    final isAttached = cart.prescriptionId == rx.id;

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: isAttached ? AppColors.primary : AppColors.border,
                                          width: isAttached ? 2 : 1,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primaryLight,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Icon(Icons.description_outlined, color: AppColors.primaryDark),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        rx.doctorName,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w700,
                                                          color: AppColors.textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Prescription ID: ${rx.id}',
                                                        style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                _buildStatusChip(rx.status),
                                              ],
                                            ),
                                            if (rx.details != null && rx.details!.isNotEmpty) ...[
                                              const SizedBox(height: 10),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: AppColors.cardAlt,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  rx.details!,
                                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 12),
                                            const Text(
                                              'Prescribed Medicines:',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                            ),
                                            const SizedBox(height: 6),
                                            ...rx.medicines.map(
                                              (item) => Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 2),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.circle, size: 6, color: AppColors.primary),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        item.medicineName,
                                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                                      ),
                                                    ),
                                                    Text(
                                                      'Qty: ${item.quantity}',
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            const Divider(height: 1, color: AppColors.border),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  AppFormatters.formatDate(rx.createdAt),
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                                ),
                                                if (isAttached)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primaryLight,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Row(
                                                      children: [
                                                        Icon(Icons.check, size: 14, color: AppColors.primaryDark),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'Attached to Cart',
                                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                else
                                                  TextButton.icon(
                                                    onPressed: () {
                                                      cart.attachPrescription(
                                                        rx.id,
                                                        patientId: rx.patientId,
                                                      );
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Prescription ${rx.id} attached to cart.'),
                                                          backgroundColor: AppColors.primaryDark,
                                                        ),
                                                      );
                                                    },
                                                    icon: const Icon(Icons.attach_file, size: 15),
                                                    label: const Text('Use for Cart Checkout'),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg = AppColors.warningBg;
    Color fg = AppColors.warning;
    if (status.toUpperCase() == 'VERIFIED') {
      bg = AppColors.successBg;
      fg = AppColors.success;
    } else if (status.toUpperCase() == 'REJECTED') {
      bg = AppColors.errorBg;
      fg = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
