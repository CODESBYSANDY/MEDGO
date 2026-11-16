# MEDGO – Pharmacy Medicine Delivery Application (Flutter Frontend)

**Tagline:** *Your Medicines. Your Pharmacy. Delivered.*

MEDGO is a modern, professional Flutter frontend built for digital pharmacy medicine ordering and rapid delivery. It connects patients with licensed neighborhood pharmacies, allowing customers to search medicines, upload valid prescriptions, retrieve clinical hospital records via Patient ID, and track live order dispatch. Pharmacy owners have a dedicated management portal to verify prescriptions, pack medicines, and generate secure parcel QR codes for delivery couriers.

---

## 🚀 Key Highlights & Architectural Overview

- **Flutter & Material 3:** Built using Google Material 3 standards, responsive mobile-first UI, clean typography, subtle shadows, and a healthcare palette.
  - **Primary Colour:** `#14B8A6` (Teal / Turquoise)
  - **Secondary Colour:** `#0F766E` (Deep Teal)
  - **Background:** `#F8FAFC` (Slate 50)
  - **Text:** `#1E293B` (Slate 800)
- **Role Separation:** Completely independent authentication, state management, dashboard, and navigation flows for **Customers** and **Pharmacy Owners**.
- **REST API & JWT:** Integration using the standard `http` package, sending `Authorization: Bearer <token>` on authenticated routes.
- **Secure Storage:** Token and user role persistence using `flutter_secure_storage`.
- **Multipart Image Upload:** Real `multipart/form-data` prescription upload via `image_picker` (sends binary files, not Base64).
- **QR Code Dispatch & Verification:** Parcel QR code generation using `qr_flutter` and camera-based courier verification using `mobile_scanner`.
- **Live vs Demo Mode:** Directly talks to your live Node.js + Express backend. A completely separated mock service is available for isolated testing.

---

## 📁 Project Structure

```
frontend/lib/
├── config/
│   ├── api_config.dart          # Central API base URL, timeout & endpoint definitions
│   └── theme_config.dart        # Material 3 light theme & branding tokens
├── models/
│   ├── user_model.dart          # Customer and Pharmacy Owner models
│   ├── pharmacy_model.dart      # Pharmacy details, coordinates & operational hours
│   ├── medicine_model.dart      # Medicine catalog, pricing & stock status
│   ├── prescription_model.dart  # Clinical prescription & medicine items
│   └── order_model.dart         # Order lifecycle model
├── providers/
│   ├── auth_provider.dart       # Role-based JWT authentication state
│   └── cart_provider.dart       # Cart state & out-of-stock validation
├── screens/
│   ├── welcome/
│   │   └── welcome_screen.dart                 # Role selection portal
│   ├── auth/
│   │   ├── customer_login_screen.dart          # Customer login
│   │   ├── customer_register_screen.dart       # Customer registration
│   │   ├── pharmacy_login_screen.dart          # Pharmacy Owner login
│   │   ├── pharmacy_register_screen.dart       # Pharmacy Owner onboarding
│   │   └── forgot_password_screen.dart         # Password recovery
│   ├── customer/
│   │   ├── customer_main_nav.dart              # Bottom navigation host
│   │   ├── customer_home_screen.dart           # Dashboard, nearby pharmacies, quick actions
│   │   ├── pharmacy_details_screen.dart        # Individual pharmacy catalog & details
│   │   ├── medicine_search_screen.dart         # Search medicines with Rx/stock filters
│   │   ├── prescription_upload_screen.dart     # Camera / Gallery multipart prescription upload
│   │   ├── patient_prescriptions_screen.dart   # Query authorized records by Patient ID
│   │   ├── cart_screen.dart                    # Cart review, stock checks & checkout
│   │   ├── order_confirmation_screen.dart      # Instant order confirmation
│   │   ├── order_tracking_screen.dart          # 7-stage vertical order timeline
│   │   ├── customer_orders_screen.dart         # Customer past & active orders
│   │   └── customer_profile_screen.dart        # Profile & server configuration
│   ├── pharmacy_owner/
│   │   ├── owner_dashboard_screen.dart         # Owner stats, open/close toggle, incoming orders
│   │   ├── owner_orders_screen.dart            # Tabbed order management (New, Active, Done)
│   │   ├── owner_order_details_screen.dart     # Order review, prescription preview & actions
│   │   ├── owner_qr_screen.dart                # Parcel QR code generator
│   │   └── owner_profile_screen.dart           # Pharmacy account settings
│   └── delivery_simulator/
│       ├── delivery_simulator_screen.dart      # Courier prototype orders list
│       └── delivery_scan_screen.dart           # Mobile QR scanner & status update
├── services/
│   ├── api_service.dart          # Core HTTP client with Bearer auth & multipart upload
│   ├── auth_service.dart         # Login & registration API calls
│   ├── pharmacy_service.dart     # Nearby pharmacies & pharmacy details
│   ├── medicine_service.dart     # Medicine catalog query API
│   ├── prescription_service.dart # Multipart prescription upload & patient records
│   ├── order_service.dart        # Order creation, tracking & owner actions
│   ├── delivery_service.dart     # QR verification & courier delivery updates
│   ├── storage_service.dart      # FlutterSecureStorage persistence
│   └── mock_data_service.dart    # Separated mock dataset for demo mode
├── utils/
│   ├── constants.dart            # Palette, fixed order statuses & role constants
│   └── formatters.dart           # Currency and date/time formatting
└── widgets/
    ├── custom_button.dart        # Styled action buttons with loading spinners
    ├── custom_text_field.dart    # Form text fields with validation
    ├── demo_mode_banner.dart     # Runtime Server IP & Demo Mode configuration dialog
    ├── empty_state.dart          # Healthcare empty-state views
    ├── loading_indicator.dart    # Branded progress indicator
    ├── medicine_card.dart        # Medicine item card with stock controls
    ├── order_status_badge.dart   # Colored badge for order states
    ├── order_timeline.dart       # 7-stage vertical delivery timeline
    └── pharmacy_card.dart        # Pharmacy card with open/closed indicator
```

