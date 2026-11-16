import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors as per specification
  static const Color primary = Color(0xFF14B8A6); // Teal / Turquoise
  static const Color primaryDark = Color(0xFF0F766E); // Deep Teal
  static const Color primaryLight = Color(0xFFCCFBF1); // Light Teal
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardAlt = Color(0xFFF1F5F9); // Light grey card
  static const Color border = Color(0xFFE2E8F0);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B); // Slate 800
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textLight = Color(0xFF94A3B8); // Slate 400

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFDBEAFE);
}

class OrderStatus {
  static const String orderPlaced = 'ORDER_PLACED';
  static const String pharmacyAccepted = 'PHARMACY_ACCEPTED';
  static const String prescriptionVerified = 'PRESCRIPTION_VERIFIED';
  static const String medicinesPacked = 'MEDICINES_PACKED';
  static const String readyForPickup = 'READY_FOR_PICKUP';
  static const String pickedUp = 'PICKED_UP';
  static const String delivered = 'DELIVERED';
  static const String rejected = 'REJECTED';
  static const String cancelled = 'CANCELLED';

  static const List<String> normalFlow = [
    orderPlaced,
    pharmacyAccepted,
    prescriptionVerified,
    medicinesPacked,
    readyForPickup,
    pickedUp,
    delivered,
  ];

  static String getDisplayName(String status) {
    switch (status) {
      case orderPlaced:
        return 'Order Placed';
      case pharmacyAccepted:
        return 'Pharmacy Accepted';
      case prescriptionVerified:
        return 'Prescription Verified';
      case medicinesPacked:
        return 'Medicines Packed';
      case readyForPickup:
        return 'Ready for Pickup';
      case pickedUp:
        return 'Picked Up';
      case delivered:
        return 'Delivered';
      case rejected:
        return 'Rejected';
      case cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case orderPlaced:
        return AppColors.info;
      case pharmacyAccepted:
      case prescriptionVerified:
        return AppColors.primary;
      case medicinesPacked:
      case readyForPickup:
        return AppColors.warning;
      case pickedUp:
        return const Color(0xFF8B5CF6); // Purple
      case delivered:
        return AppColors.success;
      case rejected:
      case cancelled:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  static Color getStatusBgColor(String status) {
    switch (status) {
      case orderPlaced:
        return AppColors.infoBg;
      case pharmacyAccepted:
      case prescriptionVerified:
        return AppColors.primaryLight;
      case medicinesPacked:
      case readyForPickup:
        return AppColors.warningBg;
      case pickedUp:
        return const Color(0xFFEDE9FE);
      case delivered:
        return AppColors.successBg;
      case rejected:
      case cancelled:
        return AppColors.errorBg;
      default:
        return AppColors.cardAlt;
    }
  }
}

class UserRole {
  static const String customer = 'CUSTOMER';
  static const String pharmacyOwner = 'PHARMACY_OWNER';
}
