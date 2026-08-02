# API Endpoints

Base URL: `http://localhost:8000/api/v1`

## Authentication

### GET `/accounts/login-users/` (Public)
List kasir aktif untuk login screen (public - no auth required).

**Response:**
```json
{
    "data": [
        {"id": 1, "username": "owner", "role": "owner"},
        {"id": 2, "username": "Budi", "role": "kasir"}
    ]
}
```

---

### POST `/accounts/pin/`
Login dengan username dan PIN.

**Request:**
```json
{
    "username": "owner",
    "pin": "000000"
}
```

**Response:**
```json
{
    "refresh": "eyJ...",
    "access": "eyJ...",
    "user": {
        "id": 1,
        "username": "owner",
        "role": "owner",
        "is_active": true
    }
}
```

---

### POST `/accounts/change-pin/`
Ganti PIN sendiri (requires auth).

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
    "old_pin": "000000",
    "new_pin": "123456"
}
```

**Response:**
```json
{
    "message": "PIN berhasil diubah"
}
```

---

### GET `/accounts/me/`
Get info user yang login (requires auth).

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
    "id": 1,
    "username": "owner",
    "role": "owner",
    "is_active": true
}
```

---

## Health Check

### GET `/health/`
Health check endpoint (public, no auth).

**Response:**
```json
{
    "status": "ok"
}
```

---

## Categories

### GET `/categories/`
List category aktif (public).

**Response:**
```json
{
    "status": true,
    "data": [
        {
            "id": 1,
            "name": "manis",
            "sort_order": 1,
            "is_active": true
        },
        {
            "id": 2,
            "name": "telur",
            "sort_order": 2,
            "is_active": true
        }
    ]
}
```

---

### GET `/categories/all/`
List semua category (aktif + nonaktif) - owner only.

**Headers:** `Authorization: Bearer <token>`

**Response:** Same as `/categories/` but includes inactive items.

---

### POST `/categories/`
Tambah category baru (owner only).

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
    "name": "Martabak Sayur",
    "sort_order": 4
}
```

**Response:**
```json
{
    "status": true,
    "message": "Category berhasil dibuat",
    "data": {
        "id": 4,
        "name": "martabak sayur",
        "sort_order": 4,
        "is_active": true
    }
}
```

**Notes:**
- `name` akan di-convert ke lowercase secara otomatis
- Jika `sort_order` tidak diset, akan auto-assign max+1
- `sort_order` harus unique globally

---

### PATCH `/categories/{id}/`
Edit category (owner only).

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
    "name": "Sayur Segar",
    "sort_order": 4
}
```

**Response:**
```json
{
    "status": true,
    "message": "Category berhasil diupdate",
    "data": {
        "id": 4,
        "name": "sayur segar",
        "sort_order": 4,
        "is_active": true
    }
}
```

---

