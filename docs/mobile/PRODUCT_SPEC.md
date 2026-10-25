# CampusFix Mobile — Product Specification

## 1. Product Mission & Value Proposition
CampusFix is an enterprise-grade campus facilities incident management and resolution product. The mobile application empowers campus members (students, faculty, administrative staff) to report facilities infrastructure defects (electrical, plumbing, HVAC, network, structural, furniture, cleanliness), provide visual photographic evidence, trace lifecycle status in real time, and receive instant push updates.

For facility technicians, operations personnel, and campus administrators, the mobile client provides prioritized triage queues, authenticated status workflows (`OPEN` -> `IN_PROGRESS` -> `RESOLVED`), workload assignment, and operational oversight.

## 2. Target Roles & Permission Boundaries
1. **Campus Member (Default Role)**:
   - Report facilities incidents with titles, category, description, physical location, and up to 5MB photographic attachments.
   - Save and recover offline drafts locally across device restarts.
   - Track public campus incidents and filter personal reported submissions under "My Issues".
   - Receive notifications when reported incidents transition states.
2. **Staff / Operations Technician**:
   - Everything available to Campus Members.
   - Access "Technician Work Queue" with assigned work orders.
   - Transition assigned incident status (`OPEN`, `IN_PROGRESS`, `RESOLVED`) with operational progress notes.
   - View technician audit timeline.
3. **Campus Administrator**:
   - Everything available to Staff.
   - Complete operational oversight over campus-wide queues.
   - Administrative reassignment of work orders to technicians.
   - Priority reassessment and incident closure verification.
   - Access user role lookup and facility directory summaries.

## 3. High-Level Feature Inventory
- **Mobile-First Experience**: High-contrast, tactile touch targets (>= 48dp), crisp dark/light theme switching, responsive layouts accommodating small and large viewports without horizontal clipping or content truncation.
- **Reliable Native Capabilities**:
  - Image capture via native Android Camera intent.
  - Image selection via Android Photo Picker / Gallery with 5MB quota and JPG/PNG/WEBP validation.
  - Local auto-saving drafts stored in encrypted secure storage, resilient to accidental navigation or app closure.
- **Robust Network & Sync Engine**:
  - 15s connection and receive timeouts with safe idempotent GET retries.
  - Exponential backoff protection preventing request stampedes.
  - Mutation-triggered cross-screen synchronization keeping Home and Issues feeds completely consistent.
- **Enterprise Authentication & Session Resilience**:
  - Email/Password sign-in with clear field validation.
  - Standard OAuth authorization-code with PKCE support (`campusfix://oauth-callback` and web redirect handlers).
  - Secure AES-256 session token persistence via `FlutterSecureStorage`.
  - Silent startup session restoration and clean teardown upon sign-out.
- **Deep Linking & Push Notification Readiness**:
  - Direct routing for `campusfix://issue/:id` and web URLs `https://campusfixed.netlify.app/issues/:id`.
  - Push notification payload routing with strict server-side authorization enforcement.