---

## ⚙️ Backend API Configuration

The base URL is centrally managed in [`lib/config/api_config.dart`](file:///c:/Users/Kowshikan%20A/MEDGO_CLEAN/frontend/lib/config/api_config.dart):

```dart
class ApiConfig {
  static String baseUrl = 'http://YOUR_SERVER_IP:5000/api/v1';
  static bool isDemoMode = false;
  ...
}
```

### Changing the Backend URL at Runtime
1. Tap the **Settings icon (⚙️)** on the top right of the Welcome Screen, Customer Home, or Pharmacy Dashboard.
2. Enter your machine's IP address (e.g., `http://192.168.1.50:5000/api/v1`) or select a preset chip:
   - `10.0.2.2 (Emulator)` – for standard Android Emulators.
   - `localhost:5000` – for Web or Desktop testing.
3. Toggle **Demo / Mock Mode** ON if you want to test the complete user journey without a live backend running.

---

## 📡 REST API Contract Compliance

All endpoints adhere to the required JSON response envelopes:
- **Success:** `{"success": true, "data": { ... }}`
- **Error:** `{"success": false, "message": "Error description"}`

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/auth/login` | Login for Customer and Pharmacy Owner |
| `POST` | `/auth/register` | Register new account (`CUSTOMER` or `PHARMACY_OWNER`) |
| `GET` | `/pharmacies?lat=..&lng=..&radius_km=5` | Nearby licensed pharmacies |
| `GET` | `/pharmacies/:id` | Individual pharmacy details |
| `GET` | `/medicines?search=..&pharmacy_id=..` | Medicine search with pharmacy filter |
| `POST` | `/prescriptions` | Multipart prescription upload (`patient_id`, `image`) |
| `GET` | `/patients/:patientId/prescriptions` | Authorized records for a clinical Patient ID |
| `PATCH`| `/prescriptions/:id/status` | Pharmacist prescription verification |
| `POST` | `/orders` | Order creation with selected medicines |
| `GET` | `/orders/:id` | Order details & tracking status |
| `GET` | `/orders` | Customer's order history |
| `GET` | `/owner/dashboard` | Pharmacy owner KPI statistics |
| `GET` | `/owner/orders` | Incoming & active orders for pharmacy owner |
| `PATCH`| `/orders/:id/status` | State transitions (`PHARMACY_ACCEPTED`, `MEDICINES_PACKED`, etc.) |
| `POST` | `/orders/:id/qr` | Generate parcel dispatch QR token |
| `POST` | `/delivery/verify` | Courier QR token verification |
| `PATCH`| `/delivery/:orderId/status` | Courier updates (`PICKED_UP`, `DELIVERED`) |

---

## 🔒 Exact Order Status Flow

Status strings strictly match the backend contract:
1. `ORDER_PLACED`
2. `PHARMACY_ACCEPTED`
3. `PRESCRIPTION_VERIFIED`
4. `MEDICINES_PACKED`
5. `READY_FOR_PICKUP`
6. `PICKED_UP`
7. `DELIVERED`
*(Terminal/Alternate: `REJECTED`, `CANCELLED`)*

---

## 🏃‍♂️ Running the Application

### 1. Prerequisites
- Flutter SDK 3.14.0+
- Android Studio / VS Code with Flutter extension
- An emulator or physical Android/iOS device

### 2. Run Flutter Analyze
```bash
cd frontend
flutter analyze
```

### 3. Launch the Application
```bash
flutter run
```
