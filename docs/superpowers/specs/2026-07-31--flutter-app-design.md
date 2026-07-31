# Flutter App Design Specification — App Martabak

**Tanggal:** 2026-07-31  
**Status:** Draft (menunggu approval user)  
**Author:** Mavis (Documentation Agent)  
**Target:** Flutter Android App  
**Companion:** [Backend Design Spec](./2026-07-29--martabak-app-design.md) | [Flutter Implementation Docs](../../FLUTTER.md)

---

## 1. Ringkasan

Spesifikasi ini mencakup **UI/UX decisions** untuk Flutter app kasir martabak:

- Brand identity (colors, typography, visual language)
- Screen layouts dan wireframes
- Component specifications
- Interaction patterns (animations, transitions)
- State management approach
- Navigation patterns

**Design Philosophy:**
> "Modern POS yang terasa hangat dan familiar — bukan generic enterprise app."

---

## 2. Brand Identity

### 2.1 Visual Language

**Tema:** "Martabak Traditional Warmth meets Modern POS"

Karakter visual:
- **Warm & Appetizing** — warna coklat/emas yang ngingetin martabak
- **Clean & Fast** — UI minimalis untuk transaksi cepat
- **Readable at a Glance** — teks besar, kontras tinggi, untuk kondisi lapak rame

### 2.2 Color Palette

```dart
// Primary Colors — Coklat Martabak
primary             // #D2691E — Chocolate (main brand)
primaryLight       // #E8A665 — Light chocolate
primaryDark        // #8B4513 — Dark chocolate

// Secondary Colors — Emas/Amber
secondary          // #FFC107 — Amber/Gold
secondaryLight     // #FFD54F — Light amber
secondaryDark      // #FFA000 — Dark amber

// Neutrals
background         // #FFF8F0 — Cream white (warm)
surface            // #FFFFFF — Pure white
surfaceVariant     // #F5F0E8 — Warm gray
divider            // #E8E0D5 — Subtle divider

// Text
textPrimary        // #2D1B0E — Dark brown (high contrast)
textSecondary      // #5D4037 — Medium brown
textHint           // #8D6E63 — Light brown
textOnPrimary      // #FFFFFF — White on primary
textOnSecondary    // #2D1B0E — Dark on secondary

// Semantic
success            // #4CAF50 — Green (payment success)
successLight       // #E8F5E9 — Light green background
error              // #E53935 — Red (errors)
errorLight         // #FFEBEE — Light red background
warning            // #FF9800 — Orange (pending/expired)
info               // #2196F3 — Blue (informational)
```

### 2.3 Typography

**Font Family:** Google Fonts — Poppins (headings), Inter (body)

> **Alternatif:** Default system font jika Google Fonts loading lambat

```dart
// Headlines — Untuk big numbers (dashboard, totals, prices)
headlineLarge      // 32sp, Bold (700), letterSpacing: -0.5
headlineMedium     // 28sp, Bold (700)
headlineSmall      // 24sp, SemiBold (600)

// Titles — Screen titles, section headers
titleLarge         // 22sp, SemiBold (600)
titleMedium        // 18sp, SemiBold (600)
titleSmall         // 16sp, Medium (500)

// Body — Normal text, descriptions
bodyLarge          // 16sp, Regular (400)
bodyMedium         // 14sp, Regular (400)
bodySmall          // 12sp, Regular (400)

// Labels — Buttons, tabs, chips
labelLarge         // 14sp, SemiBold (600)
labelMedium        // 12sp, Medium (500)
labelSmall         // 11sp, Medium (500)

// Special
priceLarge         // 28sp, Bold (700) — untuk total harga
priceMedium        // 20sp, SemiBold (600) — untuk harga item
refId              // 12sp, Medium (500), monospace — untuk invoice number
```

### 2.4 Spacing System

```dart
// Base unit: 4dp
spacingXs          // 4dp  — Tight spacing
spacingSm          // 8dp  — Small gaps
spacingMd          // 16dp — Default spacing
spacingLg          // 24dp — Section gaps
spacingXl          // 32dp — Large sections
spacingXxl         // 48dp — Screen padding top/bottom

// Border Radius
radiusSm           // 8dp  — Small elements (chips)
radiusMd           // 12dp — Cards, buttons
radiusLg           // 16dp — Modals, bottom sheets
radiusXl           // 24dp — Large cards
radiusFull         // 999dp — Pills, circular buttons

// Elevation
elevationNone      // 0dp
elevationSm        // 2dp  — Cards
elevationMd        // 4dp  — Bottom nav
elevationLg        // 8dp  — Modals, FAB
```

