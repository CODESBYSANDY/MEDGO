class ApiConfig {
  /// Base URL of the MEDGO Node.js backend.
  /// Change this string to point directly to your backend server IP/domain.
  /// Example: http://192.168.1.100:5000/api/v1 or http://10.0.2.2:5000/api/v1 (Android emulator)
  static String baseUrl = 'http://YOUR_SERVER_IP:5000/api/v1';

  /// Toggle for the clearly separated Mock/Demo mode.
  /// When false: strictly connects to the live Node.js REST API with zero fallback.
  /// When true: uses the separated MockDataService for prototyping without a running backend.
  static bool isDemoMode = false;

  // Request timeout duration
  static const Duration timeoutDuration = Duration(seconds: 15);

  // Exact API Endpoints as per specification
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  static const String pharmacies = '/pharmacies';
  static String pharmacyDetails(String id) => '/pharmacies/$id';

  static const String medicines = '/medicines';

  static const String prescriptions = '/prescriptions';
  static String patientPrescriptions(String patientId) => '/patients/$patientId/prescriptions';
  static String updatePrescriptionStatus(String id) => '/prescriptions/$id/status';

  static const String orders = '/orders';
  static String orderDetails(String id) => '/orders/$id';
  static String updateOrderStatus(String id) => '/orders/$id/status';
  static String orderQr(String id) => '/orders/$id/qr';

  static const String ownerDashboard = '/owner/dashboard';
  static const String ownerOrders = '/owner/orders';

  static const String deliveryVerify = '/delivery/verify';
  static String deliveryStatus(String orderId) => '/delivery/$orderId/status';
}
