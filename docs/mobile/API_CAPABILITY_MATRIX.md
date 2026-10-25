# CampusFix Mobile — API Capability Matrix

This matrix documents the actual capabilities verified against `https://campusfixed.netlify.app/api/v1`, the mobile client implementation status, and backend requirements:

| Feature / Domain | Method & Endpoint | Auth Req | Role Perms | Request / Response Payload | Mobile Status | Verification Method |
|---|---|---|---|---|---|---|
| **List Issues** | `GET /api/v1/issues` | Optional | Public / Member | Query: `page`, `limit`, `status`, `category`, `priority`, `search`, `scope`<br>Response: `{items: IssueModel[], meta: PaginationMeta}` | Implemented | Automated tests pass. Live endpoint returned 401 JSON when unauthenticated. |
| **Get Issue Details** | `GET /api/v1/issues/:id` | Optional | Public / Member | Path: `id`<br>Response: `{data: IssueModel}` | Implemented | Automated tests pass. Verified model parser. |
| **Create Issue** | `POST /api/v1/issues` | Required | Member, Staff, Admin | Body: `{title, category, location, priority, description, attachments}`<br>Response: `{data: IssueModel}` with `referenceCode` | Implemented | Automated tests pass with validation & offline draft recovery. |
| **Update Issue Status** | `PATCH /api/v1/issues/:id` | Required | Staff, Admin | Body: `{status, note}`<br>Response: `{data: IssueModel}` | Implemented | Automated tests pass. Live backend confirmed route exists (returns 401 unauthorized). |
| **Email/Password Sign-In** | `POST /api/v1/auth/sign-in` | Public | All | Body: `{email, password}`<br>Response: `{token, user: UserModel}` | Implemented | Automated tests pass. Token stored in AES SecureStorage. |
| **Current User Profile** | `GET /api/v1/auth/me` | Required | Authenticated | Header: `Authorization: Bearer <token>`<br>Response: `{user: UserModel}` with role & permissions | Implemented | Automated tests pass. Auto-hydrates on startup. |
| **Sign Out** | `POST /api/v1/auth/sign-out` | Required | Authenticated | Header: `Authorization: Bearer <token>` | Implemented | Automated tests pass. Storage cleared. |
| **OAuth Authorization** | `GET /api/auth/sign-in/:provider` | Public | All | Query: `provider=google/github`, `redirect_uri=campusfix://oauth-callback` | Implemented (Architecture & UI) | Mocked & DeepLink test pass. Live provider requires Google/GitHub cloud console client ID. |
| **Image Evidence Upload** | Multipart / Direct URL | Required | Member+ | Multipart file (image/jpeg, png, webp <= 5MB) | Implemented (Native Picker + URL payload) | Automated tests pass. Files validated locally. |
| **Device Token Registration**| `POST /api/v1/notifications/register` | Required | Authenticated | Body: `{token: string, platform: 'android'}` | Implemented | NotificationService unit tests pass. |
