import 'dart:math';
import '../models/pharmacy_model.dart';
import '../models/medicine_model.dart';
import '../models/prescription_model.dart';
import '../models/order_model.dart';
import '../utils/constants.dart';

/// Separated Mock Data Store used solely when ApiConfig.isDemoMode is enabled.
class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal() {
    _initMockData();
  }

  final List<PharmacyModel> _pharmacies = [];
  final List<MedicineModel> _medicines = [];
  final List<PrescriptionModel> _prescriptions = [];
  final List<OrderModel> _orders = [];

  void _initMockData() {
    _pharmacies.clear();
    _pharmacies.addAll([
      PharmacyModel(
        id: 'pharmacy-001',
        name: 'Apollo Pharmacy & Wellness',
        ownerName: 'Dr. Rajesh Sundaram',
        distance: 0.8,
        address: '142 Bypass Road, Near Apollo Hospital, Madurai',
        isOpen: true,
        openingTime: '08:00 AM',
        closingTime: '11:00 PM',
        phoneNumber: '+91 98765 43210',
        rating: 4.9,
      ),
      PharmacyModel(
        id: 'pharmacy-002',
        name: 'MedPlus Health Care',
        ownerName: 'K. Venkatesh',
        distance: 1.5,
        address: '78 Cross Cut Road, Gandhipuram, Madurai',
        isOpen: true,
        openingTime: '08:30 AM',
        closingTime: '10:30 PM',
        phoneNumber: '+91 98421 11223',
        rating: 4.7,
      ),
      PharmacyModel(
        id: 'pharmacy-003',
        name: 'Sanjeevani Medico & Surgical',
        ownerName: 'M. Senthil Nathan',
        distance: 2.3,
        address: '25 West Perumal Maistry Street, Madurai',
        isOpen: false,
        openingTime: '09:00 AM',
        closingTime: '09:30 PM',
        phoneNumber: '+91 94433 88990',
        rating: 4.6,
      ),
      PharmacyModel(
        id: 'pharmacy-004',
        name: 'Care & Cure Express Chemist',
        ownerName: 'Mrs. Radha Priya',
        distance: 3.1,
        address: '12 Alagarkoil Road, Tallakulam, Madurai',
        isOpen: true,
        openingTime: '07:30 AM',
        closingTime: '11:59 PM',
        phoneNumber: '+91 98940 55667',
        rating: 4.8,
      ),
    ]);

    _medicines.clear();
    _medicines.addAll([
      MedicineModel(
        id: 'med-001',
        name: 'Paracetamol 650mg (Dolo)',
        description: 'Antipyretic and analgesic for relief of fever and mild-to-moderate pain.',
        price: 32.50,
        stock: 45,
        isPrescriptionRequired: false,
        pharmacyId: 'pharmacy-001',
        pharmacyName: 'Apollo Pharmacy & Wellness',
        dosageForm: 'Tablet (Strip of 15)',
        manufacturer: 'Micro Labs Ltd',
      ),
      MedicineModel(
        id: 'med-002',
        name: 'Amoxicillin 500mg',
        description: 'Broad-spectrum antibiotic used to treat bacterial infections.',
        price: 110.00,
        stock: 20,
        isPrescriptionRequired: true,
        pharmacyId: 'pharmacy-001',
        pharmacyName: 'Apollo Pharmacy & Wellness',
        dosageForm: 'Capsule (Strip of 10)',
        manufacturer: 'Cipla Health',
      ),
      MedicineModel(
        id: 'med-003',
        name: 'Azithromycin 500mg',
        description: 'Macrolide antibiotic for respiratory tract infections and ear infections.',
        price: 145.00,
        stock: 15,
        isPrescriptionRequired: true,
        pharmacyId: 'pharmacy-001',
        pharmacyName: 'Apollo Pharmacy & Wellness',
        dosageForm: 'Tablet (Strip of 5)',
        manufacturer: 'Sun Pharmaceuticals',
      ),
      MedicineModel(
        id: 'med-004',
        name: 'Cetirizine 10mg (Cetzine)',
        description: 'Antihistamine providing 24h relief from allergies and runny nose.',
        price: 45.00,
        stock: 60,
        isPrescriptionRequired: false,
        pharmacyId: 'pharmacy-001',
        pharmacyName: 'Apollo Pharmacy & Wellness',
        dosageForm: 'Tablet (Strip of 10)',
        manufacturer: 'Dr. Reddy Laboratories',
      ),
      MedicineModel(
        id: 'med-005',
        name: 'Pantoprazole 40mg (Pan 40)',
        description: 'Proton-pump inhibitor for acid reflux, GERD, and gastric protection.',
        price: 98.00,
        stock: 35,
        isPrescriptionRequired: false,
        pharmacyId: 'pharmacy-001',
        pharmacyName: 'Apollo Pharmacy & Wellness',
        dosageForm: 'Tablet (Strip of 15)',
        manufacturer: 'Alkem Laboratories',
      ),
      MedicineModel(
        id: 'med-006',
        name: 'Metformin 500mg (Glycomet)',
        description: 'Oral antihyperglycemic agent for Type 2 diabetes management.',
        price: 52.00,
        stock: 50,
        isPrescriptionRequired: true,
        pharmacyId: 'pharmacy-001',
        pharmacyName: 'Apollo Pharmacy & Wellness',
        dosageForm: 'Tablet (Strip of 20)',
        manufacturer: 'USV Pvt Ltd',
      ),
      MedicineModel(
        id: 'med-007',
        name: 'ORS Electrolyte Powder (Electral)',
        description: 'Oral rehydration salts for electrolyte replenishment during dehydration.',
        price: 22.00,
        stock: 80,
        isPrescriptionRequired: false,
        pharmacyId: 'pharmacy-001',
        pharmacyName: 'Apollo Pharmacy & Wellness',
        dosageForm: 'Sachet (21.8g)',
        manufacturer: 'FDC Limited',
      ),
      MedicineModel(
        id: 'med-008',
        name: 'Telmisartan 40mg (Telma 40)',
        description: 'Angiotensin receptor blocker for essential hypertension control.',
        price: 135.00,
        stock: 25,
        isPrescriptionRequired: true,
        pharmacyId: 'pharmacy-002',
        pharmacyName: 'MedPlus Health Care',
        dosageForm: 'Tablet (Strip of 15)',
        manufacturer: 'Glenmark Pharma',
      ),
      MedicineModel(
        id: 'med-009',
        name: 'Vitamin C + Zinc Chewable (Limcee)',
        description: 'Immunity booster nutritional supplement with Ascorbic Acid.',
        price: 38.00,
        stock: 90,
        isPrescriptionRequired: false,
        pharmacyId: 'pharmacy-002',
        pharmacyName: 'MedPlus Health Care',
        dosageForm: 'Chewable (Strip of 15)',
        manufacturer: 'Abbott Healthcare',
      ),
      MedicineModel(
        id: 'med-010',
        name: 'Out of Stock Test Medicine',
        description: 'Demonstrates strict stock validation preventing checkout.',
        price: 75.00,
        stock: 0,
        isPrescriptionRequired: false,
        pharmacyId: 'pharmacy-001',
        pharmacyName: 'Apollo Pharmacy & Wellness',
        dosageForm: 'Tablet',
        manufacturer: 'Test Lab',
      ),
    ]);

    _prescriptions.clear();
    _prescriptions.addAll([
      PrescriptionModel(
        id: 'prescription-001',
        patientId: 'PAT-8801',
        doctorName: 'Dr. Anita Ramachandran, MD (General Medicine)',
        details: 'Rx for acute bacterial pharyngitis and fever. Take after meals.',
        status: 'VERIFIED',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        medicines: [
          PrescriptionItem(medicineName: 'Amoxicillin 500mg', quantity: 2, dosage: '1-0-1 for 5 days'),
          PrescriptionItem(medicineName: 'Paracetamol 650mg', quantity: 1, dosage: 'Sos fever > 100F'),
        ],
      ),
      PrescriptionModel(
        id: 'prescription-002',
        patientId: 'PAT-8801',
        doctorName: 'Dr. S. Karthikeyan, DM (Cardiology)',
        details: 'Monthly cardiac maintenance regimen. Blood pressure monitoring required.',
        status: 'VERIFIED',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        medicines: [
          PrescriptionItem(medicineName: 'Telmisartan 40mg', quantity: 2, dosage: '1-0-0 morning'),
        ],
      ),
      PrescriptionModel(
        id: 'prescription-003',
        patientId: 'PAT-9022',
        doctorName: 'Dr. Meena Swaminathan, MD (Endocrinology)',
        details: 'Type 2 Diabetes ongoing treatment.',
        status: 'PENDING',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        medicines: [
          PrescriptionItem(medicineName: 'Metformin 500mg', quantity: 3, dosage: '1-0-1 with food'),
        ],
      ),
    ]);

    _orders.clear();
    _orders.addAll([
      OrderModel(
        id: 'ORD-7701',
        pharmacyId: 'pharmacy-001',
        pharmacyName: 'Apollo Pharmacy & Wellness',
        customerId: 'user-001',
        customerName: 'Arun Kumar',
        patientId: 'PAT-8801',
        prescriptionId: 'prescription-001',
        status: OrderStatus.pharmacyAccepted,
        items: [
          OrderItemModel(
            medicineId: 'med-002',
            medicineName: 'Amoxicillin 500mg',
            price: 110.00,
            quantity: 2,
            isPrescriptionRequired: true,
          ),
          OrderItemModel(
            medicineId: 'med-001',
            medicineName: 'Paracetamol 650mg (Dolo)',
            price: 32.50,
            quantity: 1,
            isPrescriptionRequired: false,
          ),
        ],
        totalAmount: 252.50,
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        deliveryAddress: 'Flat 402, Green Valley Apts, Bypass Road, Madurai',
        customerPhone: '+91 98765 43210',
      ),
      OrderModel(
        id: 'ORD-7702',
        pharmacyId: 'pharmacy-001',
        pharmacyName: 'Apollo Pharmacy & Wellness',
        customerId: 'user-002',
        customerName: 'Priya Dharshini',
        patientId: null,
        prescriptionId: null,
        status: OrderStatus.orderPlaced,
        items: [
          OrderItemModel(
            medicineId: 'med-004',
            medicineName: 'Cetirizine 10mg (Cetzine)',
            price: 45.00,
            quantity: 2,
            isPrescriptionRequired: false,
          ),
          OrderItemModel(
            medicineId: 'med-007',
            medicineName: 'ORS Electrolyte Powder (Electral)',
            price: 22.00,
            quantity: 4,
            isPrescriptionRequired: false,
          ),
        ],
        totalAmount: 178.00,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        deliveryAddress: '15 Anna Nagar 2nd Street, Madurai',
        customerPhone: '+91 94421 99887',
      ),
      OrderModel(
        id: 'ORD-7703',
        pharmacyId: 'pharmacy-001',
        pharmacyName: 'Apollo Pharmacy & Wellness',
        customerId: 'user-003',
        customerName: 'Karthik Subramanian',
        patientId: 'PAT-8801',
        prescriptionId: 'prescription-001',
        status: OrderStatus.readyForPickup,
        qrToken: 'MEDGO_PARCEL_QR_7703_SECURE_TOKEN',
        items: [
          OrderItemModel(
            medicineId: 'med-003',
            medicineName: 'Azithromycin 500mg',
            price: 145.00,
            quantity: 1,
            isPrescriptionRequired: true,
          ),
        ],
        totalAmount: 145.00,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        deliveryAddress: '88 KK Nagar East Main Road, Madurai',
        customerPhone: '+91 97890 12345',
      ),
      OrderModel(
        id: 'ORD-7690',
        pharmacyId: 'pharmacy-001',
        pharmacyName: 'Apollo Pharmacy & Wellness',
        customerId: 'user-001',
        customerName: 'Arun Kumar',
        patientId: null,
        prescriptionId: null,
        status: OrderStatus.delivered,
        items: [
          OrderItemModel(
            medicineId: 'med-005',
            medicineName: 'Pantoprazole 40mg (Pan 40)',
            price: 98.00,
            quantity: 1,
            isPrescriptionRequired: false,
          ),
        ],
        totalAmount: 98.00,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        deliveryAddress: 'Flat 402, Green Valley Apts, Madurai',
        customerPhone: '+91 98765 43210',
      ),
    ]);
  }

  // --- Auth Simulation ---
  Future<Map<String, dynamic>> mockLogin(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final lower = email.toLowerCase().trim();
    if (lower.contains('apollo') || lower.contains('owner') || lower.contains('pharmacy')) {
      return {
        'token': 'mock_jwt_owner_${DateTime.now().millisecondsSinceEpoch}',
        'user': {
          'id': 'owner-001',
          'name': 'Dr. Rajesh Sundaram',
          'email': email,
          'phone': '9876543210',
          'role': UserRole.pharmacyOwner,
          'pharmacy_name': 'Apollo Pharmacy & Wellness',
          'address': '142 Bypass Road, Madurai',
        }
      };
    } else {
      return {
        'token': 'mock_jwt_customer_${DateTime.now().millisecondsSinceEpoch}',
        'user': {
          'id': 'user-001',
          'name': 'Arun Kumar',
          'email': email,
          'phone': '9876543210',
          'role': UserRole.customer,
        }
      };
    }
  }

  Future<Map<String, dynamic>> mockRegister(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final role = data['role']?.toString().toUpperCase() ?? UserRole.customer;
    return {
      'token': 'mock_jwt_reg_${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        'id': 'user_${Random().nextInt(9999)}',
        'name': data['name'] ?? 'User',
        'email': data['email'] ?? 'user@medgo.com',
        'phone': data['phone'] ?? '9876543210',
        'role': role,
        'pharmacy_name': data['pharmacy_name'],
        'address': data['address'],
      }
    };
  }

  // --- Pharmacies ---
  Future<List<PharmacyModel>> mockGetPharmacies() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_pharmacies);
  }

  Future<PharmacyModel> mockGetPharmacyById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _pharmacies.firstWhere(
      (p) => p.id == id,
      orElse: () => _pharmacies.first,
    );
  }

  // --- Medicines ---
  Future<List<MedicineModel>> mockSearchMedicines({String? query, String? pharmacyId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var results = _medicines.asEnumerable();
    if (pharmacyId != null && pharmacyId.isNotEmpty) {
      results = results.where((m) => m.pharmacyId == pharmacyId);
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      results = results.where((m) => m.name.toLowerCase().contains(q) || (m.description?.toLowerCase().contains(q) ?? false));
    }
    return results.toList();
  }

  // --- Prescriptions ---
  Future<Map<String, dynamic>> mockUploadPrescription(String patientId, String filePath) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final newRx = PrescriptionModel(
      id: 'prescription-${Random().nextInt(9000) + 1000}',
      patientId: patientId,
      doctorName: 'Dr. Registered Consultant',
      details: 'Patient submitted digital upload prescription.',
      imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500&q=80',
      status: 'PENDING',
      createdAt: DateTime.now(),
      medicines: [
        PrescriptionItem(medicineName: 'Prescribed Medicine', quantity: 1),
      ],
    );
    _prescriptions.insert(0, newRx);
    return newRx.toJson();
  }

  Future<List<PrescriptionModel>> mockGetPatientPrescriptions(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _prescriptions.where((p) => p.patientId.toUpperCase() == patientId.toUpperCase()).toList();
  }

  // --- Orders ---
  Future<OrderModel> mockCreateOrder(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final pharmacyId = data['pharmacy_id']?.toString() ?? 'pharmacy-001';
    final rxId = data['prescription_id']?.toString();
    final itemsList = (data['items'] as List? ?? []);

    final orderItems = <OrderItemModel>[];
    double total = 0.0;
    for (final item in itemsList) {
      final medId = item['medicine_id']?.toString() ?? '';
      final qty = (item['quantity'] as num? ?? 1).toInt();
      final med = _medicines.firstWhere((m) => m.id == medId, orElse: () => _medicines.first);
      final itemModel = OrderItemModel(
        medicineId: med.id,
        medicineName: med.name,
        price: med.price,
        quantity: qty,
        isPrescriptionRequired: med.isPrescriptionRequired,
      );
      orderItems.add(itemModel);
      total += itemModel.subtotal;
    }

    final newOrder = OrderModel(
      id: 'ORD-${Random().nextInt(9000) + 1000}',
      pharmacyId: pharmacyId,
      pharmacyName: 'Apollo Pharmacy & Wellness',
      customerId: 'user-001',
      customerName: 'Arun Kumar',
      patientId: 'PAT-8801',
      prescriptionId: rxId,
      prescriptionImageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500&q=80',
      status: OrderStatus.orderPlaced,
      items: orderItems,
      totalAmount: total > 0 ? total : 252.50,
      createdAt: DateTime.now(),
      deliveryAddress: 'Flat 402, Green Valley Apts, Madurai',
      customerPhone: '+91 98765 43210',
    );
    _orders.insert(0, newOrder);
    return newOrder;
  }

  Future<OrderModel> mockGetOrderById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _orders.firstWhere(
      (o) => o.id == id,
      orElse: () => _orders.first,
    );
  }

  Future<List<OrderModel>> mockGetCustomerOrders() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_orders);
  }

  // --- Owner Operations ---
  Future<Map<String, dynamic>> mockGetOwnerDashboard() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newOrdersCount = _orders.where((o) => o.status == OrderStatus.orderPlaced).length;
    final acceptedCount = _orders.where((o) => o.status == OrderStatus.pharmacyAccepted || o.status == OrderStatus.prescriptionVerified).length;
    final preparingCount = _orders.where((o) => o.status == OrderStatus.medicinesPacked || o.status == OrderStatus.readyForPickup).length;
    final completedCount = _orders.where((o) => o.status == OrderStatus.delivered).length;

    return {
      'new_orders': newOrdersCount,
      'accepted_orders': acceptedCount,
      'preparing_orders': preparingCount,
      'completed_orders': completedCount,
    };
  }

  Future<List<OrderModel>> mockGetOwnerOrders() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_orders);
  }

  Future<void> mockUpdateOrderStatus(String orderId, String newStatus) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: newStatus);
    }
  }

  Future<void> mockUpdatePrescriptionStatus(String rxId, String status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _prescriptions.indexWhere((p) => p.id == rxId);
    if (index != -1) {
      _prescriptions[index] = PrescriptionModel(
        id: _prescriptions[index].id,
        patientId: _prescriptions[index].patientId,
        doctorName: _prescriptions[index].doctorName,
        details: _prescriptions[index].details,
        imageUrl: _prescriptions[index].imageUrl,
        status: status,
        createdAt: _prescriptions[index].createdAt,
        medicines: _prescriptions[index].medicines,
      );
    }
  }

  Future<Map<String, dynamic>> mockGenerateQr(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final token = 'MEDGO_PARCEL_QR_${orderId}_${Random().nextInt(999999)}';
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        status: OrderStatus.readyForPickup,
        qrToken: token,
      );
    }
    return {
      'qr_token': token,
      'order_id': orderId,
      'status': OrderStatus.readyForPickup,
    };
  }

  // --- Delivery Simulator ---
  Future<Map<String, dynamic>> mockVerifyDelivery(String qrToken) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final order = _orders.firstWhere(
      (o) => o.qrToken == qrToken || qrToken.contains(o.id),
      orElse: () => _orders.firstWhere(
        (o) => o.status == OrderStatus.readyForPickup,
        orElse: () => _orders.first,
      ),
    );

    return {
      'valid': true,
      'order_id': order.id,
      'pharmacy_name': order.pharmacyName,
      'customer_name': order.customerName,
      'delivery_address': order.deliveryAddress ?? 'Madurai',
      'status': order.status,
    };
  }

  Future<void> mockUpdateDeliveryStatus(String orderId, String status) async {
    await mockUpdateOrderStatus(orderId, status);
  }
}

extension IterableExtensions<E> on Iterable<E> {
  Iterable<E> asEnumerable() => this;
}
