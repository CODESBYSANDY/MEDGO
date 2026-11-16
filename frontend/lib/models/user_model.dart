class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'CUSTOMER' or 'PHARMACY_OWNER'
  final String? pharmacyName;
  final String? address;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.pharmacyName,
    this.address,
  });

  bool get isCustomer => role == 'CUSTOMER';
  bool get isPharmacyOwner => role == 'PHARMACY_OWNER';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString().toUpperCase() ?? 'CUSTOMER',
      pharmacyName: json['pharmacy_name']?.toString() ?? json['pharmacyName']?.toString(),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'pharmacy_name': pharmacyName,
      'address': address,
    };
  }
}
