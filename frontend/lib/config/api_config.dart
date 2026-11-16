class ApiConfig {
  /// Production Base URL of the deployed MEDGO Node.js backend.
  static String baseUrl = 'https://medgo-8pig.onrender.com/api/v1';

  /// Toggle for separated Mock/Demo mode.
  /// Default: false (strictly connects to live production Node.js backend).
  static bool isDemoMode = false;

  /// Timeouts configured as per specifications
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 45);

  /// Demo delivery key accepted by backend delivery partner middleware
  static const String deliveryApiKey = 'medgo-delivery-demo-key-2026';

  // Exact API Endpoints implemented by backend
  static const String health = '/health';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  static const String pharmacies = '/pharmacies';
  static String pharmacyDetails(String id) => '/pharmacies/$id';

  static const String medicines = '/medicines';

  static const String prescriptions = '/prescriptions';
  static String prescriptionDetails(String id) => '/prescriptions/$id';
  static String updatePrescriptionStatus(String id) => '/prescriptions/$id/status';
  static String patientPrescriptions(String patientId) => '/patients/$patientId/prescriptions';

  static const String orders = '/orders';
  static String orderDetails(String id) => '/orders/$id';
  static String updateOrderStatus(String id) => '/orders/$id/status';
  static String orderQr(String id) => '/orders/$id/qr';

  static const String ownerDashboard = '/owner/dashboard';
  static const String ownerOrders = '/owner/orders';
  static const String ownerAvailability = '/owner/pharmacy/availability';

  static const String deliveryVerify = '/delivery/verify';
  static String deliveryStatus(String orderId) => '/delivery/$orderId/status';
}
