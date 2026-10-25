# CampusFix Mobile — Google Play Release Candidate Checklist

## 1. Application Metadata & Identifiers
- [x] **Application ID**: `com.campusfix.app` (configured in `android/app/build.gradle`).
- [x] **App Display Name**: `CampusFix` (configured in `AndroidManifest.xml`).
- [x] **Version Name / Code**: `1.0.0` / `1` (versioned via `pubspec.yaml`).
- [x] **Launcher Icon**: Clean 180x180 cropped dark navy tile with locator, tools, and amber marker across `mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`.
- [x] **Adaptive Icon**: `ic_launcher_foreground.png` in inner 66% safe zone with `@color/ic_launcher_background` (`#0E1728`).
- [x] **Splash Screen**: Centered `splash_logo.png` over brand navy `#0E1728` background in `drawable` and `drawable-v21`.

## 2. Security & Release Hygiene
- [x] **Production HTTPS API**: `https://campusfixed.netlify.app/api/v1` configured as default.
- [x] **DEV MODE Suppression**: `CampusDevBanner`, debug diagnostic cards, and component gallery buttons are hidden when `kReleaseMode || config.environment.isProduction`.
- [x] **Credential Redaction**: `ApiClient` custom logger redacts `Authorization: Bearer <token>` and cookie headers.
- [x] **Android Permissions**:
  - `INTERNET`: Required for API requests.
  - `CAMERA`: Required for real-time photo capture of incident evidence.
  - `READ_EXTERNAL_STORAGE` / `READ_MEDIA_IMAGES`: Scoped access for gallery photo selection.
  - `POST_NOTIFICATIONS`: Android 13+ runtime notification permissions.

## 3. Store Listing & Compliance Deliverables
- [ ] **Release Keystore & Key**: Generate `campusfix-release-key.jks` and supply passwords via environment variables or CI secrets (do NOT commit keystore to Git).
- [ ] **Privacy Policy URL**: Host publicly accessible privacy policy at `https://campusfixed.netlify.app/privacy`.
- [ ] **Google Play Data Safety Disclosures**:
  - Personal Info: Name and email (for account management and communication).
  - Photos and Videos: User-uploaded incident evidence images.
  - Device IDs: Push notification registration token.
  - Security Practices: Data encrypted in transit via HTTPS (TLS 1.3), user can request account deletion.
- [ ] **Store Graphics**: High-res icon (512x512 PNG), Feature Graphic (1024x500 PNG), and physical phone screenshots (1080x2400).
- [ ] **Testing Track**: Deploy Android App Bundle (`.aab`) to Google Play Internal Testing Track for closed testing on physical Vivo device.
