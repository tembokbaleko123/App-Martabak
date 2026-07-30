# Data Models

## Kasir

Custom user model untuk authentication dan authorization.

```python
class Kasir(AbstractUser):
    ROLE_CHOICES = [
        ('owner', 'Owner'),
        ('kasir', 'Kasir'),
    ]

    pin_hash = models.CharField(max_length=255)  # bcrypt hash
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    is_active = models.BooleanField(default=True)
```

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| `id` | AutoField | Primary key |
| `username` | CharField | Unique username |
| `pin_hash` | CharField | bcrypt hash of PIN |
| `role` | CharField | `owner` or `kasir` |
| `is_active` | BooleanField | Soft delete flag |
| `created_at` | DateTimeField | Auto set on create |
| `updated_at` | DateTimeField | Auto set on save |

**Default Users:**
| Username | PIN | Role |
|----------|-----|------|
| `owner` | `000000` | owner |
| `Budi` | `1234` | kasir |
| `Andi` | `1234` | kasir |

---

## Menu

```python
class Menu(models.Model):
    CATEGORY_CHOICES = [
        ('manis', 'Manis'),
        ('telur', 'Telur'),
        ('tipis', 'Tipis'),
    ]

    name = models.CharField(max_length=100)
    price = models.BigIntegerField()
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES)
    emoji = models.CharField(max_length=10, default='🥞')
    is_active = models.BooleanField(default=True)
    sort_order = models.IntegerField(default=0)
```

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| `id` | AutoField | Primary key |
| `name` | CharField | Menu name |
| `price` | BigIntegerField | Price in Rupiah |
| `category` | CharField | `manis`, `telur`, or `tipis` |
| `emoji` | CharField | Display emoji |
| `is_active` | BooleanField | Show/hide menu |
| `sort_order` | IntegerField | Display order |

**Default Menu Items:**
| Name | Price | Category |
|------|-------|----------|
| Martabak Manis Coklat | 25,000 | manis |
| Martabak Manis Coklat Keju | 30,000 | manis |
| Martabak Manis Keju | 28,000 | manis |
| Martabak Manis Susu | 22,000 | manis |
| Martabak Manis Kacang | 20,000 | manis |
| Martabak Telur Biasa | 20,000 | telur |
| Martabak Telur Spesial | 25,000 | telur |
| Martabak Telur Keju | 30,000 | telur |
| Martabak Tipis Biasa | 15,000 | tipis |
| Martabak Tipis Spesial | 20,000 | tipis |

---

## Order

```python
class Order(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('paid', 'Paid'),
        ('expired', 'Expired'),
        ('cancelled', 'Cancelled'),
    ]

    ref_id = models.CharField(max_length=50, unique=True)
    kasir = models.ForeignKey(Kasir, on_delete=PROTECT)
    total_amount = models.BigIntegerField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES)
    qr_string = models.TextField(null=True, blank=True)
    qr_image_url = models.URLField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    paid_at = models.DateTimeField(null=True, blank=True)
    note = models.TextField(null=True, blank=True)
    goqris_data = models.JSONField(null=True, blank=True)
```

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| `id` | AutoField | Primary key |
| `ref_id` | CharField | Unique reference (INV-YYYYMMDD-NNN) |
| `kasir` | ForeignKey | FK to Kasir |
| `total_amount` | BigIntegerField | Total in Rupiah |
| `status` | CharField | `pending`, `paid`, `expired`, `cancelled` |
| `qr_string` | TextField | QRIS string from GoQris |
| `qr_image_url` | URLField | QR image URL (optional) |
| `expires_at` | DateTimeField | QR expiration time |
| `paid_at` | DateTimeField | Payment confirmation time |
| `note` | TextField | Order note (optional) |
| `goqris_data` | JSONField | Raw GoQris API response |

**Indexes:**
- `(status, created_at)`
- `(kasir, created_at)`
- `(created_at)`

**Status Flow:**
```
pending → paid     (payment confirmed)
pending → expired (QR timeout)
pending → cancelled (owner cancelled)
```

---

## OrderItem

```python
class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=CASCADE)
    menu = models.ForeignKey(Menu, on_delete=PROTECT)
    qty = models.IntegerField()
    price_at_order = models.BigIntegerField()
    subtotal = models.IntegerField()  # auto-calculated
```

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| `id` | AutoField | Primary key |
| `order` | ForeignKey | FK to Order |
| `menu` | ForeignKey | FK to Menu |
| `qty` | IntegerField | Quantity |
| `price_at_order` | BigIntegerField | Snapshot of menu price at order time |
| `subtotal` | IntegerField | qty × price_at_order (auto-calculated) |

**Auto-calculated on save:**
```python
def save(self, *args, **kwargs):
    self.subtotal = self.qty * self.price_at_order
    super().save(*args, **kwargs)
```

