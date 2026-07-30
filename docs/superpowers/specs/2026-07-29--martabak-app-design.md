# App Martabak dengan Pembayaran GoQris — Design Spec

**Tanggal:** 2026-07-29
**Status:** Draft (menunggu approval user)
**Author:** Mavis (brainstorming session)
**Target implementasi:** droid CLI / opencode CLI

---

## 1. Ringkasan

Aplikasi kasir mobile untuk lapak martabak dengan integrasi pembayaran:
- **GoQris QRIS** - Pembayaran dengan scan QR via GoQris
- **Cash (Tunai)** - Pembayaran langsung dengan uang tunai

Alur GoQris: pembeli datang → pilih menu dari daftar fisik → kasir input di app → pilih metode pembayaran → (Kalau GoQris) QRIS muncul di layar → pembeli scan & bayar dari HP-nya sendiri → status lunas otomatis.

Alur Cash: pembeli datang → pilih menu dari daftar fisik → kasir input di app → pilih metode pembayaran → (Kalau Cash) langsung terbayar → status lunas.

**Tujuan utama:**
- Menggantikan pencatatan manual / kalkulator → digital + terstruktur
- Mempercepat transaksi (pembeli scan sendiri, kasir tinggal tunggu)
- Memberi visibility ke owner tanpa harus memegang device kasir
- Showcase portfolio (deploy ke VPS dengan subdomain)

**Target pengguna:**
- 1 owner (pemilik lapak)
- 1-3 kasir (karyawan)
- ~50-200 transaksi per hari
- Single outlet (bukan multi-cabang di MVP)

---

## 2. Goals & Non-Goals

### Goals (MVP)
- ✅ Input order cepat (kategori → menu → qty → catatan)
- ✅ 2 Metode pembayaran: GoQris QRIS + Cash (Tunai)
- ✅ Generate QRIS dinamis via GoQris (hanya jika metode = GoQris)
- ✅ Auto-detect pembayaran GoQris (polling)
- ✅ Antrian shared (semua kasir bisa lihat pesanan aktif)
- ✅ Riwayat per kasir (personal)
- ✅ Laporan harian (rekap, top menu, performa kasir, filter tanggal)
- ✅ Laporan profit (pendapatan - biaya bahan baku per periode)
- ✅ Input manual biaya bahan baku (nama, qty, harga per unit)
- ✅ Owner mode: kelola menu, kasir, pengaturan
- ✅ Auth via PIN (4-6 digit)
- ✅ Deploy di VPS dengan subdomain + SSL

### Non-Goals (Post-MVP / di-skip)
- ❌ Aplikasi sisi pembeli (self-order)
- ❌ Multiple payment method lain selain GoQris dan Cash
- ❌ Variasi menu terstruktur (topping picker, level kepedasan)
- ❌ Catatan pesanan terstruktur (cuma 1 text field bebas)
- ❌ Print struk thermal
- ❌ Kirim struk via WhatsApp
- ❌ Chart interaktif / export PDF/Excel
- ❌ Multi-bahasa (Indonesia saja)
- ❌ Multi-outlet / multi-tenant
- ❌ Upload foto menu (cuma emoji/icon)
- ❌ Real-time push (WebSocket) — pakai polling
- ❌ Custom branding per lapak

---

## 3. Personas

| Persona | Akses | Device | Goal |
|---|---|---|---|
| **Budi (Kasir)** | Login PIN kasir | HP/tablet di lapak | Input order cepat, lihat antrian |
| **Andi (Kasir)** | Login PIN kasir | HP/tablet di lapak | Sama seperti Budi |
| **Pak Hartono (Owner)** | Login PIN owner | HP/tablet | Review laporan, atur menu, tambah kasir, lihat semua transaksi |

**Pembeli** bukan user app — mereka hanya scan QRIS dari layar device kasir menggunakan aplikasi bank/e-wallet mereka sendiri.

---

## 4. Arsitektur High-Level

```
┌──────────────────────────────────────────────────────────┐
│                    USER LAYER                            │
│                                                          │
│  👤 Pembeli                  👨‍🍳 Kasir/Owner          │
│  (lihat menu fisik)          (pegang HP/tablet)         │
│  scan QRIS                  ┌──────────────┐           │
│      │                      │ Flutter App  │           │
│      │                      │ (Android/iOS)│           │
│      │                      └──────┬───────┘           │
└──────┼──────────────────────────────┼───────────────────┘
       │                              │ HTTPS
       │                              ▼
       │                      ┌──────────────┐
       │                      │  VPS Ubuntu  │
       │                      │ ┌──────────┐ │
       │                      │ │  Nginx   │ │ ← SSL + reverse proxy
       │                      │ └────┬─────┘ │
       │                      │      ▼       │
       │                      │ ┌──────────┐ │
       │                      │ │Gunicorn  │ │
       │                      │ └────┬─────┘ │
       │                      │      ▼       │
       │                      │ ┌──────────┐ │
       │                      │ │Django+DRF│ │ ← app.domainmu.com
       │                      │ └────┬─────┘ │
       │                      │      ▼       │
       │                      │ ┌──────────┐ │
       │                      │ │PostgreSQL│ │
       │                      │ └──────────┘ │
       │                      └──────┬───────┘
       │                             │ HTTPS (out)
       │                             ▼
       │                      ┌──────────────┐
       └─────────────────────►│   GoQris API │
                              │  (QRIS +     │
                              │  settlement) │
                              └──────────────┘
```

