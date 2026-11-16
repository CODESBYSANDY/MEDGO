class PrescriptionItem {
  final String medicineName;
  final int quantity;
  final String? dosage;

  PrescriptionItem({
    required this.medicineName,
    required this.quantity,
    this.dosage,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      medicineName: json['medicine_name']?.toString() ?? json['name']?.toString() ?? '',
      quantity: (json['quantity'] != null) ? (json['quantity'] as num).toInt() : 1,
      dosage: json['dosage']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicine_name': medicineName,
      'quantity': quantity,
      'dosage': dosage,
    };
  }
}

class PrescriptionModel {
  final String id;
  final String patientId;
  final String doctorName;
  final String? details;
  final String? imageUrl;
  final String status; // 'PENDING', 'VERIFIED', 'REJECTED'
  final DateTime? createdAt;
  final List<PrescriptionItem> medicines;

  PrescriptionModel({
    required this.id,
    required this.patientId,
    required this.doctorName,
    this.details,
    this.imageUrl,
    required this.status,
    this.createdAt,
    this.medicines = const [],
  });

  bool get isVerified => status.toUpperCase() == 'VERIFIED';

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    List<PrescriptionItem> parsedItems = [];
    if (json['medicines'] is List) {
      parsedItems = (json['medicines'] as List)
          .map((item) => PrescriptionItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (json['medicine_name'] != null) {
      parsedItems.add(PrescriptionItem(
        medicineName: json['medicine_name'].toString(),
        quantity: (json['quantity'] != null) ? (json['quantity'] as num).toInt() : 1,
        dosage: json['dosage']?.toString(),
      ));
    }

    return PrescriptionModel(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? json['patientId']?.toString() ?? '',
      doctorName: json['doctor_name']?.toString() ?? json['doctorName']?.toString() ?? 'Dr. Specialist',
      details: json['details']?.toString() ?? json['prescription_details']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['image']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      medicines: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_name': doctorName,
      'details': details,
      'image_url': imageUrl,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'medicines': medicines.map((m) => m.toJson()).toList(),
    };
  }
}
