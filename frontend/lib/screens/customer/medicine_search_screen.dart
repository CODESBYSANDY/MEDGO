import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/medicine_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/medicine_service.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/medicine_card.dart';
import 'cart_screen.dart';

class MedicineSearchScreen extends StatefulWidget {
  final String? initialSearch;
  final String? pharmacyId;

  const MedicineSearchScreen({super.key, this.initialSearch, this.pharmacyId});

  @override
  State<MedicineSearchScreen> createState() => _MedicineSearchScreenState();
}

class _MedicineSearchScreenState extends State<MedicineSearchScreen> {
  final MedicineService _medicineService = MedicineService();
  final TextEditingController _searchController = TextEditingController();

  List<MedicineModel> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _filterRxOnly = false;
  bool _filterInStockOnly = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) {
      _searchController.text = widget.initialSearch!;
    }
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _medicineService.searchMedicines(
        search: _searchController.text.trim(),
        pharmacyId: widget.pharmacyId,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
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

  List<MedicineModel> get _filteredResults {
    return _searchResults.where((med) {
      if (_filterRxOnly && !med.isPrescriptionRequired) return false;
      if (_filterInStockOnly && !med.inStock) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final filtered = _filteredResults;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search Medicines'),
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
        child: Column(
          children: [
            // Search Input Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    autofocus: widget.initialSearch == null,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _performSearch(),
                    decoration: InputDecoration(
                      hintText: 'Search paracetamol, antibiotics, syrup...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch();
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('In Stock Only'),
                          selected: _filterInStockOnly,
                          selectedColor: AppColors.primaryLight,
                          checkmarkColor: AppColors.primaryDark,
                          onSelected: (val) {
                            setState(() => _filterInStockOnly = val);
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Prescription Required'),
                          selected: _filterRxOnly,
                          selectedColor: const Color(0xFFFEE2E2),
                          checkmarkColor: const Color(0xFFDC2626),
                          onSelected: (val) {
                            setState(() => _filterRxOnly = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Results List
            Expanded(
              child: _isLoading
                  ? const LoadingIndicator(message: 'Searching medicines...')
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
                                  onPressed: _performSearch,
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filtered.isEmpty
                          ? EmptyStateWidget(
                              icon: Icons.search_off_rounded,
                              title: 'No Medicines Found',
                              description: 'We couldn\'t find any medicines matching "${_searchController.text.trim()}".',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final med = filtered[index];
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
            ),
          ],
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
          'Your cart contains items from ${context.read<CartProvider>().pharmacyName}. Would you like to clear it and add from ${newMed.pharmacyName} instead?',
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
