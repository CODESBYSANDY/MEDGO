import 'package:flutter/material.dart';
import '../models/medicine_model.dart';

class CartItem {
  final MedicineModel medicine;
  int quantity;

  CartItem({
    required this.medicine,
    this.quantity = 1,
  });

  double get subtotal => medicine.price * quantity;
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  String? _pharmacyId;
  String? _pharmacyName;
  String? _prescriptionId;
  String? _prescriptionPatientId;

  Map<String, CartItem> get items => Map.unmodifiable(_items);
  List<CartItem> get itemList => _items.values.toList();
  String? get pharmacyId => _pharmacyId;
  String? get pharmacyName => _pharmacyName;
  String? get prescriptionId => _prescriptionId;
  String? get prescriptionPatientId => _prescriptionPatientId;

  int get totalItemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.values.fold(0.0, (sum, item) => sum + item.subtotal);

  bool get isEmpty => _items.isEmpty;

  bool get requiresPrescription => _items.values.any((item) => item.medicine.isPrescriptionRequired);

  /// Check whether any item in cart is out of stock or requested quantity exceeds available stock.
  bool get hasStockIssues {
    for (final item in _items.values) {
      if (item.medicine.stock <= 0 || item.quantity > item.medicine.stock) {
        return true;
      }
    }
    return false;
  }

  /// Stock validation error message, if any
  String? get stockValidationError {
    for (final item in _items.values) {
      if (item.medicine.stock <= 0) {
        return '${item.medicine.name} is currently out of stock.';
      }
      if (item.quantity > item.medicine.stock) {
        return 'Only ${item.medicine.stock} units of ${item.medicine.name} available in stock.';
      }
    }
    return null;
  }

  /// Whether checkout is permitted
  bool get canCheckout {
    if (isEmpty) return false;
    if (hasStockIssues) return false;
    if (requiresPrescription && (_prescriptionId == null || _prescriptionId!.isEmpty)) {
      return false;
    }
    return true;
  }

  /// Adds a medicine to the cart.
  /// If the cart already has medicines from a different pharmacy, returns false so UI can show a dialog.
  bool addToCart(MedicineModel medicine, {int quantity = 1, bool forceReplace = false}) {
    if (!medicine.inStock) return false;

    if (_pharmacyId != null && _pharmacyId != medicine.pharmacyId && !forceReplace) {
      return false; // Different pharmacy conflict
    }

    if (forceReplace || _pharmacyId != medicine.pharmacyId) {
      _items.clear();
      _pharmacyId = medicine.pharmacyId;
      _pharmacyName = medicine.pharmacyName;
    }

    if (_items.containsKey(medicine.id)) {
      final current = _items[medicine.id]!;
      final newQty = current.quantity + quantity;
      if (newQty <= medicine.stock) {
        current.quantity = newQty;
      } else {
        current.quantity = medicine.stock;
      }
    } else {
      _items[medicine.id] = CartItem(
        medicine: medicine,
        quantity: quantity.clamp(1, medicine.stock),
      );
    }

    notifyListeners();
    return true;
  }

  void updateQuantity(String medicineId, int quantity) {
    if (!_items.containsKey(medicineId)) return;

    if (quantity <= 0) {
      removeItem(medicineId);
      return;
    }

    final item = _items[medicineId]!;
    if (quantity <= item.medicine.stock) {
      item.quantity = quantity;
      notifyListeners();
    }
  }

  void removeItem(String medicineId) {
    _items.remove(medicineId);
    if (_items.isEmpty) {
      _pharmacyId = null;
      _pharmacyName = null;
      _prescriptionId = null;
      _prescriptionPatientId = null;
    }
    notifyListeners();
  }

  void attachPrescription(String prescriptionId, {String? patientId}) {
    _prescriptionId = prescriptionId;
    _prescriptionPatientId = patientId;
    notifyListeners();
  }

  void removePrescription() {
    _prescriptionId = null;
    _prescriptionPatientId = null;
    notifyListeners();
  }

  int getQuantity(String medicineId) {
    return _items[medicineId]?.quantity ?? 0;
  }

  List<Map<String, dynamic>> toApiPayloadItems() {
    return _items.values.map((item) => {
      'medicine_id': item.medicine.id,
      'quantity': item.quantity,
    }).toList();
  }

  void clearCart() {
    _items.clear();
    _pharmacyId = null;
    _pharmacyName = null;
    _prescriptionId = null;
    _prescriptionPatientId = null;
    notifyListeners();
  }
}