---

## Settings

Singleton model for app configuration.

```python
class Settings(models.Model):
    goqris_project_name = models.CharField(max_length=100, blank=True)
```

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| `id` | IntegerField | Primary key (always 1) |
| `goqris_project_name` | CharField | GoQris project name (will appear when scanning QRIS) |

**Note:** `goqris_api_key` stored in `.env` file (`GOQRIS_API_KEY`), not in database.

---

## MaterialItem

Master data nama bahan baku (optional - material names can also be free text).

```python
class MaterialItem(models.Model):
    name = models.CharField(max_length=100, unique=True)
    is_active = models.BooleanField(default=True)
```

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| `id` | AutoField | Primary key |
| `name` | CharField | Unique material name |
| `is_active` | BooleanField | Soft delete flag |
| `created_at` | DateTimeField | Auto set on create |
| `updated_at` | DateTimeField | Auto set on save |

---

## MaterialCostEntry

Header untuk input biaya bahan dalam periode tertentu.

```python
class MaterialCostEntry(models.Model):
    date_from = models.DateField()
    date_to = models.DateField()
    notes = models.TextField(null=True, blank=True)
    created_by = models.ForeignKey(Kasir, on_delete=PROTECT)
```

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| `id` | AutoField | Primary key |
| `date_from` | DateField | Start date of period |
| `date_to` | DateField | End date of period |
| `notes` | TextField | Catatan opsional |
| `created_by` | ForeignKey | FK to Kasir |
| `created_at` | DateTimeField | Auto set on create |
| `updated_at` | DateTimeField | Auto set on save |

**Computed (via serializer):**
| Field | Description |
|-------|-------------|
| `total_cost` | Sum of all item subtotals |
| `total_revenue` | Sum of paid orders in date range |
| `profit` | total_revenue - total_cost |

---

## MaterialCostItem

Detail item bahan dalam satu cost entry.

```python
class MaterialCostItem(models.Model):
    cost_entry = models.ForeignKey(MaterialCostEntry, on_delete=CASCADE)
    material_name = models.CharField(max_length=100)
    quantity = models.DecimalField(max_digits=10, decimal_places=2)
    price_per_unit = models.BigIntegerField()
```

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| `id` | AutoField | Primary key |
| `cost_entry` | ForeignKey | FK to MaterialCostEntry |
| `material_name` | CharField | Nama bahan (free text) |
| `quantity` | DecimalField | Qty (supports decimal) |
| `price_per_unit` | BigIntegerField | Harga per unit |
| `subtotal` | BigIntegerField | quantity × price_per_unit (auto-calculated) |

---

## Database Schema

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│   kasirs     │       │    menus     │       │    orders    │
├──────────────┤       ├──────────────┤       ├──────────────┤
│ id (PK)      │       │ id (PK)      │       │ id (PK)      │
│ username     │       │ name          │       │ ref_id       │
│ pin_hash     │       │ price         │       │ kasir_id (FK)│
│ role         │       │ category      │       │ total_amount │
│ is_active    │       │ emoji         │       │ status       │
│ created_at   │       │ is_active     │       │ qr_string    │
│ updated_at   │       │ sort_order    │       │ expires_at   │
└──────────────┘       │ created_at   │       │ paid_at      │
       │               │ updated_at   │       │ note         │
       │               └──────────────┘       │ goqris_data  │
       │                                        │ created_at   │
       │                                        └──────────────┘
       │                                              │
       │                                              │
       ▼                                              ▼
┌──────────────┐                              ┌──────────────┐
│  order_items │                              │   settings   │
├──────────────┤                              ├──────────────┤
│ id (PK)      │                              │ id (PK)      │
│ order_id (FK)│                              │ goqris_proj..│
│ menu_id (FK) │                              └──────────────┘
│ qty          │
│ price_at_... │
│ subtotal     │
└──────────────┘

┌──────────────┐       ┌──────────────────────────┐
│material_items│       │  material_cost_entries   │
├──────────────┤       ├──────────────────────────┤
│ id (PK)      │       │ id (PK)                  │
│ name         │       │ date_from                │
│ is_active    │       │ date_to                  │
│ created_at   │       │ notes                    │
│ updated_at   │       │ created_by_id (FK)       │
└──────────────┘       │ created_at               │
                       │ updated_at               │
                       └──────────────────────────┘
                                │
                                │ 1:N
                                ▼
                       ┌──────────────────────────┐
                       │  material_cost_items     │
                       ├──────────────────────────┤
                       │ id (PK)                  │
                       │ cost_entry_id (FK)      │
                       │ material_name            │
                       │ quantity                 │
                       │ price_per_unit           │
                       │ subtotal                 │
                       └──────────────────────────┘
```

---

## Related

- [Setup Guide](setup.md)
- [API Endpoints](api-endpoints.md)