### Tech Stack

| Layer | Pilihan | Alasan |
|---|---|---|
| Frontend | Flutter (Dart) | Single codebase Android+iOS, cepat untuk UI mobile |
| Backend | Django 5.x + DRF | Admin backdoor built-in, DRF best-in-class untuk REST, batteries-included |
| Database | PostgreSQL 16 | Production-grade, multi-user concurrent, JSON support |
| WSGI | Gunicorn | Stabil, banyak worker, battle-tested |
| Reverse Proxy | Nginx | SSL, static files, rate limiting |
| OS | Ubuntu 22.04 LTS | Stabil, dokumentasi luas |
| CI/CD | Manual via SSH | MVP, gak perlu GitHub Actions dulu |
| API Payment | GoQris | Sesuai requirement user |

---

## 5. Database Schema

```
┌──────────────────────────────────────────────────────────┐
│ kasirs                                                   │
├──────────────────────────────────────────────────────────┤
│ id            BIGSERIAL PK                                │
│ name          VARCHAR(100) NOT NULL                       │
│ pin_hash      VARCHAR(255) NOT NULL  ← hash PIN          │
│ role          VARCHAR(20) NOT NULL  ← 'kasir' | 'owner'  │
│ is_active     BOOLEAN DEFAULT TRUE                       │
│ created_at    TIMESTAMPTZ DEFAULT NOW()                  │
│ updated_at    TIMESTAMPTZ DEFAULT NOW()                  │
└──────────────────────────────────────────────────────────┘
                       │ 1
                       │
                       ▼ N
┌──────────────────────────────────────────────────────────┐
│ orders                                                   │
├──────────────────────────────────────────────────────────┤
│ id            BIGSERIAL PK                                │
│ ref_id        VARCHAR(50) UNIQUE  ← "INV-20260729-001"   │
│ kasir_id      BIGINT FK → kasirs.id  (NOT NULL)          │
│ total_amount  BIGINT NOT NULL  ← dalam rupiah            │
│ status        VARCHAR(20) NOT NULL  ← enum:              │
│                  'pending' | 'paid' | 'expired' |        │
│                  'cancelled'                              │
│ payment_method VARCHAR(20) DEFAULT 'goqris'               │
│               ← 'goqris' | 'cash'                       │
│ payment_method_label VARCHAR(50) DEFAULT ''                │
│               ← 'GoQris QRIS' | 'Tunai'                  │
│ qr_string     TEXT  ← dari GoQris response (goqris only) │
│ qr_image_url  TEXT  ← opsional, kalau GoQris return URL  │
│ expires_at    TIMESTAMPTZ (goqris only)                  │
│ paid_at       TIMESTAMPTZ NULL                           │
│ note          TEXT NULL  ← catatan bebas dari kasir      │
│ goqris_data   JSONB  ← raw response GoQris (audit)        │
│ created_at    TIMESTAMPTZ DEFAULT NOW()                  │
│ updated_at    TIMESTAMPTZ DEFAULT NOW()                  │
│                                                          │
│ INDEX: (status, created_at DESC)                         │
│ INDEX: (kasir_id, created_at DESC)                       │
│ INDEX: (created_at)                                      │
└──────────────────────────────────────────────────────────┘
                       │ 1
                       │
                       ▼ N
┌──────────────────────────────────────────────────────────┐
│ order_items                                              │
├──────────────────────────────────────────────────────────┤
│ id            BIGSERIAL PK                                │
│ order_id      BIGINT FK → orders.id  (NOT NULL)          │
│ menu_id       BIGINT FK → menus.id  (NOT NULL)           │
│ qty           INTEGER NOT NULL  CHECK (qty > 0)          │
│ price_at_order BIGINT NOT NULL  ← snapshot harga saat itu │
│ subtotal      BIGINT NOT NULL  ← qty * price_at_order    │
└──────────────────────────────────────────────────────────┘
                       │
                       │ N
                       │
                       ▼ 1
┌──────────────────────────────────────────────────────────┐
│ menus                                                    │
├──────────────────────────────────────────────────────────┤
│ id            BIGSERIAL PK                                │
│ name          VARCHAR(100) NOT NULL                       │
│ price         BIGINT NOT NULL  ← dalam rupiah            │
│ category      VARCHAR(50)  ← 'manis' | 'telur' | 'tipis' │
│ emoji         VARCHAR(10)  ← 🥞 untuk display di app    │
│ is_active     BOOLEAN DEFAULT TRUE                       │
│ sort_order    INTEGER DEFAULT 0                           │
│ created_at    TIMESTAMPTZ DEFAULT NOW()                  │
│ updated_at    TIMESTAMPTZ DEFAULT NOW()                  │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ settings  (singleton row, id=1)                          │
├──────────────────────────────────────────────────────────┤
│ id            INTEGER PK DEFAULT 1                       │
│ nama_lapak    VARCHAR(100) NOT NULL                       │
│ goqris_apikey VARCHAR(255) NOT NULL  ← encrypted at rest │
│ goqris_project_name VARCHAR(100) NOT NULL                │
│ updated_at    TIMESTAMPTZ DEFAULT NOW()                  │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ material_items (master list nama bahan)                  │
├──────────────────────────────────────────────────────────┤
│ id            BIGSERIAL PK                              │
│ name          VARCHAR(100) NOT NULL  ← bebas (owner isi) │
│ is_active     BOOLEAN DEFAULT TRUE                      │
│ created_at    TIMESTAMPTZ                               │
│ updated_at    TIMESTAMPTZ                               │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ material_cost_entries (input cost per periode)           │
├──────────────────────────────────────────────────────────┤
│ id            BIGSERIAL PK                              │
│ date_from     DATE NOT NULL                            │
│ date_to       DATE NOT NULL                            │
│ total_cost    INTEGER  ← calculated from items          │
│ total_revenue INTEGER  ← calculated from orders         │
│ profit        INTEGER  ← total_revenue - total_cost      │
│ notes         TEXT NULL                                 │
│ created_by    BIGINT FK → kasirs.id                    │
│ created_at     TIMESTAMPTZ                              │
│ updated_at     TIMESTAMPTZ                               │
└──────────────────────────────────────────────────────────┘
                        │ 1
                        │
                        ▼ N
┌──────────────────────────────────────────────────────────┐
│ material_cost_items (detail per bahan)                  │
├──────────────────────────────────────────────────────────┤
│ id              BIGSERIAL PK                           │
│ cost_entry_id  BIGINT FK → material_cost_entries.id    │
│ material_name   VARCHAR(100)  ← bebas (owner ketik)   │
│ quantity        DECIMAL(10,2)                          │
│ price_per_unit  INTEGER                                │
│ subtotal        INTEGER  ← qty × price_per_unit        │
│ created_at      TIMESTAMPTZ                             │
└──────────────────────────────────────────────────────────┘
```