### DELETE `/categories/{id}/`
Soft delete category + deactivate semua menu di dalamnya (owner only).

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
    "status": true,
    "message": "Category berhasil dihapus. Semua menu dalam category ini juga di-nonaktifkan."
}
```

**Notes:**
- Category di-set `is_active=False`
- Semua menu dalam category di-set `is_active=False`

---

## Menus

### GET `/menus/`
List menu aktif dengan search (public).

**Query params:** `?search=nama_menu` (optional, case-insensitive)

**Response:**
```json
{
    "status": true,
    "message": "Berhasil mendapatkan data",
    "data": [
        {
            "id": 1,
            "name": "Martabak Manis Coklat",
            "price": 25000,
            "category": {
                "id": 1,
                "name": "manis"
            },
            "emoji": "🥞",
            "image": null,
            "image_url": null,
            "default_image_url": "http://localhost:8000/media/defaults/martabak.jpg",
            "is_active": true,
            "sort_order": 1
        }
    ]
}
```

**Notes:**
- `category`: Nested object `{id, name}`
- `image`: File image yang diupload (null jika tidak ada)
- `image_url`: URL lengkap ke image yang diupload (null jika tidak ada)
- `default_image_url`: Default image URL (`defaults/martabak.jpg`)
- Hanya menampilkan menu dengan category yang aktif
- Search filter: case-insensitive partial match pada nama menu

---

### GET `/menus/all/`
List semua menu (aktif + nonaktif) - owner only.

**Headers:** `Authorization: Bearer <token>`

**Response:** Same as `/menus/` but includes inactive items.

---

### POST `/menus/`
Tambah menu baru (owner only).

**Headers:** `Authorization: Bearer <token>`

**Request (JSON):**
```json
{
    "name": "Martabak Manis Special",
    "price": 35000,
    "category_id": 1,
    "emoji": "⭐",
    "sort_order": 11
}
```

**Request (form-data dengan image):**
```
name: Martabak Manis Special
price: 35000
category_id: 1
emoji: ⭐
sort_order: 11
image: <file upload>
```

**Response:**
```json
{
    "status": true,
    "message": "Menu berhasil dibuat",
    "data": {
        "id": 11,
        "name": "Martabak Manis Special",
        "price": 35000,
        "category": {
            "id": 1,
            "name": "manis"
        },
        "emoji": "⭐",
        "image": null,
        "image_url": null,
        "default_image_url": "http://localhost:8000/media/defaults/martabak.jpg",
        "is_active": true,
        "sort_order": 11
    }
}
```

**Notes:**
- `category_id`: WAJIB, ID dari category yang sudah ada
- `is_active` default `true` saat create
- Jika `sort_order` tidak diset atau 0, akan auto-assign max+1 per category

---

### PATCH `/menus/{id}/`
Edit menu (owner only).

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
    "price": 32000
}
```

---

### DELETE `/menus/{id}/`
Soft delete menu (owner only).

**Headers:** `Authorization: Bearer <token>`

Sets `is_active=false`.

---

### PATCH `/menus/bulk/`
Bulk update menus (owner only). Bisa reassign ke category lain dan/atau aktivasi/deaktivasi.

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
    "menu_ids": [6, 7, 8],
    "category_id": 1,
    "is_active": true
}
```

**Request Fields:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `menu_ids` | Array of int | Yes | List menu ID yang mau diupdate |
| `category_id` | int | No | Category baru untuk reassign |
| `is_active` | boolean | No | Aktifkan/nonaktifkan menu |

**Use Cases:**

1. **Reassign menus ke category lain:**
   ```json
   {"menu_ids": [1, 2], "category_id": 3}
   ```

2. **Reactivate menu + reassign:**
   ```json
   {"menu_ids": [6, 7, 8], "category_id": 1, "is_active": true}
   ```

3. **Hanya reactivate tanpa reassign:**
   ```json
   {"menu_ids": [1, 2], "is_active": true}
   ```

**Response:**
```json
{
    "status": true,
    "message": "3 menu berhasil diupdate (dipindahkan ke category manis, diaktivasi)",
    "updated_count": 3,
    "updated_menus": [
        {"id": 6, "name": "Martabak Telur Spesial", "category_id": 1, "category_name": "manis", "is_active": true},
        {"id": 7, "name": "Martabak Telur Keju", "category_id": 1, "category_name": "manis", "is_active": true},
        {"id": 8, "name": "Martabak Telur Biasa", "category_id": 1, "category_name": "manis", "is_active": true}
    ]
}
```

**Notes:**
- Minimal 1 menu ID harus diberikan
- Category harus aktif jika digunakan
- Menu IDs yang tidak ditemukan akan diabaikan

---

## Orders

### POST `/orders/`
Buat order baru (requires auth: owner/kasir).

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
    "items": [
        {"menu_id": 1, "qty": 2},
        {"menu_id": 3, "qty": 1}
    ],
    "note": "Untuk makan di tempat",
    "payment_method": "goqris"
}
```

**Notes:**
- `payment_method` WAJIB: `"goqris"` atau `"cash"`
- Jika `payment_method="goqris"` → generate QRIS (jika GoQris available)
- Jika `payment_method="cash"` → langsung marked as paid

