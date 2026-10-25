# CampusFix Mobile — Implementation Plan

## Phase 3 Execution Stages

### Stage A: Recovery & Diagnostic Supervision
- Terminate stale tasks safely.
- Verify bounded network requests (15s maximum timeout, no infinite waiting).

### Stage B: Product Architecture & Specifications
- Complete all core specification documents (`PRODUCT_SPEC.md`, `INFORMATION_ARCHITECTURE.md`, `DESIGN_SYSTEM.md`, `USER_FLOWS.md`, `AUTH_AND_OAUTH.md`, `API_CAPABILITY_MATRIX.md`, `RELEASE_CHECKLIST.md`).

### Stage C: Logo & Brand Foundation
- Crop source screenshot asset `media_1792174657490.png` to exact 180x180 tile, removing light outer canvas and drop shadow.
- Generate mipmap launcher icons, adaptive icons with safe-zone padding, and native launch background drawables.
- Ensure zero DEV MODE badges or debug config panels appear in production/release mode.

### Stage D: Enterprise Authentication & OAuth
- Refine `SignInScreen` with Google and GitHub OAuth entry points.
- Support deep link callback `campusfix://oauth-callback` and state/PKCE challenge verification.
- Secure session storage and automatic startup hydration.

### Stage E: Core Member Experience
- Refactor `HomeScreen` into a personalized campus facilities workspace with quick report CTA, category shortcuts, and live recent incidents.
- Refactor `IssuesScreen` with responsive filter chips, search input, scope toggles (All vs. My Issues), and pagination.
- Enhance `ReportIssueScreen` with native camera & gallery picker, 5MB file validation, image previews, and offline draft auto-save/recovery.
- Enhance `IssueDetailScreen` with resolution timeline, attachment gallery, and status transition sheet.

### Stage F: Role-Based Staff & Administrator Workflows
- Staff work queue access on Home and Issues screens.
- Operational status transition (`OPEN`, `IN_PROGRESS`, `RESOLVED`) with audit note tracking.
- Admin overview metrics and user directory overview.

### Stage G: Native Capabilities & Resilience
- `DraftStorageService`: Auto-saves drafts during report composition; clears on success/logout.
- `DeepLinkService`: Parses custom scheme `campusfix://issue/:id` and web URLs `https://campusfixed.netlify.app/issues/:id`.
- `NotificationService`: Manages device tokens and resolves incoming push notification routes.
- `ApiClient`: Idempotent GET retries on network blips and sanitized logging.

### Stage H: Release Preparation & Verification
- Verify formatting (`dart format .`), static analysis (`flutter analyze`), and full test suite (`flutter test`).
- Compile debug APK using actual dart-define production configuration.
- Prepare Google Play Store release candidate checklist.
