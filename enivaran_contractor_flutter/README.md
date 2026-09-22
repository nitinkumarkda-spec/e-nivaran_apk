# KDA e-Nivaran - Department & Officer Mobile App (Flutter)

Official Departmental & Officer Mobile Application for **Kota Development Authority (KDA) - eNivaran Grievance Redressal & Field Inspection System**.

Built with **Flutter & Dart**, providing a dedicated workspace for KDA Officers (Super Admin, Moderators, JENs, AENs, XENs) and Empaneled Contractors.

---

## 🌟 Key Features Included

- **Dedicated to Department Only**: Zero citizen options. All citizen login links, "Go to Citizen", and "Install App" prompts are automatically suppressed.
- **Officer & Field Focused Flow**:
  1. **Animated Department Splash Screen**: Official KDA Emblem with glowing badge animation.
  2. **Departmental Onboarding Slides**: 3 interactive slides highlighting Grievance Queue, Field Inspection (JEN/AEN with GPS), and Contractor Resolution.
  3. **Department Web Portal (`webview_flutter`)**:
     - Automatically connects to:  
       `https://kdakota.rajasthan.gov.in/enivaran/auth/department-login?dept_app=1`
     - **Dual Theme Support**: Flawless contrast in both Dark Mode (`#1e293b` slate cards with crisp white text) and Light Mode.
     - **Empty Chart State**: Handles zero active complaints with a sleek "All Grievances Addressed" state instead of an empty box.
     - **Configurable Host URL**: Tap menu ➔ "Host URL Settings" to easily switch between production, local server, or Cloudflare tunnels.
     - **Pull-to-Refresh & Back Navigation**: Pull to reload, and press back safely with Android back navigation.
  4. **Native Officer Console & Dashboard**: Offline preview of assigned metrics (Assigned, In Progress, SLA Critical, Resolved) and direct action shortcuts.

---

## 📁 Project Structure

```
enivaran_department_flutter/
├── assets/
│   └── images/
│       └── logo2.png                       # Official KDA Emblem
├── lib/
│   ├── config/
│   │   └── api_config.dart                 # Endpoint URLs & dynamic host management
│   ├── models/
│   │   └── department_user.dart            # Officer role and user models
│   ├── screens/
│   │   ├── splash_screen.dart              # Department Splash with KDA Emblem
│   │   ├── intro_screen.dart               # 3 Officer Onboarding Carousel Slides
│   │   ├── department_web_portal_screen.dart # WebView with Dark Mode & script injection
│   │   ├── department_login_screen.dart    # Native Officer Login & Role Selector
│   │   └── department_dashboard_screen.dart# Native Department Metric Console
│   └── main.dart                           # Flutter App Entry Point with Dark Theme
├── android/                                # Android Native Runner Configuration
│   ├── app/
│   │   ├── build.gradle                    # Package: in.gov.rajasthan.kdakota.enivaran.department
│   │   └── src/main/
│   │       ├── AndroidManifest.xml         # Camera, Location, Storage Permissions
│   │       └── kotlin/.../MainActivity.kt
│   ├── build.gradle
│   └── settings.gradle
├── ios/                                    # Apple iOS Native Runner Configuration
│   ├── Podfile                             # CocoaPods dependencies & iOS 13+ platform target
│   ├── Runner/
│   │   ├── Info.plist                      # Camera, Location, Photo Privacy Permissions
│   │   ├── AppDelegate.swift               # iOS application entry
│   │   └── Assets.xcassets/                # iOS App Icon Catalog
│   ├── Runner.xcodeproj/                   # Xcode Project Configuration
│   └── Runner.xcworkspace/                 # Xcode Workspace
└── pubspec.yaml                            # Dependencies & assets configuration
```

---

## 🚀 How to Run & Build

### 1. Android Build (.apk)
```bash
# Get packages
flutter pub get

# Run on Android phone / emulator
flutter run

# Build release Android APK (.apk)
flutter build apk --release
```
The compiled APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

---

### 2. iOS Build (.ipa)
> **Note on iOS binaries**: While Android uses **`.apk`**, Apple iOS devices use **`.ipa`** (iOS App Store Package). The same Flutter codebase compiles to native iOS using Xcode!

```bash
# Get packages
flutter pub get

# Install CocoaPods dependencies for iOS
cd ios
pod install
cd ..

# Run on connected iPhone or iOS Simulator
flutter run -d ios

# Build release iOS archive
flutter build ios --release

# Build release iOS .ipa package
flutter build ipa --release --no-codesign
```
To open in Xcode on macOS:
```bash
open ios/Runner.xcworkspace
```
From Xcode, select **Product > Archive** to distribute via:
- **TestFlight** (Apple Official Testing)
- **Ad-Hoc / Enterprise** (Direct device installation via Diawi / AltStore)
- **App Store Connect** (Official public release)