**Response (goqris - pending):**
```json
{
    "id": 1,
    "ref_id": "INV-20260729-001",
    "kasir": 1,
    "kasir_name": "Budi",
    "items": [...],
    "total_amount": 78000,
    "status": "pending",
    "payment_method": "goqris",
    "payment_method_label": "GoQris QRIS",
    "note": "Untuk makan di tempat",
    "qr_string": "000201010212...",
    "qr_image_url": "https://...",
    "expires_at": "2026-07-29T20:00:00+07:00",
    "paid_at": null,
    "created_at": "2026-07-29T19:19:06+07:00"
}
```

**Response (cash - langsung paid):**
```json
{
    "id": 2,
    "ref_id": "INV-20260729-002",
    "kasir": 1,
    "kasir_name": "Budi",
    "items": [...],
    "total_amount": 78000,
    "status": "paid",
    "payment_method": "cash",
    "payment_method_label": "Tunai",
    "note": "Untuk makan di tempat",
    "qr_string": null,
    "qr_image_url": null,
    "expires_at": null,
    "paid_at": "2026-07-29T19:20:00+07:00",
    "created_at": "2026-07-29T19:19:06+07:00"
}
```

**Order Status Flow:**
- `pending` → QRIS generated, waiting for payment
- `paid` → Payment confirmed
- `expired` → QRIS timeout
- `cancelled` → Cancelled by owner

---

### GET `/orders/`
List orders.

- **Owner**: sees all orders
- **Kasir**: sees only their own orders

**Headers:** `Authorization: Bearer <token>`

**Query params:** `?page=1&search=&ordering=-created_at`

**Response:**
```json
{
    "status": true,
    "message": "Berhasil mendapatkan data",
    "data": [
        {
            "id": 1,
            "ref_id": "INV-20260729-001",
            "kasir_name": "Budi",
            "items_count": 2,
            "total_amount": 78000,
            "status": "paid",
            "note": "test",
            "created_at": "2026-07-29T19:19:06+07:00"
        }
    ],
    "pagination": {
        "page": 1,
        "size": 20,
        "total_data": 1,
        "total_pages": 1
    }
}
```

---

### GET `/orders/me/`
Riwayat order kasir yang login.

**Headers:** `Authorization: Bearer <token>`

---

### GET `/orders/{id}/`
Detail order.

**Headers:** `Authorization: Bearer <token>`

---

### GET `/orders/{id}/status/`
Cek status pembayaran order.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
    "ref_id": "INV-20260729-001",
    "status": "pending",
    "total_amount": 30000,
    "is_expired": false
}
```

---

### GET `/orders/queue/`
Antrian shared untuk display kasir (pending + paid orders).

**Headers:** `Authorization: Bearer <token>`

**Throttle:** 6 requests/minute per user (1 request setiap 10 detik)

**Response:** List of recent pending/paid orders.

---

### POST `/orders/{id}/cancel/`
Batalkan order (owner only).

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
    "message": "Order berhasil dibatalkan"
}
```

---

## Kasir Management (Owner Only)

### GET `/accounts/kasirs/`
List semua kasir.

**Headers:** `Authorization: Bearer <token>` (owner)

---

### POST `/accounts/kasirs/`
Tambah kasir baru.

**Headers:** `Authorization: Bearer <token>` (owner)

**Request:**
```json
{
    "username": "Citra",
    "pin": "5678",
    "role": "kasir"
}
```

---

### PATCH `/accounts/kasirs/{id}/`
Edit kasir.

**Headers:** `Authorization: Bearer <token>` (owner)

---

### DELETE `/accounts/kasirs/{id}/`
Soft delete kasir (sets `is_active=false`).

**Headers:** `Authorization: Bearer <token>` (owner)

---

### POST `/accounts/kasirs/{id}/reset-pin/`
Reset PIN kasir ke default `1234` (owner only).

**Headers:** `Authorization: Bearer <token>` (owner)

**Response:**
```json
{
    "message": "PIN Budi direset ke 1234"
}
```

---

## Settings (Owner Only)

### GET `/settings/`
Get app settings.

**Headers:** `Authorization: Bearer <token>` (owner)

**Response:**
```json
{
    "id": 1,
    "goqris_project_name": "Toko Martabak"
}
```

---

### PATCH `/settings/`
Update app settings.

