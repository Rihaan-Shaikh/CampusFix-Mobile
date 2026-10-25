# CampusFix Mobile — Authentication & OAuth Architecture

## 1. Authentication Foundation
The backend is built with Next.js and Better Auth, with database-backed session state.
Mobile API requests require a Bearer token:
`Authorization: Bearer <campusfix_auth_token>`

## 2. Supported Authentication Mechanisms
1. **Email / Password**:
   - Endpoint: `POST /api/v1/auth/sign-in` (or Better Auth `/api/auth/sign-in/email`)
   - Returns session token and user profile model with role (`MEMBER`, `STAFF`, `ADMIN`).
   - Stored in Android Keystore / iOS Keychain via `FlutterSecureStorage`.
2. **Social OAuth (Google & GitHub)**:
   - Better Auth on the web supports OAuth redirects to `/api/auth/callback/google` and `/api/auth/callback/github`.
   - On mobile, OAuth uses custom tabs / system browser with PKCE verification and deep link callback:
     `campusfix://oauth-callback?token=...` or `https://campusfixed.netlify.app/api/auth/callback/mobile`.
   - PKCE code verifier and state challenge are generated securely on the client prior to launching the browser intent.
   - Upon return, the deep link intent filter intercepts the URL, extracts the exchange token, verifies the state parameter against the stored challenge, exchanges it for an authenticated session token, and hydrates Riverpod `authNotifierProvider`.

## 3. Session Lifecycle & Expiry Handling
- **Startup**: `AuthNotifier.init()` checks secure storage. If token exists, calls `GET /api/v1/auth/me`. If valid, hydrates user state; if 401 Unauthorized, automatically purges the stale token and transitions to unauthenticated state without infinite loops.
- **API Requests**: `ApiClient` interceptor injects `Authorization: Bearer <token>` into all outgoing HTTP requests.
- **Sign-Out**: `AuthNotifier.signOut()`:
  - Calls `POST /api/v1/auth/sign-out` (bounded).
  - Clears `campusfix_auth_token` from secure storage.
  - Clears offline issue drafts (`campusfix_issue_draft_v1`).
  - Cleans up registered FCM device token (`campusfix_fcm_device_token`).
  - Resets all in-memory user states and redirects to `/home`.

## 4. Security Constraints & Prohibitions
- Bearer tokens are NEVER logged, printed to console, or written to standard `SharedPreferences`.
- OAuth client secrets are NEVER embedded inside the Flutter APK/AAB bundle.
- Client-side navigation guards are paired with server-side authorization checks on all mutating API calls.
