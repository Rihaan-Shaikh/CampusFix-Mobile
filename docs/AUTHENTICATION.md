# CampusFix Mobile — Authentication Architecture & Implementation Guide

This document describes the complete authentication architecture, session lifecycle, token exchange mechanics, and backend contracts implemented in CampusFix Mobile.

---

## 1. Authentication Architecture Overview

CampusFix Mobile connects to the official CampusFix web backend (`https://campusfixed.netlify.app`), which utilizes **Better Auth** backed by Prisma and a shared PostgreSQL database. The mobile application does **not** create a separate identity system or database.

```mermaid
sequenceDiagram
    autonumber
    actor User as Campus Member
    participant UI as Flutter Presentation (SignInScreen)
    participant Notifier as AuthNotifier (Riverpod)
    participant Repo as BetterAuthRepository
    participant Storage as FlutterSecureStorage
    participant Dio as Dio HTTP Client (Interceptors)
    participant Backend as Better Auth / Next.js (/api/auth)
    participant API as Protected APIs (/api/v1)

    %% Registration & Login Flow
    User->>UI: Enter Email & Password
    UI->>Notifier: signIn(email, password)
    Notifier->>Repo: signIn(email, password)
    Repo->>Backend: POST /api/auth/sign-in/email
    Backend-->>Repo: 200 OK { user, token / session, Set-Cookie }
    Note over Repo: Robust Extraction:<br/>1. data['token']<br/>2. data['session']['token']<br/>3. Set-Cookie (__Secure-better-auth.session_token)
    Repo->>Storage: write('campusfix_auth_token', token)
    Repo->>Notifier: Return UserModel
    Notifier-->>UI: state = AuthAuthenticated(user)
    UI-->>User: Navigate to Shell / Home

    %% Protected API Call
    User->>UI: Fetch Issues / Create Incident
    UI->>Dio: GET /api/v1/issues
    Note over Dio: Interceptor injects:<br/>- Authorization: Bearer <token><br/>- Cookie: better-auth.session_token=<token>; __Secure-...
    Dio->>API: Request with Bearer & Session Cookies
    API-->>UI: 200 OK (Protected Data)
```

---

## 2. Supported Authentication Methods

| Method | Status | Backend Endpoint | Protocol / Mechanism | Verification Status |
| :--- | :--- | :--- | :--- | :--- |
| **Email / Password Login** | **Implemented** | `POST /api/auth/sign-in/email` | JSON payload → Token / Session Cookie | Automated Tested & Endpoint Probed |
| **Email Registration** | **Implemented** | `POST /api/auth/sign-up/email` | JSON payload → Token / Session Cookie | Automated Tested |
| **Session Restoration** | **Implemented** | `GET /api/v1/auth/me` with fallback to `GET /api/auth/get-session` | Secure storage read → Bearer Token & Cookie verification | Automated Tested |
| **Remote Sign-Out** | **Implemented** | `POST /api/auth/sign-out` | Remote session invalidation + local storage wipe | Automated Tested |
| **Google Sign-In** | **Implemented** | `POST /api/auth/sign-in/social` | Native OIDC ID token exchange | Automated Tested (Test Doubles) |
| **GitHub OAuth** | **Partially Implemented** | Web Browser / Deep Link (`campusfix://oauth-callback`) | OAuth 2.0 Web Redirect | Safe Client Stub & Deep Link Intent Verified |

---

## 3. The Better Auth Contract & Token Extraction

### Dual-Header Session Transport
Better Auth deployments running on Netlify/Next.js edge middleware can resolve authenticated sessions in two ways:
1. **Bearer Token**: `Authorization: Bearer <token>` (required by custom `/api/v1/*` routes).
2. **Session Cookies**:
   - `better-auth.session_token=<token>` (HTTP development)
   - `__Secure-better-auth.session_token=<token>` (HTTPS production)
   - `campusfix_authorization=<token>` (custom Next.js middleware)

To guarantee that requests succeed across all endpoints (both Better Auth internal handlers and custom REST APIs), `lib/core/network/api_client.dart` injects **both** the `Authorization` header and the cookie string on every outgoing request when a valid token is stored:

```dart
options.headers['Authorization'] = 'Bearer $token';
options.headers['Cookie'] =
    'better-auth.session_token=$token; __Secure-better-auth.session_token=$token; campusfix_authorization=$token';
```

### Multi-Strategy Response Parser (`BetterAuthRepository`)
Different Better Auth versions and plugins format the response body differently. The mobile client extracts the session token defensively in priority order:
1. Top-level JSON key: `data['token']`
2. Nested session object: `data['session']['token']` or `data['session']['id']`
3. `Set-Cookie` response headers: matching `(?:__Secure-)?better-auth\.session_token=([^;]+)` or `campusfix_authorization=([^;]+)`
4. `Authorization` response header: `Bearer <token>`

---

## 4. Google Native Sign-In Configuration

### Credentials & Fingerprints
- **Android Application ID**: `com.campusfix.app`
- **Debug Keystore SHA-1**: `4C:79:E9:2A:51:2E:A6:97:F3:6E:5E:9A:41:E5:3D:6D:71:7F:D8:EE`
- **Google Web/Server Client ID**: `440612845967-ggac7dh53iktbpo8t38qaj392kp5kk5v.apps.googleusercontent.com`

### How It Works:
1. The user taps "Google" on `SignInScreen`.
2. Native `GoogleSignIn.instance.authenticate()` invokes Google Play Services on the device.
3. The device requests an OIDC ID token with `serverClientId` set to the **Web Client ID**.
4. The obtained `idToken` is sent to Better Auth via `POST /api/auth/sign-in/social` with payload:
   ```json
   {
     "provider": "google",
     "idToken": {
       "token": "<GOOGLE_OIDC_ID_TOKEN>"
     }
   }
   ```
5. Better Auth validates the token signature against Google's public JWKS keys and verifies that the audience (`aud`) matches `GOOGLE_SERVER_CLIENT_ID`.
6. Better Auth creates/updates the user in PostgreSQL and issues a CampusFix session token.

---

## 5. GitHub OAuth Workflow

1. In Better Auth, GitHub is an external web OAuth provider.
2. The Android manifest registers intent filters for deep linking:
   ```xml
   <intent-filter>
       <action android:name="android.intent.action.VIEW"/>
       <category android:name="android.intent.category.DEFAULT"/>
       <category android:name="android.intent.category.BROWSABLE"/>
       <data android:scheme="campusfix" android:host="oauth-callback"/>
   </intent-filter>
   ```
3. When initiated via web browser, Better Auth redirects back to `campusfix://oauth-callback?token=<SESSION_TOKEN>`.
4. `AuthNotifier.handleOAuthCallback(token)` intercepts the token, persists it securely, and restores the user profile.

---

## 6. Security Hygiene & Local Storage

- Session tokens are stored using `FlutterSecureStorage` (backed by Android Keystore and iOS Keychain).
- Tokens and passwords are never logged to console output.
- `LogInterceptor` disables header and body logging in release mode and sanitizes authorization tokens in debug mode.
- Local draft issue data does not contain passwords or secrets.