**Headers:** `Authorization: Bearer <token>` (owner)

**Request:**
```json
{
    "goqris_project_name": "Toko Martabak Mantap"
}
```

---

## GoQris (Owner Only)

### GET `/goqris/profile/`
Get GoQris subscription profile & status.

**Headers:** `Authorization: Bearer <token>` (owner)

**Response (API key not configured):**
```json
{
    "status": "not_configured",
    "message": "GoQris API key belum diset di .env"
}
```

**Response (active):**
```json
{
    "status": "active",
    "data": {
        "name": "John Doe",
        "email": "user@example.com",
        "plan": "Free Plan",
        "usage": 3,
        "limit": 5,
        "timezone": "Asia/Jakarta"
    }
}
```

**Note:** GoQris API key is read from `.env` file (`GOQRIS_API_KEY`), not from database.

---

## Reports (Owner Only)

### GET `/reports/daily/`
Laporan harian.

**Headers:** `Authorization: Bearer <token>` (owner)

**Query params:** `?date=YYYY-MM-DD` (default: today)

**Response:**
```json
{
    "status": true,
    "message": "Berhasil mendapatkan laporan harian",
    "data": {
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
            {"kasir_id": 2, "name": "Budi", "transaksi": 28, "total": 745000},
            {"kasir_id": 3, "name": "Andi", "transaksi": 19, "total": 490000}
        ],
        "top_menus": [
            {"menu_id": 5, "name": "Martabak Manis Coklat Keju", "emoji": "🥞", "qty": 18, "total": 450000}
        ]
    }
}
```

---

### GET `/reports/top-menus/`
Top N menu dalam rentang waktu.

**Headers:** `Authorization: Bearer <token>` (owner)

**Query params:**
- `from` (required): YYYY-MM-DD
- `to` (required): YYYY-MM-DD
- `limit`: number (default: 5)

**Response:**
```json
{
    "status": true,
    "message": "Berhasil mendapatkan top menu",
    "data": [
        {"menu_id": 1, "name": "Martabak Manis Coklat", "emoji": "🥞", "qty": 50, "total": 1250000}
    ]
}
```

---

### GET `/reports/kasir-performance/`
Performa kasir di tanggal tertentu.

**Headers:** `Authorization: Bearer <token>` (owner)

**Query params:** `?date=YYYY-MM-DD` (default: today)

**Response:**
```json
{
    "status": true,
    "message": "Berhasil mendapatkan performa kasir",
    "data": [
        {"kasir_id": 2, "name": "Budi", "transaksi": 28, "total": 745000, "rata_rata": 26607}
    ]
}
```

---

### GET `/reports/profit/`
Laporan profit (pendapatan - biaya bahan baku) per periode.

**Headers:** `Authorization: Bearer <token>` (owner)

**Query params:**
- `from` (required): YYYY-MM-DD
- `to` (required): YYYY-MM-DD

**Response:**
```json
{
    "status": true,
    "message": "Berhasil mendapatkan laporan profit",
    "data": {
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
}
```

---

## Raw Materials (Owner Only)

### GET `/raw-materials/items/`
List semua nama bahan.

**Headers:** `Authorization: Bearer <token>` (owner)

**Response:**
```json
{
    "status": true,
    "data": [
        {"id": 1, "name": "Tepung", "is_active": true, "created_at": "...", "updated_at": "..."}
    ]
}
```

---

### POST `/raw-materials/items/`
Tambah nama bahan baru.

**Headers:** `Authorization: Bearer <token>` (owner)

**Request:**
```json
{
    "name": "Tepung"
}
```

**Response:**
```json
{
    "id": 1,
    "name": "Tepung",
    "is_active": true,
    "created_at": "2026-07-30T...",
    "updated_at": "2026-07-30T..."
}
```

---

### DELETE `/raw-materials/items/{id}/`
Soft delete bahan (sets `is_active=false`).

**Headers:** `Authorization: Bearer <token>` (owner)

**Response:**
```json
{
    "message": "Material berhasil dihapus"
}
```

---

### GET `/raw-materials/cost-entries/`
List semua cost entries.

**Headers:** `Authorization: Bearer <token>` (owner)

