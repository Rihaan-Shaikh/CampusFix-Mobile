# CampusFix Mobile — New-PC Development Handoff Guide

This guide ensures complete continuity when cloning and running CampusFix Mobile on a fresh Windows development machine.

---

## 1. Prerequisites Checklist for Fresh Windows Machine

Ensure the following tools are installed before running the project:

| Tool | Recommended Version | Verification Command | Notes |
| :--- | :--- | :--- | :--- |
| **Git** | `2.40+` | `git --version` | Required to clone and maintain version control |
| **Flutter SDK** | `3.47.7` (channel `stable`) | `flutter --version` | Bundles Dart SDK `3.13.5` |
| **Dart SDK** | `3.13.5` (bundled) | `dart --version` | Bundled directly with Flutter SDK |
| **Java JDK** | OpenJDK 17 (`Java 17`) | `java -version` | **Mandatory** for Android Gradle Plugin 8.x/9.x and Kotlin 2.x |
| **Android Studio** | Latest Stable (Koala/Ladybug) | `flutter doctor -v` | Provides Android SDK, command-line tools, and emulator |
| **Android SDK** | API 36 / 37 | SDK Manager | Platforms: `android-36`, `android-37`. Build tools: `36.0.0` |

---

## 2. Step-by-Step Setup Sequence on New Laptop

### Step 1: Install OpenJDK 17 & Configure JAVA_HOME
1. Download Microsoft Build of OpenJDK 17 or Eclipse Temurin 17.
2. In Windows System Properties → Environment Variables:
   - Add `JAVA_HOME = C:\Program Files\Eclipse Adoptium\jdk-17...`
   - Append `%JAVA_HOME%\bin` to your `Path` variable.
3. Open a new terminal and verify:
   ```powershell
   java -version
   ```

### Step 2: Clone the Repository
```powershell
git clone <YOUR_EXISTING_REPOSITORY_URL>
cd CampusFix-Mobile
```

### Step 3: Install Flutter Dependencies
```powershell
flutter pub get
```

### Step 4: Verify Environment Health
```powershell
flutter doctor -v
```
Ensure Flutter, Android toolchain, and connected devices report no missing prerequisites.

### Step 5: Verify Static Analysis & Automated Tests
```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
All 104 tests must pass.

---

## 3. Environment Defines & Runtime Execution

The application is pre-configured to connect **out-of-the-box to the live CampusFix production backend** (`https://campusfixed.netlify.app/api/v1`). No manual `.env` file is required to connect to production.

### Running Against Production (Default)
```powershell
flutter run
```
or explicitly:
```powershell
flutter run --dart-define=ENVIRONMENT=production --dart-define=API_BASE_URL=https://campusfixed.netlify.app/api/v1
```

### Running with Local Backend
If you are running the backend locally on port 5000:
- **Android Emulator**:
  ```powershell
  flutter run --dart-define=ENVIRONMENT=development --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/v1
  ```
- **Physical Phone (via ADB reverse)**:
  ```powershell
  adb reverse tcp:5000 tcp:5000
  flutter run --dart-define=ENVIRONMENT=development --dart-define=API_BASE_URL=http://localhost:5000/api/v1
  ```
- **Physical Phone (via LAN IP)**:
  ```powershell
  flutter run --dart-define=ENVIRONMENT=development --dart-define=API_BASE_URL=http://192.168.1.X:5000/api/v1
  ```

---

## 4. Google Cloud & Android Signing Fingerprints

### Debug Fingerprints
When running debug builds, Android Studio signs with the local debug keystore:
- **Debug SHA-1**: `4C:79:E9:2A:51:2E:A6:97:F3:6E:5E:9A:41:E5:3D:6D:71:7F:D8:EE`
- **Package Name**: `com.campusfix.app`

### How to Check the Debug Fingerprint on the New Machine
If Android generates a new debug keystore on your new PC (`~/.android/debug.keystore`), inspect its SHA-1:
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```
If the SHA-1 differs from `4C:79:E9:2A...`, add the new SHA-1 to your **Google Cloud Console → Credentials → Android OAuth Client** under the package name `com.campusfix.app`.

---

## 5. Secret Hygiene & What Must NOT Be Committed

- `android/local.properties`: Contains developer-specific local paths (`sdk.dir`, `flutter.sdk`). Ignored in `.gitignore`.
- `.env`: Real secret credentials files are ignored.
- Keystores: `*.keystore`, `*.jks`, `key.properties` are ignored.
