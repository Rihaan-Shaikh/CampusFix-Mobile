# CampusFix Mobile — Design System & Visual Foundation

## 1. Brand Identity & Visual Language
Aligned directly with the production website `https://campusfixed.netlify.app/` and the official CampusFix logo:
- **Core Dominant**: Deep Navy (`#0E1728` / `#0A0F1D`) — Authoritative, high-contrast, clean modern foundation.
- **Brand Accent**: Amber Gold (`#F59E0B` / hover `#D97706`) — Delivers purposeful visual hierarchy for primary calls-to-action, badges, and markers.
- **Surface Elevation**: Layered neutral navy card surfaces (`#1E293B` dark, `#FFFFFF` light) with subtle 1px structural borders (`#334155` dark, `#E2E8F0` light) eliminating heavy shadows and tacky gradients.

## 2. Color Palette & Token Definitions

### Primary & Accent
- `AppColors.deepNavy`: `#0E1728`
- `AppColors.brandAmber`: `#F59E0B`
- `AppColors.brandAmberHover`: `#D97706`
- `AppColors.brandAmberBg`: `Color(0x26F59E0B)`

### Status Indicators (Semantic)
- **OPEN**: `#F59E0B` (Amber) | Background: `Color(0x1AF59E0B)`
- **IN_PROGRESS**: `#3B82F6` (Electric Blue) | Background: `Color(0x1A3B82F6)`
- **RESOLVED**: `#10B981` (Emerald Green) | Background: `Color(0x1A10B981)`
- **CRITICAL / ERROR**: `#EF4444` (Ruby Crimson) | Background: `Color(0x1AEF4444)`

### Typography Scale
Strictly avoids browser defaults and uses systematically scaled hierarchy:
- Display Large: 28sp / bold / -0.5 tracking
- Headline Medium: 24sp / bold / -0.3 tracking
- Headline Small: 22sp / bold / -0.2 tracking
- Title Large: 20sp / semi-bold / -0.2 tracking
- Title Medium: 16sp / semi-bold / 0 tracking
- Body Large: 16sp / regular / 1.5 height
- Body Medium: 14sp / regular / 1.45 height
- Body Small: 12sp / regular / 1.4 height
- Label Large: 14sp / semi-bold / button scale
- Label Small: 11sp / medium / badge scale

### Spacing & Metrics
- `AppSpacing.xs`: 4dp
- `AppSpacing.sm`: 8dp
- `AppSpacing.md`: 12dp
- `AppSpacing.lg`: 16dp
- `AppSpacing.xl`: 24dp
- `AppSpacing.xxl`: 32dp
- Touch Targets: Guaranteed minimum 48dp height for all interactive buttons, chips, and list tiles.
- Border Radii: 8dp (`sm`), 12dp (`md`), 16dp (`lg`), 24dp (`xl`).

## 3. Component Standards
1. **CampusButton**:
   - `primary`: Filled deep navy / amber accent with 48dp minimum height and integrated progress indicator.
   - `secondary`: Card surface with subtle border.
   - `danger`: Ruby red for destructive actions (e.g. discarding drafts).
2. **CampusIssueCard**:
   - Status badge, formatted reference code (`CFX-XXXX`), clear title, location icon + text, timestamp, and attachment badge.
3. **CampusTimeline**:
   - Chronological vertical timeline detailing who transitioned status and why.
4. **Photo Attachment Card**:
   - 80x80 rounded preview with remove button and tap-to-inspect viewer.
