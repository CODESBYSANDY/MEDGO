import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/medicine_model.dart';
import '../../models/pharmacy_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/medicine_service.dart';
import '../../services/pharmacy_service.dart';
import '../../utils/constants.dart';
import '../../widgets/demo_mode_banner.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/medicine_card.dart';
import '../../widgets/pharmacy_card.dart';
import 'medicine_search_screen.dart';
import 'patient_prescriptions_screen.dart';
import 'pharmacy_details_screen.dart';
import 'prescription_upload_screen.dart';
import 'customer_orders_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final PharmacyService _pharmacyService = PharmacyService();
  final MedicineService _medicineService = MedicineService();

  List<PharmacyModel> _nearbyPharmacies = [];
  List<MedicineModel> _popularMedicines = [];

  bool _isLoadingPharmacies = true;
  bool _isLoadingMedicines = true;
  String? _pharmacyError;
  String? _medicineError;

  String _currentLocation = 'Madurai Central, Bypass Rd';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    _loadPharmacies();
    _loadMedicines();
  }

  Future<void> _loadPharmacies() async {
    setState(() {
      _isLoadingPharmacies = true;
      _pharmacyError = null;
    });

    try {
      final pharmacies = await _pharmacyService.getNearbyPharmacies(
        lat: 9.9252,
        lng: 78.1198,
        radiusKm: 5.0,
      );
      if (mounted) {
        setState(() {
          _nearbyPharmacies = pharmacies;
          _isLoadingPharmacies = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pharmacyError = e.toString();
          _isLoadingPharmacies = false;
        });
      }
    }
  }

  Future<void> _loadMedicines() async {
    setState(() {
      _isLoadingMedicines = true;
      _medicineError = null;
    });

    try {
      final medicines = await _medicineService.searchMedicines();
      if (mounted) {
        setState(() {
          _popularMedicines = medicines;
          _isLoadingMedicines = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _medicineError = e.toString();
          _isLoadingMedicines = false;
        });
      }
    }
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Delivery Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.my_location, color: AppColors.primary),
                title: const Text('Madurai Central, Bypass Rd'),
                subtitle: const Text('Current selected delivery point'),
                trailing: const Icon(Icons.check, color: AppColors.primary),
                onTap: () {
                  setState(() => _currentLocation = 'Madurai Central, Bypass Rd');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                title: const Text('Anna Nagar, Madurai'),
                subtitle: const Text('3.2 km away'),
                onTap: () {
                  setState(() => _currentLocation = 'Anna Nagar, Madurai');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                title: const Text('KK Nagar East Main Road'),
                subtitle: const Text('4.5 km away'),
                onTap: () {
                  setState(() => _currentLocation = 'KK Nagar East Main Road');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final userName = auth.currentUser?.name.split(' ').first ?? 'Arun';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $userName',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          InkWell(
                            onTap: _showLocationPicker,
                            borderRadius: BorderRadius.circular(6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _currentLocation,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No new notifications right now.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    InkWell(
                      onTap: () => ApiConfigDialog.show(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cardAlt,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.settings_outlined, size: 20, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Bar
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MedicineSearchScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Search medicines, pharmacies...',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(Icons.tune_rounded, color: AppColors.textLight, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // SECTION C: QUICK ACTIONS
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.document_scanner_outlined,
                        iconColor: AppColors.primaryDark,
                        bgColor: AppColors.primaryLight,
                        title: 'Upload\nPrescription',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PrescriptionUploadScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.badge_outlined,
                        iconColor: const Color(0xFF0284C7),
                        bgColor: const Color(0xFFE0F2FE),
                        title: 'Enter\nPatient ID',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PatientPrescriptionsScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.receipt_long_outlined,
                        iconColor: const Color(0xFF7C3AED),
                        bgColor: const Color(0xFFEDE9FE),
                        title: 'My\nOrders',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CustomerOrdersScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.local_pharmacy_outlined,
                        iconColor: const Color(0xFFD97706),
                        bgColor: const Color(0xFFFEF3C7),
                        title: 'Nearby\nPharmacies',
                        onTap: () {
                          // Scrolls to nearby pharmacies section
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // SECTION A: NEARBY PHARMACIES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nearby Pharmacies',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Within 5 km',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_isLoadingPharmacies)
                  const LoadingIndicator(message: 'Finding nearby licensed pharmacies...')
                else if (_pharmacyError != null)
                  _buildErrorBox(
                    message: _pharmacyError!,
                    onRetry: _loadPharmacies,
                  )
                else if (_nearbyPharmacies.isEmpty)
                  const EmptyStateWidget(
                    icon: Icons.storefront_outlined,
                    title: 'No Pharmacies Found',
                    description: 'No registered pharmacies available within your 5 km radius.',
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _nearbyPharmacies.length,
                    itemBuilder: (context, index) {
                      final pharmacy = _nearbyPharmacies[index];
                      return PharmacyCard(
                        pharmacy: pharmacy,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PharmacyDetailsScreen(pharmacy: pharmacy),
                            ),
                          );
                        },
                      );
                    },
                  ),
                const SizedBox(height: 20),

                // SECTION B: SEARCH / POPULAR MEDICINES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Essential Medicines',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MedicineSearchScreen()),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_isLoadingMedicines)
                  const LoadingIndicator(message: 'Loading available medicines...')
                else if (_medicineError != null)
                  _buildErrorBox(
                    message: _medicineError!,
                    onRetry: _loadMedicines,
                  )
                else if (_popularMedicines.isEmpty)
                  const EmptyStateWidget(
                    icon: Icons.medication_outlined,
                    title: 'No Medicines Listed',
                    description: 'Check back soon as pharmacies update their catalog.',
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _popularMedicines.take(6).length,
                    itemBuilder: (context, index) {
                      final med = _popularMedicines[index];
                      final cartQty = cart.getQuantity(med.id);

                      return MedicineCard(
                        medicine: med,
                        cartQuantity: cartQty,
                        onAdd: () {
                          final added = cart.addToCart(med);
                          if (!added) {
                            if (cart.pharmacyId != null && cart.pharmacyId != med.pharmacyId) {
                              _showReplaceCartDialog(med);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cannot add out of stock item.')),
                              );
                            }
                          }
                        },
                        onIncrement: () => cart.updateQuantity(med.id, cartQty + 1),
                        onDecrement: () => cart.updateQuantity(med.id, cartQty - 1),
                      );
                    },
                  ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBox({required String message, required VoidCallback onRetry}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  void _showReplaceCartDialog(MedicineModel newMed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace Cart Items?'),
        content: Text(
          'Your cart currently contains medicines from ${context.read<CartProvider>().pharmacyName}. Would you like to clear the cart and add medicines from ${newMed.pharmacyName} instead?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CartProvider>().addToCart(newMed, forceReplace: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Clear & Add'),
          ),
        ],
      ),
    );
  }
}
