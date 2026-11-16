class OrderItemModel {
  final String medicineId;
  final String medicineName;
  final double price;
  final int quantity;
  final bool? isPrescriptionRequired;

  OrderItemModel({
    required this.medicineId,
    required this.medicineName,
    required this.price,
    required this.quantity,
    this.isPrescriptionRequired,
  });

  double get subtotal => price * quantity;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      medicineId: json['medicine_id']?.toString() ?? json['medicineId']?.toString() ?? '',
      medicineName: json['medicine_name']?.toString() ?? json['name']?.toString() ?? 'Medicine',
      price: (json['price'] != null) ? (json['price'] as num).toDouble() : 0.0,
      quantity: (json['quantity'] != null) ? (json['quantity'] as num).toInt() : 1,
      isPrescriptionRequired: json['prescription_required'] == true || json['is_prescription_required'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicine_id': medicineId,
      'quantity': quantity,
    };
  }

  Map<String, dynamic> toDetailedJson() {
    return {
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'price': price,
      'quantity': quantity,
      'prescription_required': isPrescriptionRequired,
    };
  }
}

class OrderModel {
  final String id;
  final String pharmacyId;
  final String pharmacyName;
  final String? customerId;
  final String customerName;
  final String? patientId;
  final String? prescriptionId;
  final String? prescriptionImageUrl;
  final String status;
  final List<OrderItemModel> items;
  final double totalAmount;
  final DateTime? createdAt;
  final String? qrToken;
  final String? deliveryAddress;
  final String? customerPhone;

  OrderModel({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    this.customerId,
    required this.customerName,
    this.patientId,
    this.prescriptionId,
    this.prescriptionImageUrl,
    required this.status,
    required this.items,
    required this.totalAmount,
    this.createdAt,
    this.qrToken,
    this.deliveryAddress,
    this.customerPhone,
  });

  bool get requiresPrescription =>
      prescriptionId != null && prescriptionId!.isNotEmpty ||
      items.any((item) => item.isPrescriptionRequired == true);

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<OrderItemModel> parsedItems = [];
    if (json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return OrderModel(
      id: json['id']?.toString() ?? json['order_id']?.toString() ?? '',
      pharmacyId: json['pharmacy_id']?.toString() ?? json['pharmacyId']?.toString() ?? '',
      pharmacyName: json['pharmacy_name']?.toString() ?? json['pharmacyName']?.toString() ?? 'Pharmacy',
      customerId: json['customer_id']?.toString() ?? json['customerId']?.toString(),
      customerName: json['customer_name']?.toString() ?? json['customerName']?.toString() ?? 'Customer',
      patientId: json['patient_id']?.toString() ?? json['patientId']?.toString(),
      prescriptionId: json['prescription_id']?.toString() ?? json['prescriptionId']?.toString(),
      prescriptionImageUrl: json['prescription_image']?.toString() ??
          json['prescription_image_url']?.toString() ??
          json['prescriptionImageUrl']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'ORDER_PLACED',
      items: parsedItems,
      totalAmount: (json['total_amount'] != null)
          ? (json['total_amount'] as num).toDouble()
          : (json['total'] != null)
              ? (json['total'] as num).toDouble()
              : 0.0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      qrToken: json['qr_token']?.toString() ?? json['qrToken']?.toString(),
      deliveryAddress: json['delivery_address']?.toString() ?? json['address']?.toString(),
      customerPhone: json['customer_phone']?.toString() ?? json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacy_id': pharmacyId,
      'pharmacy_name': pharmacyName,
      'customer_id': customerId,
      'customer_name': customerName,
      'patient_id': patientId,
      'prescription_id': prescriptionId,
      'prescription_image_url': prescriptionImageUrl,
      'status': status,
      'items': items.map((i) => i.toDetailedJson()).toList(),
      'total_amount': totalAmount,
      'created_at': createdAt?.toIso8601String(),
      'qr_token': qrToken,
      'delivery_address': deliveryAddress,
      'customer_phone': customerPhone,
    };
  }

  OrderModel copyWith({
    String? status,
    String? qrToken,
  }) {
    return OrderModel(
      id: id,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      customerId: customerId,
      customerName: customerName,
      patientId: patientId,
      prescriptionId: prescriptionId,
      prescriptionImageUrl: prescriptionImageUrl,
      status: status ?? this.status,
      items: items,
      totalAmount: totalAmount,
      createdAt: createdAt,
      qrToken: qrToken ?? this.qrToken,
      deliveryAddress: deliveryAddress,
      customerPhone: customerPhone,
    );
  }
}