### Catatan Skema
- `price_at_order` di `order_items` snapshot harga, jadi kalau owner ubah harga menu besok, history order tetap akurat
- `kasir_id` di `orders` lock siapa yang create order, gak peduli nanti handover ke kasir lain
- `goqris_data` JSONB simpan raw response untuk audit/debugging
- `settings` pakai singleton pattern (satu baris saja, id=1)
- `goqris_apikey` sebaiknya di-encrypt pakai `django-cryptography` atau `django-fernet-fields` — tidak plain text

---

## 6. API Contract

Base URL: `https://app.domainmu.com/api/v1`

| Method | Endpoint | Auth | Fungsi |
|---|---|---|---|
| POST | `/auth/pin` | publik | Login PIN, return JWT |
| GET | `/me` | JWT | Info user yang sedang login |
| POST | `/auth/change-pin` | JWT | Ganti PIN sendiri |
| GET | `/menus` | JWT | List menu aktif (untuk order) |
| GET | `/menus/all` | JWT owner | List semua menu termasuk nonaktif |
| POST | `/menus` | JWT owner | Tambah menu |
| PATCH | `/menus/{id}` | JWT owner | Edit menu |
| DELETE | `/menus/{id}` | JWT owner | Soft delete (set is_active=false) |
| GET | `/orders/queue` | JWT | Antrian shared (semua kasir, status aktif) |
| GET | `/orders/me` | JWT kasir | Riwayat kasir yang login, filter ?date= |
| GET | `/orders` | JWT owner | Semua order, filter ?date=&kasir_id= |
| GET | `/orders/{id}` | JWT | Detail order |
| POST | `/orders` | JWT | Buat order + panggil GoQris |
| GET | `/orders/{id}/status` | JWT | Polling status pembayaran |
| POST | `/orders/{id}/cancel` | JWT owner | Batalkan order |
| GET | `/kasirs` | JWT owner | List kasir (termasuk nonaktif, dengan flag) |
| POST | `/kasirs` | JWT owner | Tambah kasir baru (default role='kasir', is_active=true) |
| PATCH | `/kasirs/{id}` | JWT owner | Edit kasir: name, role (kasir/owner, lihat rules), reset PIN, reactivate |
| DELETE | `/kasirs/{id}` | JWT owner | **Soft delete**: set is_active=false, history transaksi tetap utuh |
| GET | `/reports/daily?date=` | JWT owner | Rekap harian |
| GET | `/reports/top-menus?from=&to=` | JWT owner | Top N menu dalam rentang waktu |
| GET | `/reports/kasir-performance?date=` | JWT owner | Performa per kasir |
| GET | `/reports/profit?from=&to=` | JWT owner | Laporan laba rugi per periode |
| GET/POST | `/raw-materials/items/` | JWT owner | List & create material names |
| DELETE | `/raw-materials/items/{id}/` | JWT owner | Soft delete material |
| GET/POST | `/raw-materials/cost-entries/` | JWT owner | List & create cost entries |
| GET/PATCH/DELETE | `/raw-materials/cost-entries/{id}/` | JWT owner | Detail/Edit/Delete cost entry |
| GET | `/settings` | JWT owner | Lihat pengaturan |
| PATCH | `/settings` | JWT owner | Update pengaturan (nama lapak, GoQris API key) |
| GET | `/health` | publik | Health check (untuk monitoring) |

