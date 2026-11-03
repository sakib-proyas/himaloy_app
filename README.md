# Himaloy Agro Care - Mobile ERP & Field Force Automation (Android & iOS)

A cross-platform Flutter application built for **Himaloy Agro Care Inventory Management System**, integrating seamlessly with the Laravel 12 REST API.

---

## 📱 Features

- **Authentication & RBAC**:
  - Secure Bearer token authorization via Laravel Sanctum & Flutter Secure Storage.
  - Role-specific dynamic dashboard (Field Sales Officers vs Managers/Admins).
- **Field Order Booking**:
  - Automatically applies **Wholesale vs Retail Pricing** based on customer tier (`customer.is_wholesale`).
  - Interactive product catalog with real-time stock levels, pack sizes, and unit details.
  - Advance payment recording and dynamic due calculations.
- **Due Collection & Debt Settlement**:
  - Settle customer debts against unpaid sales invoices in **FIFO (First-In, First-Out)** order.
  - Real-time balance calculations with support for Cash, bKash, Nagad, and Bank payments.
- **Sales Targets & Performance Tracking**:
  - Monthly & Annual sales target progress indicators.
  - Real-time achievement versus quota tracking.
- **Customer CRM**:
  - Customer directory with territory and region filters.
  - On-field creation of new customer accounts.

---

## 🚀 Getting Started

### 1. Prerequisites
- **Flutter SDK**: `^3.5.0` or higher ([Download Flutter](https://docs.flutter.dev/get-started/install))
- **Android Studio** (for Android Emulator & SDK setup)
- **Xcode** (on macOS for iOS simulator & iPhone deployment)

### 2. Configure Backend API Endpoint
Open `lib/core/constants/api_constants.dart` and set `baseUrl`:
- **Android Emulator**: `http://10.0.2.2:8000/api/v1`
- **iOS Simulator**: `http://localhost:8000/api/v1`
- **Physical Device (via Wi-Fi)**: `http://<YOUR_LOCAL_IP>:8000/api/v1` (e.g. `http://192.168.1.50:8000/api/v1`)
- **Production Server**: `https://inventory.himaloyagrocare.com/api/v1`

### 3. Run the Backend API Server
In the parent directory (`C:\Users\Yasir IT\Desktop\projects\inventory`):
```bash
php artisan serve --host=0.0.0.0 --port=8000
```

### 4. Run the Flutter Mobile App
In this folder (`mobile_app`):
```bash
# Fetch dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

---

## 📂 Project Architecture

```
mobile_app/
├── lib/
│   ├── core/
│   │   ├── constants/       # API endpoints and route keys
│   │   ├── network/         # Dio client with Bearer token interceptor
│   │   ├── storage/         # Secure KeyStore & Keychain storage
│   │   └── theme/           # Agro-green brand color palette & styles
│   ├── features/
│   │   ├── auth/            # Login, session persistence, UserModel
│   │   ├── dashboard/       # Role-based KPI stats & navigation
│   │   ├── catalog/         # Product listing & stock badges
│   │   ├── customers/       # Customer directory, debt badges, add customer
│   │   ├── orders/          # Field order cart, pricing tier calculation
│   │   ├── collections/     # FIFO due invoices & collection recording
│   │   └── targets/         # Monthly and yearly target achievement rings
│   └── main.dart            # App entry point & auth restore
└── pubspec.yaml
```