**Response:**
```json
{
    "status": true,
    "data": [
        {
            "id": 1,
            "date_from": "2026-07-28",
            "date_to": "2026-07-30",
            "items": [
                {"id": 1, "material_name": "Tepung", "quantity": "8.00", "unit": "kg", "price_per_unit": 15000, "subtotal": 120000}
            ],
            "total_cost": 168000,
            "total_revenue": 500000,
            "profit": 332000,
            "notes": "Bahan baku habis",
            "created_by_name": "owner",
            "created_at": "...",
            "updated_at": "..."
        }
    ]
}
```

---

### POST `/raw-materials/cost-entries/`
Buat cost entry baru (input biaya bahan baku).

**Headers:** `Authorization: Bearer <token>` (owner)

**Request:**
```json
{
    "date_from": "2026-07-28",
    "date_to": "2026-07-30",
    "items": [
        {"material_name": "Tepung", "quantity": "8", "unit": "kg", "price_per_unit": 15000},
        {"material_name": "Gula", "quantity": "4", "unit": "kg", "price_per_unit": 12000}
    ],
    "notes": "Bahan baku habis untuk periode ini"
}
```

**Response:**
```json
{
    "id": 1,
    "date_from": "2026-07-28",
    "date_to": "2026-07-30",
    "items": [
        {"id": 1, "material_name": "Tepung", "quantity": "8.00", "unit": "kg", "price_per_unit": 15000, "subtotal": 120000},
        {"id": 2, "material_name": "Gula", "quantity": "4.00", "unit": "kg", "price_per_unit": 12000, "subtotal": 48000}
    ],
    "total_cost": 168000,
    "total_revenue": 500000,
    "profit": 332000,
    "notes": "Bahan baku habis untuk periode ini",
    "created_by_name": "owner",
    "created_at": "2026-07-30T10:00:00+07:00",
    "updated_at": "2026-07-30T10:00:00+07:00"
}
```

**Notes:**
- `total_revenue` dihitung otomatis dari orders (paid) dalam range tanggal
- `profit` = `total_revenue` - `total_cost`
- Material name dan unit bebas (free text) - owner bisa isi apa saja (kg, gram, butir, zak, dll)

---

### GET `/raw-materials/cost-entries/{id}/`
Detail cost entry.

**Headers:** `Authorization: Bearer <token>` (owner)

**Response:** Same as single entry in list.

---

### PATCH `/raw-materials/cost-entries/{id}/`
Edit cost entry.

**Headers:** `Authorization: Bearer <token>` (owner)

**Request:**
```json
{
    "date_from": "2026-07-28",
    "date_to": "2026-07-31",
    "items": [
        {"material_name": "Tepung", "quantity": "10", "unit": "kg", "price_per_unit": 15000}
    ],
    "notes": "Updated"
}
```

---

### DELETE `/raw-materials/cost-entries/{id}/`
Hapus cost entry.

**Headers:** `Authorization: Bearer <token>` (owner)

**Response:**
```json
{
    "message": "Entry berhasil dihapus"
}
```

---

## Error Responses

### 400 Bad Request
```json
{
    "status": false,
    "message": "Validation error",
    "errors": {
        "field": ["Error message"]
    }
}
```

### 401 Unauthorized
```json
{
    "status": false,
    "message": "Data autentikasi tidak diberikan.",
    "errors": {
        "detail": "Authentication credentials were not provided."
    }
}
```

### 403 Forbidden
```json
{
    "error": "Unauthorized"
}
```

### 404 Not Found
```json
{
    "error": "Resource not found"
}
```

### 429 Too Many Requests
```json
{
    "status": false,
    "message": "Permintaan ini telah dibatasi. Expected available in X seconds.",
    "errors": {
        "detail": "Request was throttled."
    }
}
```

---

## Rate Limiting

| Endpoint | Rate |
|----------|------|
| `/accounts/pin/` | 20/minute/IP |
| Other API | 500/minute/user |

---

## Related

- [Setup Guide](setup.md)
- [Data Models](models.md)
- [Postman Collection](../postman/App-Martabak-API.json)
