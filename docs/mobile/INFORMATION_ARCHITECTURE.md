# CampusFix Mobile — Information Architecture & Navigation Map

## 1. Structural Navigation Principles
The navigation system is role-aware and clean. Instead of overcrowding the bottom navigation bar with extraneous tabs, CampusFix Mobile uses a focused 4-tab shell for primary contexts, with contextual drill-downs and role-gated modals:

```
[ Root Shell - StatefulShellRoute ]
  ├── Tab 1: Home (/home)
  │     ├── Hero Summary & Quick Report CTA
  │     ├── Technician Work Queue Card (Staff / Admin only)
  │     ├── Active Stats & Category Shortcuts
  │     └── Recent Verified Campus Incidents List (Synchronized)
  │
  ├── Tab 2: Issues Feed (/issues)
  │     ├── Search Bar (Title, location, reference code)
  │     ├── Scope Segment: All Campus Issues vs. My Reported Issues
  │     ├── Horizontal Category Filter Chips
  │     ├── Status Filter Toggle (All, Open, In Progress, Resolved)
  │     ├── Infinite Scrolling List & Pull-to-Refresh
  │     └── Floating Quick Report Button
  │
  ├── Tab 3: Report Issue (/report-issue) [Direct route from FAB or Tab]
  │     ├── Recoverable Draft Banner (Restore / Discard)
  │     ├── Incident Details: Title, Category, Priority, Location
  │     ├── Detailed Description Input
  │     ├── Evidence Attachment Picker (Camera / Gallery)
  │     ├── Attachment Previews with Delete Action
  │     ├── Live Form Validation & Submit Button
  │     └── Confirmed Success View with Incident Reference Code
  │
  └── Tab 4: Profile & Settings (/profile)
        ├── Authenticated User Card (Avatar, Name, Email, Role Badge)
        ├── Role-Specific Hub Links (Staff Queue / Admin Overview)
        ├── Appearance: Light, Dark, System Theme Selector
        ├── Notification Preferences (Status updates, Work assignments)
        ├── Offline Storage Stats & Draft Cache Management
        ├── About & App Version Info (Clean, no debug credentials in release)
        └── Sign Out / Sign In Interactive Actions
```

## 2. Secondary & Contextual Routes
- `/issues/:id` — **Issue Detail Screen**:
  - Reference code header and live status badge.
  - Reporter metadata, creation timestamp, location badge.
  - Problem description and high-resolution photographic evidence gallery.
  - Resolution audit timeline (chronological status transitions with notes).
  - **Staff / Admin Floating Action**: "Update Status" bottom sheet modal allowing transition between `OPEN`, `IN_PROGRESS`, and `RESOLVED` with optional progress notes.
- `/auth/sign-in` — **Sign In Screen**:
  - CampusFix dark navy brand header with official approved logo.
  - Email and password inputs with validation and obscure toggles.
  - Social OAuth Provider Buttons (Google, GitHub) with native webview / custom-tab authorization.
  - Safe error banners and connection diagnostics handling.
- `/oauth-callback` — **OAuth Deep Link Receiver**:
  - Handles authorization codes, validates state/PKCE tokens, exchanges for authenticated session, and redirects to target destination.
