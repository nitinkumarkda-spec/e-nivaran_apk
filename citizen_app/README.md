# KDA e-Nivaran - Citizen Mobile App (Flutter)

Official Citizen-Only Mobile Application for **Kota Development Authority (KDA) - eNivaran Public Grievance Redressal System**.

---

## 🌟 Features Included

- **Dedicated to Citizens Only**: Zero departmental sections, zero officer logins.
- **No Generic Home Page**: The app flows directly from Splash ➔ Intro ➔ Citizen Login ➔ Citizen Dashboard.
- **Animated Splash Screen**: Official KDA logo with subtle branding animation.
- **Onboarding / Intro Screens**: 3 interactive carousel slides explaining photo geotagging, live milestone tracking, and time-bound SLA resolution.
- **Citizen Login / OTP**: 10-digit mobile number authentication with OTP verification & Guest mode.
- **5 Bottom Navigation Tabs**:
  1. **Dashboard**: Citizen Welcome Hero, Quick Register Action, and 6 Status Overview cards (Total, Pending, Assigned, Resolved, Rejected, Reopened).
  2. **Register Complaint**: Exact Web App form with Category, Sub Type, Garden/Park selector, GPS Auto-Detect with Kota/Bundi territory validation, and Live Camera capture.
  3. **My Complaints**: Search bar, status filter chips (All, Pending, In Progress, Resolved), and grievance cards.
  4. **Track Timeline**: Detailed milestone stepper (Submitted ➔ Moderator Verified ➔ Field Engineer Assigned ➔ Contractor In Progress ➔ Resolved).
  5. **Alerts**: Official public announcements and grievance updates from KDA.
  6. **Profile**: Citizen information, English / हिन्दी language switch, configurable Backend Host URL, Helpline shortcut, and Logout.

---

## 📁 Project Structure

```
enivaran_flutter/
├── assets/
│   └── images/
│       └── logo2.png
├── lib/
│   ├── config/
│   │   └── api_config.dart
│   ├── models/
│   │   └── complaint.dart
│   ├── screens/
│   │   ├── splash_screen.dart              # Animated Splash with KDA Logo
│   │   ├── intro_screen.dart               # 3 Onboarding Carousel Slides
│   │   ├── citizen_login_screen.dart       # Mobile OTP & Guest Login
│   │   ├── main_citizen_nav_screen.dart    # 5 Tab Bottom Navigation
│   │   ├── citizen_dashboard_screen.dart   # Dashboard & 6 Status Cards
│   │   ├── register_complaint_screen.dart  # Form with GPS & Live Camera
│   │   ├── complaints_list_screen.dart     # Search & Filterable List
│   │   ├── complaint_track_screen.dart     # Timeline Tracking Stepper
│   │   ├── notifications_screen.dart       # KDA Alerts
│   │   └── profile_screen.dart             # Citizen Profile & Language
│   └── main.dart                           # Entry point with Inter & Theme
└── pubspec.yaml
```

---

## 🚀 How to Run

1. Open this folder `enivaran_flutter` in **VS Code** or **Android Studio**.
2. Run `flutter pub get` in the terminal to fetch packages.
3. Connect your Android or iOS device.
4. Press `F5` or run:
   ```bash
   flutter run
   ```
5. To build release APK:
   ```bash
   flutter build apk --release
   ```