### 2.5 Iconography

**Style:** Rounded Outlined (Material Symbols)

```yaml
# Recommended icons
- material_symbols_rounded
- cupertino_icons (fallback)
```

**Icon Sizes:**
- Navigation: 24dp
- Action buttons: 24dp
- Menu cards: 32dp
- Empty states: 64dp

---

## 3. Screen Layouts

### 3.1 Login Screen

**Route:** `/login`  
**Access:** Public

```
┌─────────────────────────────────────────┐
│                                         │
│           🏪 Martabak Pak Harto        │  ← Shop name from settings
│                                         │
│     ┌─────────────────────────────┐     │
│     │     [App Logo/Icon 80dp]    │     │
│     └─────────────────────────────┘     │
│                                         │
│         Pilih Kasir / Owner              │
│                                         │
│     ┌─────────┐  ┌─────────┐          │
│     │   👤    │  │   👤    │          │
│     │  Owner  │  │  Budi   │          │
│     │ (crown) │  │         │          │
│     └─────────┘  └─────────┘          │
│                                         │
│     ┌─────────┐  ┌─────────┐          │
│     │   👤    │  │         │          │
│     │  Andi   │  │   + ?   │          │
│     │         │  │Tambah   │          │
│     └─────────┘  └─────────┘          │
│                                         │
│     ┌─────────────────────────────┐     │
│     │      [ ● ● ● ● ]           │     │  ← PIN dots
│     │                             │     │
│     │    [1]  [2]  [3]           │     │
│     │    [4]  [5]  [6]           │     │
│     │    [7]  [8]  [9]           │     │
│     │    [⌫]  [0]  [✓]           │     │
│     └─────────────────────────────┘     │
│                                         │
└─────────────────────────────────────────┘
```

**States:**
- Default: User grid visible, PIN pad visible
- User selected: Selected card highlighted (primary color border)
- PIN entered: Dots filled progressively
- Loading: PIN pad disabled, loading indicator
- Error: Shake animation, error message, dots reset
- Success: Checkmark animation, navigate to home

**Animations:**
- User card selection: scale 0.95 → 1.0 (100ms)
- PIN dot fill: scale bounce (150ms)
- Error shake: horizontal oscillation (300ms, 3 cycles)
- Success: checkmark scale + fade (200ms)

### 3.2 Order Screen (Kasir Mode)

**Route:** `/order`  
**Access:** Authenticated (Kasir & Owner)

```
┌─────────────────────────────────────────┐
│ [≡] Order Baru              [👤 Owner] │  ← Drawer menu, user avatar
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────┐ ┌──────────┐ ┌────────┐│
│  │  Manis   │ │  Telur   │ │ Tipis  ││  ← Category tabs
│  └──────────┘ └──────────┘ └────────┘│
│                                         │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  │   🥞    │ │   🥞    │ │   🥞    │  │
│  │ Manis   │ │ Manis   │ │ Manis   │  │
│  │ Coklat  │ │ Coklat  │ │ Keju    │  │
│  │ Rp 25k  │ │ Keju    │ │ Rp 28k  │  │
│  │         │ │ Rp 30k  │ │         │  │
│  │  [ + ]  │ │  [ + ]  │ │  [ + ]  │  │
│  └─────────┘ └─────────┘ └─────────┘  │
│                                         │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  │   🥞    │ │   🥞    │ │   🥞    │  │
│  │ Manis   │ │ Telur   │ │ Telur   │  │
│  │ Susu    │ │ Biasa   │ │ Spesial │  │
│  │ Rp 22k  │ │ Rp 20k  │ │ Rp 25k  │  │
│  │         │ │         │ │         │  │
│  │  [ + ]  │ │  [ + ]  │ │  [ + ]  │  │
│  └─────────┘ └─────────┘ └─────────┘  │
│                                         │
├─────────────────────────────────────────┤
│  [🛒 2 items]           Total: Rp 75.000│  ← Cart bar (sticky bottom)
│  [        Bayar Sekarang        ]        │  ← Primary CTA button
└─────────────────────────────────────────┘
```

