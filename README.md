# Ruhamaa Foundation Employee Tracker — Flutter Applet

Welcome! This folder contains the complete, production-ready **Flutter Mobile Application** corresponding to the Ruhamaa Foundation Web Portal. It has been fully converted using **Material 3 (M3) UX standards** and integrates directly with the same Firebase Firestore backend, Storage, and Authentication services.

---

## 📱 Core Features Implemented

1. **Dual Gate Authentication**: Connects natively to Firebase Auth using official GMS services. Fits with local email-matched `employees` Firestore collections.
2. **High-Precision Geofencing & Timelines**: Watches device location streams in real-time. Calculates Haversine distances to enforce HQ radius boundaries.
3. **Geotagged Photo Watermarking**: Features a native Flutter Canvas-based watermarking utility (`WatermarkUtils`). Overlays translucent violet gradients, custom metadata (Officer name, ID, Project name), date-time Stamps, and GPS coordinates directly on device camera selfies.
4. **Active Task Controls**: Supports starting, pausing, and finishing tasks with embedded geotag proofs.
5. **Dynamic Leave & Visits Reporting**: Provides field teams dropdown project lists, multiple visit types, custom date range picking, and live leave counters.
6. **Supervisor Real-time Mapping**: Renders active officer pins and polyline breadcrumb historical tracks on Google Maps.

---

## 🚀 Step-by-Step Setup Instructions

Follow these instructions to configure, run, and compile signed release products for production app stores:

### 1. Configure Firebase Mobile Configs

Since the mobile platforms use native frameworks, you must generate mobile configuration files in your Firebase console:

- **Android**:
  1. Add an Android App with Package Name `org.ruhamaa.tracker` inside your Firebase Project.
  2. Download `google-services.json` and place it in `/flutter_app/android/app/`.
- **iOS**:
  1. Add an iOS App with Bundle ID `org.ruhamaa.tracker` inside your Firebase Project.
  2. Download `GoogleService-Info.plist` and place it in `/flutter_app/ios/Runner/`.

### 2. Configure Google Maps SDK

- Generate an API key in your Google Cloud Console with the **Maps SDK for Android** and **Maps SDK for iOS** enabled.
- Open `/flutter_app/android/app/src/main/AndroidManifest.xml` and replace `YOUR_ANDROID_MAPS_API_KEY` with your key.

### 3. Generate a Production Signing Keystore

To compile signed packages ready for Google Play Store, you must generate a release signing key. Run the following command in your terminal:

```bash
keytool -genkey -v -keystore ruhamaa_release_key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ruhamaa_alias
```

- When prompted, set a secure password (e.g. `RuhamaaSecurePassword123!`).
- Move the resulting file `ruhamaa_release_key.jks` into the `/flutter_app/android/` folder.

### 4. Set Up Release Keys (`key.properties`)

Open `/flutter_app/android/key.properties` and verify your credentials match the keystore credentials generated above:

```properties
keyAlias=ruhamaa_alias
keyPassword=RuhamaaSecurePassword123!
storeFile=ruhamaa_release_key.jks
storePassword=RuhamaaSecurePassword123!
```

---

## 🛠️ Building Production App Packages

Ensure you have the Flutter SDK (version `>= 3.0.0`) installed on your local machine, then navigate to `/flutter_app` in your console and run:

### Step A: Fetch Packages
```bash
flutter pub get
```

### Step B: Build Signed Release APK
This outputs a fully signed, production-ready APK file supporting older and newer Android devices:
```bash
flutter build apk --release
```
*Output Location:* `/flutter_app/build/app/outputs/flutter-apk/app-release.apk`

### Step C: Build Android App Bundle (AAB)
This outputs the App Bundle required by Google Play Console for deployment:
```bash
flutter build appbundle --release
```
*Output Location:* `/flutter_app/build/app/outputs/bundle/release/app-release.aab`

### Step D: Build iOS App Store Package (IPA)
Ensure you are running on a macOS environment with Xcode configured, then execute:
```bash
flutter build ipa --release
```
*Output Location:* `/flutter_app/build/ios/archive/Runner.xcarchive` (ready to submit via Transporter or Xcode Organizer).

---

## 🗂️ Project Code Map

- `lib/main.dart`: Global entry point with MultiProvider setup, named routes, and custom Material 3 themes.
- `lib/providers/app_state_provider.dart`: Heart of the app; manages Firestore snapshots, background GPS mapping loops, geofence validations, biometric camera bindings, and state transitions.
- `lib/services/firebase_service.dart`: Exposes atomic Firestore and Storage CRUD operations matching original security rules.
- `lib/utils/watermark_utils.dart`: Ultra high-performance UI Canvas overlay drawer.
- `lib/models/`: Encapsulates 100% accurate data structures (`employee.dart`, `attendance.dart`, `task.dart`, etc.).
- `lib/screens/`: Contains responsive, fully typed user-interfaces for Login, Dashboard, Check-In/Out lines, Field Visits, Task Timers, Leave applications, and Maps routing.