### Contoh Request/Response

**POST /auth/pin**
```json
// Request
{ "name": "Budi", "pin": "1234" }

// Response 200
{
  "token": "eyJhbGciOi...",
  "user": { "id": 2, "name": "Budi", "role": "kasir" }
}

// Response 401
{ "error": "PIN salah" }
```

**POST /orders**
```json
// Request - payment_method WAJIB
{
  "items": [
    { "menu_id": 5, "qty": 2 },
    { "menu_id": 8, "qty": 1 }
  ],
  "note": "Extra keju, gak pedes",
  "payment_method": "goqris"  // WAJIB: "goqris" atau "cash"
}

// Response 201 - GOQRIS (pending, perlu polling)
{
  "id": 42,
  "ref_id": "INV-20260729-001",
  "total_amount": 51000,
  "status": "pending",
  "payment_method": "goqris",
  "payment_method_label": "GoQris QRIS",
  "qr_string": "00020101021226580014ID.CO.QRIS.WWW...",
  "qr_image_url": "https://api.goqris.web.id/qr/abc.png",
  "expires_at": "2026-07-29T15:00:00+07:00",
  "created_at": "2026-07-29T14:45:00+07:00"
}

// Response 201 - CASH (langsung paid)
{
  "id": 43,
  "ref_id": "INV-20260729-002",
  "total_amount": 51000,
  "status": "paid",
  "payment_method": "cash",
  "payment_method_label": "Tunai",
  "qr_string": null,
  "qr_image_url": null,
  "paid_at": "2026-07-29T14:45:00+07:00",
  "created_at": "2026-07-29T14:45:00+07:00"
}
```

**GET /orders/{id}/status**
```json
// Response
{
  "ref_id": "INV-20260729-001",
  "status": "paid",
  "payment_method": "goqris",
  "payment_method_label": "GoQris QRIS",
  "total_amount": 51000,
  "is_expired": false,
  "paid_at": "2026-07-29T14:46:23+07:00"
}
```

**GET /reports/daily?date=2026-07-29**
```json
{
  "date": "2026-07-29",
  "summary": {
    "total_transaksi": 47,
    "total_pemasukan": 1235000,
    "rata_rata": 26276,
    "lunas": 45,
    "pending": 1,
    "expired": 1
  },
  "per_kasir": [
    { "kasir_id": 2, "name": "Budi", "transaksi": 28, "total": 745000 },
    { "kasir_id": 3, "name": "Andi", "transaksi": 19, "total": 490000 }
  ],
  "top_menus": [
    { "menu_id": 5, "name": "Martabak Manis Coklat Keju", "qty": 18, "total": 450000 }
  ]
}
```

**GET /reports/profit?from=2026-07-01&to=2026-07-31**
```json
{
  "date_from": "2026-07-01",
  "date_to": "2026-07-31",
  "total_cost": 4500000,
  "total_revenue": 15000000,
  "total_profit": 10500000,
  "entries": [
    {
      "id": 1,
      "date_from": "2026-07-28",
      "date_to": "2026-07-30",
      "total_cost": 168000,
      "total_revenue": 500000,
      "profit": 332000
    }
  ]
}
```

