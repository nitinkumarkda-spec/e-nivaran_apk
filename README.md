# KDA e-Nivaran: Official Mobile Applications & Release APKs

This repository contains the standalone Flutter source code and ready-to-install Android APK binaries for the Kota Development Authority (KDA) e-Nivaran grievance redressal system.

---

## 📥 Direct APK Downloads

Ready-to-install release APKs are located in the [`/apks`](./apks) folder:

| Application | Target Audience | File Name | Size | Direct Link |
| :--- | :--- | :--- | :--- | :--- |
| **Citizen App (e-Nivaran)** | Citizens of Kota | `KDA-eNivaran-Citizen.apk` | ~17 MB | [Download](./apks/KDA-eNivaran-Citizen.apk) |
| **Department App** | KDA Officers & Engineers | `KDA-Department.apk` | ~18 MB | [Download](./apks/KDA-Department.apk) |
| **Contractor App** | Authorized Contractors | `KDA-Contractor.apk` | ~54 MB | [Download](./apks/KDA-Contractor.apk) |

---

## 📱 Source Code Structure

Each application is a completely independent Flutter project with its own clean codebase:

### 1. [`/enivaran_flutter`](./enivaran_flutter) (Citizen App)
- Citizen Complaint Registration with live camera, gallery attachment, and GPS geocoding.
- Live Status Tracking (Registered, In Progress, Resolved).
- Citizen Profile and Push Notifications.

### 2. [`/enivaran_department_flutter`](./enivaran_department_flutter) (Department App)
- Secure Officer Login with role-based dashboard.
- Live grievance metrics (Pending, In Progress, Resolved, Escalated).
- Action tiles: Direct Resolution, Site Inspection, Re-assignment, Call Citizen.
- Integrated Web Portal view with auto session pass.

### 3. [`/enivaran_contractor_flutter`](./enivaran_contractor_flutter) (Contractor App)
- Work order assignment and site execution tracking.
- Completion verification and inspection uploads.

---

## 🛠️ How to Run Locally

Open any of the three folders in VS Code or Android Studio:

```bash
# Example: Running Citizen App
cd enivaran_flutter
flutter pub get
flutter run

# Example: Running Department App
cd enivaran_department_flutter
flutter pub get
flutter run
```

---

## 📦 Building Fresh APKs

```bash
# Inside any app folder:
flutter build apk --release --split-per-abi
```
Generated lightweight APKs will be located at:
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
