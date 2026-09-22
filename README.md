# KDA e-Nivaran Mobile Applications (Flutter)

This repository contains the standalone Flutter source code for the KDA e-Nivaran mobile applications.

## 📱 Included Applications

### 1. Citizen Mobile App (`/citizen_app`)
- **Target**: Citizens of Kota / KDA
- **Features**: 
  - Complaint Registration with Camera / Gallery Proofs
  - Real-time GPS Location Detection
  - Live Tracking of Complaints (Registered, In Progress, Resolved)
  - Profile Management, History, and Instant Notifications
  - Bi-lingual Support (Hindi & English)

### 2. Department Mobile App (`/department_app`)
- **Target**: KDA Department Officers, Engineers, and Staff
- **Features**:
  - Secure Officer Login with Authentication
  - Dynamic KPI Counters (Total Complaints, Pending, Resolved, SLA Breached)
  - Action Management: Direct Resolution, Inspection, Re-assignment, Citizen Call
  - Web Portal Integration with Session Sync
  - Instant Refresh & Search

---

## 🚀 How to Run Locally

### Prerequisites
- Flutter SDK (3.24.0 or later recommended)
- Android Studio / Android SDK
- Java JDK 17

### Running Citizen App:
```bash
cd citizen_app
flutter pub get
flutter run
```

### Running Department App:
```bash
cd department_app
flutter pub get
flutter run
```

---

## 📦 Building Production APK
```bash
# For Citizen APK:
cd citizen_app
flutter build apk --release

# For Department APK:
cd department_app
flutter build apk --release
```
Output APKs will be generated under `build/app/outputs/flutter-apk/app-release.apk`.
