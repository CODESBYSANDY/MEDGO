class PharmacyModel {
  final String id;
  final String name;
  final String ownerName;
  final double distance; // in km
  final String address;
  final bool isOpen;
  final String openingTime;
  final String closingTime;
  final String phoneNumber;
  final double rating;
  final double? latitude;
  final double? longitude;

  PharmacyModel({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.distance,
    required this.address,
    required this.isOpen,
    required this.openingTime,
    required this.closingTime,
    required this.phoneNumber,
    this.rating = 4.8,
    this.latitude,
    this.longitude,
  });

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['pharmacy_name']?.toString() ?? '',
      ownerName: json['owner_name']?.toString() ?? json['ownerName']?.toString() ?? 'Pharmacy Owner',
      distance: (json['distance'] != null) ? (json['distance'] as num).toDouble() : 1.2,
      address: json['address']?.toString() ?? '',
      isOpen: json['is_open'] == true || json['isOpen'] == true || json['status'] == 'OPEN',
      openingTime: json['opening_time']?.toString() ?? json['openingTime']?.toString() ?? '08:00 AM',
      closingTime: json['closing_time']?.toString() ?? json['closingTime']?.toString() ?? '10:00 PM',
      phoneNumber: json['phone']?.toString() ?? json['phoneNumber']?.toString() ?? json['phone_number']?.toString() ?? '',
      rating: (json['rating'] != null) ? (json['rating'] as num).toDouble() : 4.8,
      latitude: (json['latitude'] != null) ? (json['latitude'] as num).toDouble() : null,
      longitude: (json['longitude'] != null) ? (json['longitude'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_name': ownerName,
      'distance': distance,
      'address': address,
      'is_open': isOpen,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'phone': phoneNumber,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
