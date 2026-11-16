class MedicineModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final bool isPrescriptionRequired;
  final String pharmacyId;
  final String pharmacyName;
  final String? dosageForm; // e.g. "Tablet", "Syrup", "Capsule"
  final String? manufacturer;

  MedicineModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    required this.isPrescriptionRequired,
    required this.pharmacyId,
    required this.pharmacyName,
    this.dosageForm,
    this.manufacturer,
  });

  bool get inStock => stock > 0;

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: (json['price'] != null) ? (json['price'] as num).toDouble() : 0.0,
      stock: (json['stock'] != null) ? (json['stock'] as num).toInt() : 0,
      isPrescriptionRequired: json['prescription_required'] == true ||
          json['is_prescription_required'] == true ||
          json['requiresPrescription'] == true,
      pharmacyId: json['pharmacy_id']?.toString() ?? json['pharmacyId']?.toString() ?? '',
      pharmacyName: json['pharmacy_name']?.toString() ?? json['pharmacyName']?.toString() ?? 'Pharmacy',
      dosageForm: json['dosage_form']?.toString() ?? json['dosageForm']?.toString() ?? 'Tablet',
      manufacturer: json['manufacturer']?.toString() ?? 'Pharma Care',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'prescription_required': isPrescriptionRequired,
      'pharmacy_id': pharmacyId,
      'pharmacy_name': pharmacyName,
      'dosage_form': dosageForm,
      'manufacturer': manufacturer,
    };
  }
}
