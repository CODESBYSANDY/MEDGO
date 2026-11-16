import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/medicine_model.dart';
import '../../models/pharmacy_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/medicine_service.dart';
import '../../services/pharmacy_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/medicine_card.dart';
import 'cart_screen.dart';

class PharmacyDetailsScreen extends StatefulWidget {
  final PharmacyModel pharmacy;

  const PharmacyDetailsScreen({super.key, required this.pharmacy});

  @override
  State<PharmacyDetailsScreen> createState() => _PharmacyDetailsScreenState();
}

class _PharmacyDetailsScreenState extends State<PharmacyDetailsScreen> {
  final PharmacyService _pharmacyService = PharmacyService();
  final MedicineService _medicineService = MedicineService();
  final TextEditingController _searchController = TextEditingController();

  late PharmacyModel _currentPharmacy;
  List<MedicineModel> _medicines = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentPharmacy = widget.pharmacy;
    _loadPharmacyData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPharmacyData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Refresh pharmacy details from backend
      try {
        final refreshed = await _pharmacyService.getPharmacyDetails(_currentPharmacy.id);
        _currentPharmacy = refreshed;
      } catch (_) {
        // Fallback to widget.pharmacy if single details fails
      }

      final medicines = await _medicineService.searchMedicines(
        pharmacyId: _currentPharmacy.id,
        search: _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _medicines = medicines;
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
        title: Text(_currentPharmacy.name),
        actions: [
          if (cart.totalItemCount > 0)
            IconButton(
              icon: Badge(
                label: Text('${cart.totalItemCount}'),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPharmacyData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pharmacy Header Info Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primaryDark, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentPharmacy.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Owner: ${_currentPharmacy.ownerName}',
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 10),

                      // Status & Working hours
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _currentPharmacy.isOpen ? AppColors.successBg : AppColors.errorBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _currentPharmacy.isOpen ? 'OPEN NOW' : 'CLOSED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _currentPharmacy.isOpen ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${_currentPharmacy.openingTime} - ${_currentPharmacy.closingTime}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Address
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _currentPharmacy.address,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.cardAlt,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              AppFormatters.formatDistance(_currentPharmacy.distance),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),

                      if (_currentPharmacy.phoneNumber.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 15, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              _currentPharmacy.phoneNumber,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Search within Pharmacy
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _loadPharmacyData(),
                  decoration: InputDecoration(
                    hintText: 'Search medicines in this pharmacy...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _loadPharmacyData();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Medicines',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_medicines.length} Items',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const LoadingIndicator(message: 'Loading inventory...')
                else if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                    ),
                  )
                else if (_medicines.isEmpty)
                  const EmptyStateWidget(
                    icon: Icons.medication_outlined,
                    title: 'No Medicines Found',
                    description: 'No medicines matched your search for this pharmacy.',
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _medicines.length,
                    itemBuilder: (context, index) {
                      final med = _medicines[index];
                      final cartQty = cart.getQuantity(med.id);

                      return MedicineCard(
                        medicine: med,
                        cartQuantity: cartQty,
                        onAdd: () {
                          final added = cart.addToCart(med);
                          if (!added) {
                            if (cart.pharmacyId != null && cart.pharmacyId != med.pharmacyId) {
                              _showReplaceDialog(med);
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
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReplaceDialog(MedicineModel newMed) {
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
