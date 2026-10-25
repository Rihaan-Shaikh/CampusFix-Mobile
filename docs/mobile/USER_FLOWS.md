# CampusFix Mobile — End-to-End User Flows

## Flow 1: First Launch & Session Restoration
```mermaid
graph TD
    A[Launch App] --> B[Display Native Android Splash]
    B --> C[Read campusfix_auth_token from SecureStorage]
    C -->|Token Present| D[Fetch /api/v1/auth/me]
    D -->|Valid 200 OK| E[Hydrate AuthState.authenticated with User Role]
    E --> F[Direct to /home with Role Navigation]
    C -->|No Token| G[Set AuthState.unauthenticated]
    G --> F
    D -->|Expired 401| H[Clear Stored Token]
    H --> G
```

## Flow 2: Reporting an Incident with Native Photo & Draft Recovery
```mermaid
graph TD
    A[User opens /report-issue] --> B[Check for saved draft in storage]
    B -->|Draft Found| C[Display 'Recovered Unfinished Draft' banner]
    C -->|Tap Restore| D[Populate Form Fields & Attachments]
    C -->|Tap Discard| E[Delete Draft & Clear Form]
    B -->|No Draft| F[Empty Form Ready]
    D --> G[User edits fields]
    F --> G
    G --> H[Debounced Auto-Save Draft to SecureStorage]
    G --> I[Tap 'Camera' or 'Gallery']
    I --> J[Invoke image_picker with 5MB validation]
    J --> K[Add to _attachments and persist in Draft]
    K --> L[Tap 'Submit Incident Report']
    L --> M[Cancel draft timer & Post to POST /api/v1/issues]
    M -->|201 Created| N[Clear saved draft]
    N --> O[Refresh Home & Issues feeds in background]
    O --> P[Display Success Screen with CFX-XXXX Reference Code]
    M -->|Network Error / 5xx| Q[Preserve form data & Show recoverable error banner]
```

## Flow 3: Technician & Admin Status Transition
```mermaid
graph TD
    A[Staff / Admin opens /issues/:id] --> B[Fetch GET /api/v1/issues/:id]
    B --> C[Render Issue Details & Current Status Badge]
    C --> D[Display 'Update Incident Status' Action Button]
    D --> E[Open Status Transition Modal Bottom Sheet]
    E --> F[Select Target Status: OPEN, IN_PROGRESS, or RESOLVED]
    F --> G[Enter Optional Work Note / Resolution Evidence]
    G --> H[Tap 'Confirm Status Change']
    H --> I[Send PATCH /api/v1/issues/:id]
    I -->|200 OK| J[Update local issue state & timeline]
    J --> K[Trigger refresh of Issues list and Home recent feed]
    K --> L[Dismiss modal & Show success snackbar]
    I -->|401/403/500| M[Display inline error inside modal with retry]
```