**Cart Bottom Sheet (on tap cart bar):**
```
┌─────────────────────────────────────────┐
│  ─────  (drag handle)                   │
│                                         │
│  🛒 Orderan                    [Clear] │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │ 1x Martabak Manis Coklat           ││
│  │                           Rp 25.000 ││
│  │ [ - ]  1  [ + ]     [ 🗑️ ]        ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │ 2x Martabak Telur Spesial          ││
│  │                           Rp 50.000 ││
│  │ [ - ]  2  [ + ]     [ 🗑️ ]        ││
│  └─────────────────────────────────────┘│
│                                         │
│  📝 Catatan:                           │
│  ┌─────────────────────────────────────┐│
│  │ Extra keju, gak pedes...            ││
│  └─────────────────────────────────────┘│
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  💳 Metode Pembayaran                   │
│  ┌───────────────┐ ┌───────────────┐   │
│  │   📱 GoQris   │ │   💵 Tunai    │   │
│  │     (●)       │ │     ( )       │   │
│  └───────────────┘ └───────────────┘   │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │      Bayar Sekarang — Rp 75.000    ││  ← Total dalam button
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

**States:**
- Empty cart: "Belum ada item. Tap menu untuk menambahkan."
- Items in cart: List items with qty controls
- Payment method selected: Toggle highlight
- Submitting: Button shows loading, inputs disabled
- Error: Snackbar with error message

**Animations:**
- Menu card tap: scale 0.95 → 1.0 + ripple (100ms)
- Add to cart: card bounces, cart badge increments
- Qty change: number slides up/down (150ms)
- Remove item: slide out left + fade (200ms)
- Bottom sheet: slide up with spring physics

### 3.3 QR Display Screen

**Route:** `/order/qr/:id`  
**Access:** Authenticated

```
┌─────────────────────────────────────────┐
│ [←] Detail Order                       │
├─────────────────────────────────────────┤
│                                         │
│         ┌───────────────┐              │
│         │               │              │
│         │    ┌───┐     │              │
│         │    │QR │     │              │  ← QR Code (250x250dp)
│         │    │   │     │              │
│         │    └───┘     │              │
│         │               │              │
│         └───────────────┘              │
│                                         │
│     Scan QRIS untuk pembayaran          │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  Total        Rp 75.000            ││
│  │  Ref         INV-20260731-001      ││
│  │  Metode      GoQris QRIS           ││
│  │  Kadaluarsa  14:47:30              ││  ← Countdown timer
│  └─────────────────────────────────────┘│
│                                         │
│  ⏳ Menunggu pembayaran...              │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │        [ Batalkan Order ]          ││
│  └─────────────────────────────────────┘│
│                                         │
└─────────────────────────────────────────┘
```

**After Payment Success:**
```
┌─────────────────────────────────────────┐
│                                         │
│           ✓                             │  ← Animated checkmark
│                                         │
│      Pembayaran Berhasil!               │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  Total        Rp 75.000            ││
│  │  Ref         INV-20260731-001      ││
│  │  Metode      GoQris QRIS           ││
│  │  Dibayar     14:46:23              ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │      [ Order Baru ]                ││
│  └─────────────────────────────────────┘│
│                                         │
└─────────────────────────────────────────┘
```

**After Expired:**
```
┌─────────────────────────────────────────┐
│                                         │
│           ⏰                             │
│                                         │
│       QR Kadaluarsa!                    │
│                                         │
│  QR ini sudah tidak dapat digunakan.     │
│  Silakan buat order baru.               │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │      [ Order Baru ]                ││
│  └─────────────────────────────────────┘│
│                                         │
└─────────────────────────────────────────┘
```

**States:**
- Loading: Skeleton placeholder for QR
- QR Generated: Show QR with countdown
- Polling: Check payment status every 5 seconds
- Paid: Success animation, show receipt
- Expired: Show expired state, option to reorder
- Cancelled: Show cancelled state

**Animations:**
- QR appear: fade in + scale (300ms)
- Countdown: pulse animation when < 1 minute
- Success: confetti + checkmark scale
- Expired: fade to gray + clock icon

### 3.4 Queue Screen

**Route:** `/queue`  
**Access:** Authenticated (Shared view)

```
┌─────────────────────────────────────────┐
│ [≡] Antrian                  [↻ Auto] │  ← Auto-refresh toggle
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────────┐│
│  │ 🔵 PENDING                          ││  ← Status header
│  ├─────────────────────────────────────┤│
│  │ INV-20260731-001         14:46:23   ││
│  │ 1x Manis Coklat, 2x Telur Biasa    ││
│  │ Rp 75.000 — Budi                   ││
│  │ [Lunas]  [Batalkan] (owner only)   ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │ 🟢 LUNAS                            ││  ← Status header
│  ├─────────────────────────────────────┤│
│  │ INV-20260731-002         14:45:10   ││
│  │ 1x Manis Susu                      ││
│  │ Rp 22.000 — Andi                   ││
│  │ [✓ Lunas 14:46:23]                 ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │ INV-20260731-003         14:44:55   ││
│  │ 3x Telur Spesial                   ││
│  │ Rp 75.000 — Budi                   ││
│  │ [Lunas]  [Batalkan] (owner only)   ││
│  └─────────────────────────────────────┘│
│                                         │
│  Auto-refresh: ON (10s)                 │
│                                         │
└─────────────────────────────────────────┘
```

**States:**
- Empty: "Tidak ada order aktif"
- Loading: Shimmer skeleton
- Has items: List grouped by status
- Refreshing: Pull-to-refresh indicator

### 3.5 History Screen

**Route:** `/history`  
**Access:** Authenticated

```
┌─────────────────────────────────────────┐
│ [≡] Riwayat                 [📅 Filter]│
├─────────────────────────────────────────┤
│                                         │
│  📅 31 Juli 2026  [◀] [▶]             │  ← Date picker
│                                         │
│  ┌─────────────────────────────────────┐│
│  │ INV-20260731-001         14:46:23   ││
│  │ 1x Manis Coklat, 2x Telur Biasa    ││
│  │ Rp 75.000 — 💵 Tunai              ││
│  │ [✓ Lunas]                         ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │ INV-20260731-002         14:45:10   ││
│  │ 1x Manis Susu                      ││
│  │ Rp 22.000 — 📱 GoQris             ││
│  │ [✓ Lunas 14:46:23]                ││
│  └─────────────────────────────────────┘│
│                                         │
│  ─────────────────────────────────────  │
│  Total Hari Ini: Rp 97.000 (2 order)   │
│                                         │
└─────────────────────────────────────────┘
```

**Owner View (all kasirs):**
- Filter by kasir (dropdown)
- Filter by status (all/paid/pending/expired/cancelled)
- Summary header shows all kasirs combined

### 3.6 Dashboard (Owner Mode)

**Route:** `/dashboard`  
**Access:** Owner only

```
┌─────────────────────────────────────────┐
│ [≡] Dashboard                [👤 Owner] │
├─────────────────────────────────────────┤
│                                         │
│  📊 Hari Ini — 31 Juli 2026            │
│                                         │
│  ┌───────────────┐ ┌───────────────┐   │
│  │      47       │ │   Rp 1.235.000│   │
│  │  Transaksi   │ │  Pemasukan   │   │
│  └───────────────┘ └───────────────┘   │
│                                         │
│  ┌───────────────┐ ┌───────────────┐   │
│  │     26.277    │ │      45       │   │
│  │  Rata-rata   │ │    Lunas     │   │
│  └───────────────┘ └───────────────┘   │
│                                         │
│  ┌───────────────┐ ┌───────────────┐   │
│  │       1       │ │       1       │   │
│  │   Pending    │ │   Expired    │   │
│  └───────────────┘ └───────────────┘   │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  🍽️ Top Menu Hari Ini                   │
│  ┌─────────────────────────────────────┐│
│  │ 1. 🥞 Martabak Manis Coklat  18x   ││
│  │ 2. 🥞 Martabak Telur Biasa   12x   ││
│  │ 3. 🥞 Martabak Manis Keju    10x   ││
│  └─────────────────────────────────────┘│
│                                         │
│  👥 Performa Kasir                     │
│  ┌─────────────────────────────────────┐│
│  │ Budi    │  28 tx  │  Rp 745.000    ││
│  │ Andi    │  19 tx  │  Rp 490.000    ││
│  └─────────────────────────────────────┘│
│                                         │
└─────────────────────────────────────────┘
```

### 3.7 Reports Screen

**Route:** `/reports`  
**Access:** Owner only

```
┌─────────────────────────────────────────┐
│ [≡] Laporan                  [📅 Periode]│
├─────────────────────────────────────────┤
│                                         │
│  📊 Laporan Profit — Juli 2026          │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  Dari: 2026-07-01                   ││
│  │  Ke:   2026-07-31                   ││
│  │  [Terapkan]                         ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │         📈 RINGKASAN                ││
│  ├─────────────────────────────────────┤│
│  │  Total Penjualan    Rp 38.500.000  ││
│  │  Total Biaya         Rp 15.200.000  ││
│  │  ────────────────────────────────  ││
│  │  LABA/RUGI          Rp 23.300.000  ││  ← Highlighted
│  └─────────────────────────────────────┘│
│                                         │
│  📋 Detail Per Entri                    │
│  ┌─────────────────────────────────────┐│
│  │ 28-30 Jul │ Biaya: Rp 168.000      ││
│  │            │ Penjualan: Rp 500.000 ││
│  │            │ Profit: Rp 332.000 ✓  ││
│  ├─────────────────────────────────────┤│
│  │ 25-27 Jul │ Biaya: Rp 450.000      ││
│  │            │ Penjualan: Rp 1.200.000││
│  │            │ Profit: Rp 750.000 ✓  ││
│  └─────────────────────────────────────┘│
│                                         │
│  [+ Tambah Entri Biaya]                 │
│                                         │
└─────────────────────────────────────────┘
```

### 3.8 Settings Screen

**Route:** `/settings`  
**Access:** Owner only

```
┌─────────────────────────────────────────┐
│ [←] Pengaturan                         │
├─────────────────────────────────────────┤
│                                         │
│  🏪 Info Toko                          │
│  ┌─────────────────────────────────────┐│
│  │  Nama Toko                          ││
│  │  Martabak Pak Harto           [✏️]││
│  └─────────────────────────────────────┘│
│                                         │
│  📱 GoQris QRIS                        │
│  ┌─────────────────────────────────────┐│
│  │  Status: ● Aktif                   ││
│  │  Plan: Free Plan (3/5 transaksi)  ││
│  │  Project: Martabak Pak Harto       ││
│  │                                   ││
│  │  [ Konfigurasi Ulang ]            ││
│  └─────────────────────────────────────┘│
│                                         │
│  👥 Kelola Kasir                       │
│  ┌─────────────────────────────────────┐│
│  │  Budi           [ Reset PIN ] [✏️] ││
│  │  Andi           [ Reset PIN ] [✏️] ││
│  │  [+ Tambah Kasir ]                ││
│  └─────────────────────────────────────┘│
│                                         │
│  🍽️ Kelola Menu                        │
│  ┌─────────────────────────────────────┐│
│  │  [+ Tambah Menu ]                 ││
│  │  [ Lihat Semua Menu ]             ││
│  └─────────────────────────────────────┘│
│                                         │
└─────────────────────────────────────────┘
```

---

## 4. Component Specifications

### 4.1 Buttons

**Primary Button:**
```dart
// Use for: Main CTAs (Bayar Sekarang, Simpan)
// Style:
- Background: primary (#D2691E)
- Text: white, labelLarge (14sp, SemiBold)
- Padding: horizontal 24dp, vertical 14dp
- Border radius: 12dp
- Min height: 48dp
- Min width: 120dp

// States:
// Default: primary background
// Pressed: primaryDark background + scale 0.98
// Disabled: 50% opacity
// Loading: circular progress indicator (white)
```

**Secondary Button:**
```dart
// Use for: Secondary actions (Batal, Kembali)
// Style:
- Background: transparent
- Border: 1.5dp primary color
- Text: primary color, labelLarge
- Padding: horizontal 24dp, vertical 14dp
- Border radius: 12dp

// States:
// Default: transparent background, primary border
// Pressed: primaryLight background + scale 0.98
// Disabled: 50% opacity
```

**Text Button:**
```dart
// Use for: Tertiary actions (Lihat Selengkapnya)
// Style:
- Background: transparent
- Text: primary color, labelLarge
- No border, no padding

// States:
// Default: primary text
// Pressed: primaryDark text
```

**Danger Button:**
```dart
// Use for: Destructive actions (Batalkan)
// Style:
- Background: error (#E53935)
- Text: white, labelLarge
- Same sizing as Primary

// States:
// Default: error background
// Pressed: darker red
```

### 4.2 Cards

**Menu Card:**
```dart
// Size: Flexible (grid item, 2 columns)
// Padding: 12dp
// Border radius: 16dp
// Elevation: 2dp
// Background: white

// Layout:
// [emoji 32dp]          ← Top, centered
// [name]                ← Center, titleMedium
// [price]               ← Bottom, priceMedium
// [add button]          ← Bottom, full width

// States:
// Default: white background, elevation 2
// Pressed: scale 0.98, elevation 1
// Disabled: 50% opacity
```

**Order Card (Queue/History):**
```dart
// Full width
// Padding: 16dp
// Border radius: 12dp
// Elevation: 1dp

// Layout:
// [ref_id]                    ← refId style, top-left
// [time]                      ← bodySmall, top-right
// [items summary]             ← bodyMedium, center
// [total + kasir + method]    ← bodyMedium, bottom
// [status badge + actions]    ← bottom-right

// Status colors:
// Pending: warning (#FF9800) background
// Paid: success (#4CAF50) background
// Expired: error (#E53935) background
// Cancelled: gray (#9E9E9E) background
```

### 4.3 Input Fields

**Text Field:**
```dart
// Height: 56dp
// Border radius: 12dp
// Border: 1.5dp, surfaceVariant

// States:
// Default: surfaceVariant border
// Focused: primary border (2dp)
// Error: error border + error text below
// Disabled: 50% opacity

// Label: bodySmall, positioned above
// Hint: bodyMedium, textHint color
// Input: bodyLarge, textPrimary
```

**PIN Input:**
```dart
// 6 dots, horizontal
// Dot size: 16dp diameter
// Gap: 12dp between dots
// Empty: border only (surfaceVariant)
// Filled: filled primary

// Animation: scale bounce on fill
```

### 4.4 Bottom Navigation

```dart
// Height: 64dp + safe area
// Background: white
// Elevation: 4dp
// Icon size: 24dp
// Label: labelMedium (12sp)

// Items: 4 for Kasir, 7 for Owner
// Active: primary color, filled icon
// Inactive: textSecondary, outlined icon

// Animation:
// Active indicator: pill shape behind icon
// Transition: 200ms ease-in-out
```

### 4.5 Loading States

**Shimmer Skeleton:**
```dart
// Use for: Initial load
// Color: surfaceVariant → white → surfaceVariant
// Duration: 1.5s
// Direction: left to right

// Shapes:
// Card skeleton: 16dp border radius
// List skeleton: 8dp border radius
// Circle skeleton: for avatars
```

**Circular Progress:**
```dart
// Use for: Button loading, small loads
// Size: 24dp (inline), 48dp (standalone)
// Color: primary
// Stroke: 2.5dp
```

**Linear Progress:**
```dart
// Use for: Progress bars
// Height: 4dp
// Border radius: 2dp
// Background: surfaceVariant
// Progress: primary
```

### 4.6 Empty States

```dart
// Icon: 64dp, textHint color
// Title: titleMedium, textPrimary
// Description: bodyMedium, textSecondary
// Action: optional secondary button

// Spacing: 16dp between elements
// Padding: 32dp horizontal
```

### 4.7 Error States

```dart
// Icon: 48dp, error color
// Title: titleMedium, error color
// Description: bodyMedium, textSecondary
// Action: primary button (Retry)

// Snackbar for minor errors:
// Background: error
// Text: white
// Duration: 4s
// Action: optional retry button
```

---

## 5. Navigation Patterns

### 5.1 Navigation Structure

**Kasir Mode:**
```
/login
└── /order (tab 0)
    └── /order/qr/:id
└── /queue (tab 1)
└── /history (tab 2)
    └── /history/:id
└── /profile (tab 3)
    └── /profile/change-pin
```

**Owner Mode:**
```
/login
└── /dashboard (tab 0)
└── /order (tab 1)
    └── /order/qr/:id
└── /queue (tab 2)
└── /history (tab 3)
    └── /history/:id
└── /menu (tab 4)
    └── /menu/edit/:id
    └── /menu/add
└── /kasir (tab 5)
    └── /kasir/add
    └── /kasir/edit/:id
└── /reports (tab 6)
    └── /reports/daily
    └── /reports/profit
└── /settings (tab 7)
    └── /settings/goqris
```

### 5.2 Transition Animations

| Transition | Animation |
|-------------|-----------|
| Screen push | Slide in from right (300ms) |
| Screen pop | Slide out to right (300ms) |
| Modal open | Slide up from bottom (300ms) |
| Modal close | Slide down (250ms) |
| Tab switch | Fade crossfade (200ms) |
| Bottom sheet | Spring physics slide up |

### 5.3 Back Navigation

- **App Bar back button:** Standard, navigates back
- **System back button:** Same as app bar back
- **Deep link:** Handled by GoRouter

---

## 6. State Management

### 6.1 BLoC Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      PRESENTATION                        │
│                                                         │
│  Screen/Widget                                          │
│       │                                                 │
│       │ reads/triggers                                  │
│       ▼                                                 │
│  ┌─────────┐  emits  ┌─────────┐  updates  ┌─────────┐ │
│  │  Event  │────────▶│   BLoC   │─────────▶│  State  │ │
│  └─────────┘         └─────────┘           └─────────┘ │
│                           │                           │
│                           │ calls                      │
│                           ▼                           │
│                    ┌─────────────┐                    │
│                    │ Repository  │                    │
│                    └─────────────┘                    │
│                           │                           │
│                           │ implements                │
│                           ▼                           │
│                    ┌─────────────┐                    │
│                    │   Service   │                    │
│                    └─────────────┘                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 6.2 Global BLoCs

| BLoC | Scope | Purpose |
|------|-------|---------|
| `AuthBloc` | Global | Session management, login/logout |
| `ThemeBloc` | Global | Theme preferences |

### 6.3 Feature BLoCs

| Feature | BLoC | States |
|---------|------|--------|
| Auth | `AuthBloc` | Initial, Loading, Authenticated, Unauthenticated, Error |
| Menu | `MenuBloc` | Initial, Loading, Loaded, Error |
| Order | `OrderBloc` | Initial, Cart, Submitting, QrGenerated, Paid, Expired, Error |
| Queue | `QueueBloc` | Initial, Loading, Loaded, Error |
| History | `HistoryBloc` | Initial, Loading, Loaded, Error |
| Reports | `ReportsBloc` | Initial, Loading, Loaded, Error |
| Settings | `SettingsBloc` | Initial, Loading, Loaded, Saving, Error |

### 6.4 Polling Strategy

**Order Payment Status:**
```dart
// Polling interval: 5 seconds
// Stop conditions:
// - status == 'paid' → show success
// - status == 'expired' → show expired
// - status == 'cancelled' → show cancelled
// - Max retries: 180 (15 minutes)
// - On app background: pause polling
// - On app foreground: resume polling
```

**Queue Auto-refresh:**
```dart
// Interval: 10 seconds (configurable)
// Toggle: User can enable/disable
// Manual refresh: Pull-to-refresh
```

---

## 7. Interaction Patterns

### 7.1 Gestures

| Gesture | Element | Action |
|---------|---------|--------|
| Tap | Menu card | Add to cart (+1 qty) |
| Long press | Menu card | Open qty picker dialog |
| Swipe left | Cart item | Reveal delete action |
| Pull down | List | Refresh |
| Tap outside | Bottom sheet | Dismiss |

### 7.2 Animations

**Micro-interactions:**
```dart
// Button press: scale 0.98 (100ms)
// Card tap: ripple + scale 0.98 (100ms)
// Add to cart: bounce animation
// Remove from cart: slide out left (200ms)
// Tab switch: crossfade (200ms)

// Transitions:
// Screen push: slide right (300ms)
// Modal: slide up (300ms)
// Bottom sheet: spring physics
```

**Loading States:**
```dart
// Initial load: shimmer skeleton
// Action pending: button spinner
// Background task: linear progress
// Success: checkmark pop
// Error: shake + snackbar
```

### 7.3 Haptic Feedback

```dart
// Light impact: Button tap
// Medium impact: Add to cart
// Selection: Tab switch
// Success: Payment confirmed
// Error: Validation failed
```

### 7.4 Error Handling

| Error Type | UI Response |
|------------|-------------|
| Network error | Snackbar + retry option |
| API error (4xx) | Error message from API |
| API error (5xx) | "Server error. Coba lagi." |
| Validation error | Inline field error |
| Session expired | Navigate to login |

---

## 8. Accessibility

### 8.1 Touch Targets
- Minimum: 48x48dp
- Recommended: 56x56dp for primary actions

### 8.2 Text Scaling
- Support system font scaling up to 200%
- Test layouts at 1.0x, 1.3x, 1.5x, 2.0x

### 8.3 Color Contrast
- Primary text: WCAG AA (4.5:1 ratio)
- Secondary text: WCAG AA (4.5:1 ratio)
- Large text: WCAG AA (3:1 ratio)

### 8.4 Screen Reader
- Semantic labels on all interactive elements
- Announce state changes (loading, success, error)

---

## 9. Performance Targets

| Metric | Target |
|--------|--------|
| Cold start | < 2 seconds |
| Screen transition | < 300ms |
| API call (network) | < 3 seconds (with loading indicator) |
| Frame rate | 60fps |
| Memory usage | < 150MB |
| APK size | < 20MB |

---

## 10. Implementation Checklist

### 10.1 Core Setup
- [ ] Flutter project scaffold
- [ ] Dependencies setup (pubspec.yaml)
- [ ] Clean Architecture folder structure
- [ ] Theme configuration
- [ ] Navigation setup (GoRouter)
- [ ] API client setup (Dio)

### 10.2 Shared Components
- [ ] AppButton (primary, secondary, text, danger)
- [ ] AppCard
- [ ] AppTextField
- [ ] LoadingIndicator (shimmer, circular)
- [ ] ErrorWidget
- [ ] EmptyState
- [ ] PinInput

### 10.3 Feature: Auth
- [ ] LoginScreen
- [ ] UserGrid widget
- [ ] PinKeypad widget
- [ ] AuthBloc

### 10.4 Feature: Order
- [ ] OrderScreen
- [ ] MenuGrid
- [ ] MenuCard
- [ ] CartSheet
- [ ] QrDisplayScreen
- [ ] OrderBloc

### 10.5 Feature: Queue
- [ ] QueueScreen
- [ ] QueueItemCard
- [ ] QueueBloc

### 10.6 Feature: History
- [ ] HistoryScreen
- [ ] HistoryBloc

### 10.7 Feature: Dashboard (Owner)
- [ ] DashboardScreen
- [ ] StatCard widget
- [ ] ReportsBloc

### 10.8 Feature: Menu Management (Owner)
- [ ] MenuListScreen
- [ ] MenuFormScreen
- [ ] MenuBloc

### 10.9 Feature: Kasir Management (Owner)
- [ ] KasirListScreen
- [ ] KasirFormScreen
- [ ] KasirBloc

### 10.10 Feature: Reports (Owner)
- [ ] ReportsScreen
- [ ] DailyReportScreen
- [ ] ProfitReportScreen

### 10.11 Feature: Settings (Owner)
- [ ] SettingsScreen
- [ ] SettingsBloc

### 10.12 Polish
- [ ] Animations
- [ ] Haptic feedback
- [ ] Error handling
- [ ] Loading states
- [ ] Empty states
- [ ] Accessibility

---

## Appendix A: Dependencies Reference

```yaml
# State Management
flutter_bloc: ^9.0.0
equatable: ^2.0.7

# Networking
dio: ^5.7.0

# Storage
flutter_secure_storage: ^9.2.2

# QR
qr_flutter: ^4.1.0

# UI
shimmer: ^3.0.0
flutter_animate: ^4.5.2
badges: ^3.1.2

# Typography
google_fonts: ^6.2.1

# Utilities
intl: ^0.20.1

# Navigation
go_router: ^14.6.0
```

---

## Appendix B: Color Reference (Hex)

```dart
// Primary
const primary = 0xFFD2691E;
const primaryLight = 0xFFE8A665;
const primaryDark = 0xFF8B4513;

// Secondary
const secondary = 0xFFFFC107;
const secondaryLight = 0xFFFFD54F;
const secondaryDark = 0xFFFFA000;

// Neutrals
const background = 0xFFFFF8F0;
const surface = 0xFFFFFFFF;
const surfaceVariant = 0xFFF5F0E8;

// Text
const textPrimary = 0xFF2D1B0E;
const textSecondary = 0xFF5D4037;
const textHint = 0xFF8D6E63;

// Semantic
const success = 0xFF4CAF50;
const error = 0xFFE53935;
const warning = 0xFFFF9800;
const info = 0xFF2196F3;
```

---

**Last Updated:** 2026-07-31  
**Author:** Mavis (Documentation Agent)  
**Version:** 1.0.0