**POST /raw-materials/cost-entries/**
```json
// Request
{
  "date_from": "2026-07-28",
  "date_to": "2026-07-30",
  "items": [
    {"material_name": "Tepung", "quantity": "8", "price_per_unit": 15000},
    {"material_name": "Gula", "quantity": "4", "price_per_unit": 12000}
  ],
  "notes": "Bahan baku habis untuk periode ini"
}

// Response 201
{
  "id": 1,
  "date_from": "2026-07-28",
  "date_to": "2026-07-30",
  "items": [
    {"material_name": "Tepung", "quantity": "8", "price_per_unit": 15000, "subtotal": 120000},
    {"material_name": "Gula", "quantity": "4", "price_per_unit": 12000, "subtotal": 48000}
  ],
  "total_cost": 168000,
  "total_revenue": 500000,
  "profit": 332000,
  "notes": "Bahan baku habis untuk periode ini",
  "created_at": "2026-07-30T10:00:00+07:00"
}
```

---

## 7. Alur Data Utama: Order → Pembayaran

### Flowchart Decision Point

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                                   │
│                                                                      │
│  1. Kasir pilih menu + qty                                          │
│  2. Kasir pilih METODE PEMBAYARAN (sebelum submit)                  │
│     ├── 💰 Cash (Tunai)                                             │
│     └── 📱 GoQris (QRIS)                                           │
│  3. Kasir tekan "Bayar"                                             │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        DJANGO BACKEND                                │
│                                                                      │
│  POST /api/v1/orders/                                                │
│  Body: { items: [...], payment_method: "goqris" | "cash" }          │
│                                                                      │
│                    ┌─────────────────┬─────────────────┐             │
│                    │ payment_method  │                 │             │
│                    │ = 'cash' ?      │                 │             │
│                    └────────┬────────┘                 │             │
│                             │                          │             │
│              ┌──────────────┴──────────────┐            │             │
│              ▼                             ▼            ▼             │
│  ┌───────────────────────┐   ┌──────────────────────┐ ┌───────────┐ │
│  │ CASH                  │   │ GOQRIS               │ │ GOQRIS    │ │
│  │ status = 'paid'       │   │ Call GoQris API      │ │ fallback  │ │
│  │ paid_at = now()       │   │ status = 'pending'   │ │ status=   │ │
│  │ NO GoQris API call    │   │ qr_string = ...      │ │ 'paid'    │ │
│  └───────────────────────┘   └──────────────────────┘ └───────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP - RESPONSE                        │
│                                                                      │
│  Jika CASH:                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │  ✅ "LUNAS!" - Pembayaran Tunai                                 ││
│  │  Order langsung tercatat sebagai PAID                            ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
│  Jika GOQRIS:                                                        │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │  📱 Tampilkan QR Code                                           ││
│  │  ┌─────────┐     Polling GET /orders/{id}/status setiap 5 detik ││
│  │  │ QR CODE │ ─────────────────────────────────────────────────► ││
│  │  │ Rp 51rb │ ◄──────────────────────────────────────────────── ││
│  │  └─────────┘     { status: "pending" }                          ││
│  │                  ... (pembeli scan & bayar dari HP-nya)         ││
│  │                 { status: "paid" }                                ││
│  │  ✅ "LUNAS!"                                                     ││
│  └─────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
```

### Alur Lengkap (GoQris path)

```
┌─────────┐         ┌─────────┐         ┌─────────┐         ┌─────────┐
│  KASIR  │         │ FLUTTER │         │ DJANGO  │         │ GOQRIS  │
└────┬────┘         └────┬────┘         └────┬────┘         └────┬────┘
     │ pilih menu        │                   │                   │
     │──────────────────►│                   │                   │
     │ pilih payment     │                   │                   │
     │ method: goqris   │                   │                   │
     │──────────────────►│                   │                   │
     │                   │ POST /orders      │                   │
     │                   │ {payment_method   │                   │
     │                   │  ="goqris"}       │                   │
     │                   │──────────────────►│                   │
     │                   │                   │ generate ref_id   │
     │                   │                   │ save to DB        │
     │                   │                   │ (pending,goqris) │
     │                   │                   │                   │
     │                   │                   │ POST /order       │
     │                   │                   │──────────────────►│
     │                   │                   │◄──────────────────│
     │                   │                   │   { qr_string,    │
     │                   │                   │     expires_at }  │
     │                   │                   │                   │
     │                   │                   │ save qr_string    │
     │                   │◄──────────────────│                   │
     │                   │ 201 Created       │                   │
     │                   │ {qr_string,...}   │                   │
     │ tampilkan QR      │                   │                   │
     │◄──────────────────│                   │                   │
     │                   │                   │                   │
     │ [pembeli scan dari HP-nya]            │                   │
     │                   │                   │                   │
     │                   │ GET /status (poll 5 detik)            │
     │                   │──────────────────►│                   │
     │                   │                   │ GET /status       │
     │                   │                   │──────────────────►│
     │                   │                   │◄──────────────────│
     │                   │                   │  { paid: false }  │
     │                   │◄──────────────────│                   │
     │                   │ { status: pending }                  │
     │                   │                   │                   │
     │                   │ ... (pembeli bayar di app bank-nya) │
     │                   │                   │                   │
     │                   │ GET /status (poll)                   │
     │                   │──────────────────►│                   │
     │                   │                   │ GET /status       │
     │                   │                   │──────────────────►│
     │                   │                   │◄──────────────────│
     │                   │                   │  { paid: true }   │
     │                   │                   │ update DB → paid  │
     │                   │◄──────────────────│                   │
     │                   │ { status: paid }  │                   │
     │ "LUNAS!"          │                   │                   │
     │◄──────────────────│                   │                   │
```

### Alur Cash (Simpel)

```
┌─────────┐         ┌─────────┐         ┌─────────┐
│  KASIR  │         │ FLUTTER │         │ DJANGO  │
└────┬────┘         └────┬────┘         └────┬────┘
     │ pilih menu        │                   │
     │──────────────────►│                   │
     │ pilih payment     │                   │
     │ method: cash      │                   │
     │──────────────────►│                   │
     │                   │ POST /orders      │
     │                   │ {payment_method   │
     │                   │  ="cash"}         │
     │                   │──────────────────►│
     │                   │                   │ save to DB
     │                   │                   │ (paid, cash)
     │                   │                   │ paid_at = now()
     │                   │◄──────────────────│
     │                   │ 201 Created       │
     │                   │ {status:"paid"}   │
     │ "LUNAS!"          │                   │
     │◄──────────────────│                   │
     │ NO QR, langsung    │                   │
     │ selesai            │                   │
```

### Edge cases yang di-handle
- **QR expired sebelum bayar** → Flutter stop polling, tampilkan "QR Kedaluwarsa, buat ulang?"
- **Pembeli bayar setelah expired** → GoQris akan reject, Flutter tetap menampilkan "pending" (cek terus sampai max 5 menit, lalu flag manual)
- **Network drop di kasir** → Retry exponential backoff, queue request offline
- **GoQris API down** → Tampilkan error jelas, owner bisa cek `/orders` di admin Django untuk manual reconciliation
- **Double tap "Buat Order"** → Backend pakai `ref_id` unique, request kedua akan ditolak

---

## 8. Frontend (Flutter) — Struktur

### Navigation
- **Login screen** (pilih user + PIN)
- **Mode kasir**: Bottom Nav 4 tab
  - 📋 Antrian (shared)
  - ➕ Order Baru
  - 📊 Riwayat Saya
  - 👤 Profil
- **Mode owner**: Bottom Nav 7 tab (semua tab kasir + )
  - 🍳 Kelola Menu
  - 👥 Kelola Kasir
  - 📈 Laporan
  - ⚙️ Pengaturan

### State Management
- `flutter_bloc` atau `provider` (pilih salah satu, recommend `flutter_bloc` untuk testability)
- Global state: `AuthBloc` (token, current user)
- Per-screen: `OrderBloc`, `QueueBloc`, `MenuBloc`, dll

### Key Packages
| Package | Fungsi |
|---|---|
| `dio` atau `http` | HTTP client |
| `flutter_bloc` | State management |
| `shared_preferences` | Simpan token offline |
| `qr_flutter` | Render QR string ke QR image |
| `intl` | Format currency (Rp 25.000) |
| `fl_chart` | Chart sederhana di laporan (opsional) |
| `connectivity_plus` | Detect online/offline |
| `flutter_secure_storage` | Simpan token dengan aman |

### Reusable Shared Widgets

```
lib/shared/
└── widgets/
    ├── payment_method_selector.dart   ← NEW (reusable)
    └── ...
```

#### PaymentMethodSelector Widget

```dart
// lib/shared/widgets/payment_method_selector.dart

class PaymentMethod {
  final String code;
  final String label;
  final IconData icon;

  const PaymentMethod({
    required this.code,
    required this.label,
    required this.icon,
  });

  static const goqris = PaymentMethod(
    code: 'goqris',
    label: 'GoQris QRIS',
    icon: Icons.qr_code,
  );

  static const cash = PaymentMethod(
    code: 'cash',
    label: 'Tunai',
    icon: Icons.money,
  );

  static List<PaymentMethod> get all => [goqris, cash];
}

class PaymentMethodSelector extends StatelessWidget {
  final String selectedCode;
  final ValueChanged<String> onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selectedCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: PaymentMethod.all.map((method) {
        return RadioListTile<String>(
          value: method.code,
          groupValue: selectedCode,
          title: Text(method.label),
          secondary: Icon(method.icon),
          onChanged: (value) => onChanged(value!),
        );
      }).toList(),
    );
  }
}
```

**Benefits:**
- **DRY**: Tulis sekali, reuse di Order Baru, History, Reports
- **Konsisten**: UI payment method sama di semua screen
- **Extensible**: Tambah payment method baru gampang (tambah di `PaymentMethod.all`)

### Screen Flow Detail

**Login Screen**
```
1. Tampil grid user (Budi, Andi, Owner)
2. User pilih, masukkan PIN
3. POST /auth/pin → simpan token di secure storage
4. Navigate ke home sesuai role
```

**Order Baru Screen**
```
1. Pilih kategori (Manis / Telur / Tipis)
2. Pilih menu (grid card dengan emoji + harga)
3. Cart screen (list item, qty, total)
4. Optional: field "Catatan" (1 text bebas)
5. PaymentMethodSelector (reusable widget - pilih metode pembayaran)
6. Tap button sesuai metode:
   - Kalau Cash → "Bayar Cash" → langsung paid → "LUNAS!" ✅
   - Kalau GoQris → "Generate QRIS" → POST /orders
     → Loading spinner
     → Tampil QR code + nominal + countdown
     → Background polling status
     → Saat paid: animasi ✓ + auto-return ke order baru
```

**Antrian Screen**
```
1. GET /orders/queue (filter status in: pending, paid)
2. Auto-refresh setiap 5 detik
3. Tampil list: ref_id, kasir, total, status, waktu
4. Tap item → detail order (lihat QR jika masih pending)
```

**Riwayat Saya Screen**
```
1. GET /orders/me?date=today (default)
2. Date picker untuk ganti hari
3. Tampil list order hari itu
4. Total di header: "12 transaksi, Rp 320.000"
```

**Kelola Menu Screen (Owner)**
```
1. GET /menus/all
2. List menu dengan switch aktif/nonaktif
3. FAB "Tambah Menu" → form
4. Tap menu → edit form
5. Swipe/delete → soft delete
```

**Laporan Screen (Owner)**
```
1. Date picker
2. GET /reports/daily
3. Tampil summary cards
4. Tampil tabel per kasir
5. Tampil top 5 menu
```

---

## 9. Backend (Django) — Struktur

### Apps
- `accounts` — Custom User model (atau `kasirs` table terpisah), PIN auth
- `menus` — Menu CRUD
- `orders` — Order, OrderItem, GoQris integration
- `reports` — Aggregation queries
- `settings` — Singleton settings

### Libraries
- `djangorestframework` — REST API
- `djangorestframework-simplejwt` — JWT auth
- `psycopg2-binary` — PostgreSQL adapter
- `requests` — HTTP client ke GoQris
- `python-decouple` atau `django-environ` — Env var management
- `gunicorn` — WSGI server
- `whitenoise` — Static files (untuk admin)
- `django-cors-headers` — CORS (jika Flutter web someday)
- `drf-spectacular` — OpenAPI/Swagger docs (bonus portfolio)

### Service Layer
Pisahkan business logic dari view:

```python
# orders/services/goqris.py
class GoQrisService:
    def create_order(self, amount: int, ref_id: str) -> dict
    def check_status(self, ref_id: str) -> dict

# orders/services/orders.py
class OrderService:
    def create_order(self, kasir, items, note) -> Order
    def cancel_order(self, order, owner) -> Order
    def get_daily_report(self, date) -> dict
```

Viewset cuma orchestrate: parse request → panggil service → return response.

### Settings
- `DEBUG=False` di production
- `SECRET_KEY` dari env
- `ALLOWED_HOSTS` = domain
- Database dari env (`DATABASE_URL`)
- GoQris API key dari settings table (bukan env, biar owner bisa update)

### Environment Variables
```
DJANGO_SECRET_KEY=...
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=app.domainmu.com
DATABASE_URL=postgres://user:pass@localhost:5432/martabak
GOQRIS_API_BASE=https://api.goqris.web.id
GOQRIS_API_KEY=GO_xxx  (fallback, utama dari settings table)
```

---

### 9.1 Kasir Management Rules (Penting untuk Agent Implementasi)

Owner punya full CRUD pada kasir, dengan rules ketat:

- ✅ **Create**: boleh bikin kasir baru kapan aja, role default 'kasir', is_active=true
- ✅ **Read**: list semua kasir (aktif + nonaktif) untuk visibility
- ✅ **Update (edit)**: boleh ubah `name`, `is_active` (reactivate), `pin` (reset)
- ✅ **Delete**: SELALU soft delete (`is_active=false`), JANGAN hard delete
- ❌ **Tidak boleh**: edit role kasir lain jadi owner (biar gak ada owner baru tanpa sengaja)
- ❌ **Tidak boleh**: owner menghapus akunnya sendiri (lockout protection)
- ❌ **Tidak boleh**: owner demote dirinya sendiri jadi kasir

**Validasi di backend (bukan client)**:
```python
# Pseudo-logic di view/serializer
if request.user.role != 'owner':
    return 403

if action == 'delete' and target_kasir.id == request.user.id:
    return 400 "Tidak bisa menghapus akun sendiri"

if action == 'patch' and 'role' in data and target_kasir.id != request.user.id:
    return 400 "Tidak bisa ubah role kasir lain menjadi owner"
```

**Behavior soft delete di endpoint**:
- `DELETE /kasirs/{id}` → `is_active = false`, `updated_at = now()`
- Response: 204 No Content (atau 200 dengan object yg sudah updated)
- Kasir yang is_active=false: tidak muncul di `/auth/pin` options, tidak bisa login, tapi history order tetap refer ke dia

**Reactivation**:
- `PATCH /kasirs/{id}` dengan body `{"is_active": true}` → kasir bisa login lagi
- TIdak perlu recreate

## 10. Error Handling

### Backend (Django)
- Validation error → 400 dengan field-level error
- Auth missing/invalid → 401
- Permission denied → 403
- Not found → 404
- Server error → 500 dengan trace ID (untuk support)
- Logging ke file + Sentry (opsional, kalau mau)

### Frontend (Flutter)
- HTTP error → tampilkan snackbar/toast
- 401 → logout otomatis, kembali ke login
- 403 → tampilkan "Anda tidak punya akses"
- Network timeout → retry 3x dengan backoff
- 500 → "Terjadi kesalahan, coba lagi" + log error ID
- Offline → tampilkan banner "Tidak ada koneksi"

### GoQris integration
- API timeout (10 detik) → log error, return 502 ke Flutter dengan pesan "Payment service unavailable"
- Invalid API key → log critical, alert owner (via admin), return 500
- Ref_id duplicate (race condition) → retry 1x dengan ref_id baru

---

## 11. Testing

### Backend
- **Unit test** — services (GoQris mock, OrderService, Reports)
- **Integration test** — DRF endpoints dengan test DB
- **Coverage target**: 70% (MVP cukup)
- Tools: `pytest-django`, `pytest-mock`, `factory_boy`

### Frontend
- **Widget test** — screen utama (Login, Order Baru, Antrian)
- **Integration test** — flow lengkap (login → order → status)
- Tools: `flutter_test`, `mocktail`

### Manual test
- Skenario end-to-end:
  1. Kasir Budi login → buat order → muncul QR → scan dari HP kedua → status jadi paid
  2. Kasir Andi login → antrian muncul orderan Budi
  3. Owner login → buka laporan → angka sesuai
  4. Owner tambah kasir baru → kasir baru bisa login
  5. Owner ubah harga menu → order baru pakai harga baru, history tetap harga lama
  6. QR expired sebelum bayar → tampilkan pesan benar

---

## 12. Deployment

### Server Spec Minimum
- VPS: 1 vCPU, 1GB RAM, 25GB SSD (cukup untuk MVP)
- OS: Ubuntu 22.04 LTS
- Domain: subdomain sudah tersedia

### Services
- `nginx` — port 80/443, reverse proxy ke gunicorn
- `gunicorn` — port 8000 internal, 3 workers
- `postgresql` — port 5432 internal only
- `certbot` — SSL via Let's Encrypt

### Folder Structure di Server
```
/opt/martabak/
├── venv/                # Python venv
├── app/                 # Django project
│   ├── manage.py
│   ├── martabak/        # Settings
│   ├── accounts/
│   ├── menus/
│   ├── orders/
│   ├── reports/
│   └── settings_app/
├── staticfiles/         # Collected static (admin)
├── media/               # Uploaded files (kosong di MVP)
├── logs/
│   ├── django.log
│   ├── nginx-access.log
│   └── nginx-error.log
└── gunicorn.sock
```

### Deploy Steps (Manual SSH)
1. SSH ke VPS
2. `git pull` (kalau pakai git) atau `rsync` kode
3. `source venv/bin/activate`
4. `pip install -r requirements.txt`
5. `python manage.py migrate`
6. `python manage.py collectstatic --noinput`
7. `sudo systemctl restart gunicorn nginx`
8. Verify: `curl https://app.domainmu.com/api/v1/health`

### Backup
- Database: `pg_dump` harian, simpan di S3/object storage (atau lokal + rotasi 7 hari)
- Auto via cron: `0 2 * * * /opt/martabak/backup.sh`

### Monitoring
- Health check endpoint `/api/v1/health`
- Manual check mingguan via cron + email alert (opsional)

---

## 13. Struktur Repo (Monorepo)

```
app-martabak/
├── backend/                 # Django project
│   ├── manage.py
│   ├── requirements.txt
│   ├── martabak/            # settings package
│   │   ├── settings.py
│   │   ├── urls.py
│   │   ├── wsgi.py
│   │   └── asgi.py
│   ├── accounts/
│   ├── menus/
│   ├── orders/
│   ├── reports/
│   ├── raw_materials/
│   └── settings_app/
├── frontend/                # Flutter project
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/            # constants, themes, utils
│   │   ├── data/            # models, repositories, api client
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── orders/
│   │   │   ├── queue/
│   │   │   ├── menus/
│   │   │   ├── kasirs/
│   │   │   ├── reports/
│   │   │   └── settings/
│   │   └── shared/          # widgets, helpers
│   ├── android/
│   └── ios/
├── docs/
│   └── superpowers/
│       └── specs/
│           ├── 2026-07-29--martabak-app-design.md  (file ini)
│           └── 2026-07-29--martabak-app-prompt.md  (prompt untuk coding agent)
├── .gitignore
├── README.md
└── LICENSE
```

---

## 14. Out of Scope & Future Considerations

### Post-MVP Ideas
- Multi-outlet (chain)
- Aplikasi sisi pembeli (pre-order)
- Multiple payment method lain selain GoQris dan Cash (e-wallet lain, transfer bank, dll)
- Variasi menu terstruktur (topping picker)
- Print struk thermal (Bluetooth)
- Kirim struk via WhatsApp
- Loyalty program
- Inventory tracking (auto-deduct dari orders, stock alert)
- Diskon / promo / voucher
- Cash drawer integration
- Real-time push via WebSocket
- Image upload untuk menu
- Custom branding per lapak

### Trade-off yang Disengaja
- **Polling bukan WebSocket** — simpler infra, delay 5 detik masih oke
- **PIN bukan full auth** — owner/kasir tetap punya jejak audit, gak pakai email/password
- **Catatan bebas bukan variasi terstruktur** — MVP cepet, upgrade nanti kalau owner perlu
- **Tanpa image upload** — emoji cukup, masalah storage hilang
- **Mobile-only** — Django admin kept as backdoor, gak dipromosikan
- **Manual cost entry untuk profit** — owner hitung manual biaya bahan baku per periode, tidak auto-deduct

---

## 15. Approval

Spec ini menunggu approval user sebelum diserahkan ke droid/opencode CLI.

Checklist approval:
- [ ] Arsitektur & tech stack OK
- [ ] Database schema sesuai
- [ ] API contract lengkap
- [ ] Alur order → pembayaran jelas
- [ ] Frontend screens sesuai
- [ ] Scope (goals vs non-goals) sesuai
- [ ] Deployment plan realistis
- [ ] Repo structure sesuai

Setelah approved, gunakan file `2026-07-29--martabak-app-prompt.md` untuk eksekusi via droid/opencode CLI.
