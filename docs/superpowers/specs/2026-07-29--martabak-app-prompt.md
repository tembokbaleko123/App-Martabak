# Prompt untuk Coding Agent (Droid / OpenCode CLI)

> **Cara pakai:** Buka terminal di folder project (`app-martabak/`), lalu paste prompt ini ke droid/opencode CLI.
>
> **Prinsip:** Spec adalah single source of truth. Prompt ini cuma orchestrator yang ngasih tahu agent *urutan kerja* dan *boundary*. Detail lengkap selalu di spec.

---

## MASTER PROMPT (paste utuh ke CLI)

```
Kamu adalah senior fullstack developer. Tugas kamu: membangun aplikasi kasir
martabak dengan pembayaran GoQris sesuai spec di
`docs/superpowers/specs/2026-07-29--martabak-app-design.md`.

BACALAH SPEC ITU DULU SEBELUM MULAI APAPUN. Spec adalah single source of
truth — jangan mengarang requirement di luar spec. Kalau ada yang ambigu,
tanya user, jangan asumsi.

═══════════════════════════════════════════════════════════════════
TUJUAN UTAMA
═══════════════════════════════════════════════════════════════════

Bangun MVP yang bisa langsung dipakai di lapak martabak sungguhan:
- 1-3 kasir input order di HP Android
- QRIS muncul, pembeli bayar dari HP sendiri
- Owner bisa lihat laporan harian di HP yang sama (mode owner via PIN)
- Deploy ke VPS dengan subdomain (user sudah punya VPS, install/config
  Nginx + SSL + Gunicorn di fase akhir)

═══════════════════════════════════════════════════════════════════
BATAS KERJA (NON-NEGOTIABLE)
═══════════════════════════════════════════════════════════════════

WAJIB:
- Backend: Django 5.x + DRF + PostgreSQL
- Frontend: Flutter (Dart) — single codebase Android
- Payment: GoQris (https://goqris.web.id) — endpoint `/order` dan `/status`
- Struktur repo monorepo: `/backend` dan `/frontend`
- Semua konfigurasi sensitif via env var, bukan hardcoded

LARANGAN (sesuai spec section 2 "Non-Goals"):
- ❌ JANGAN buat aplikasi sisi pembeli
- ❌ JANGAN tambah payment method lain (cash, e-wallet lain, dll)
- ❌ JANGAN buat variasi menu terstruktur (topping picker, dll)
- ❌ JANGAN buat print struk
- ❌ JANGAN buat chart interaktif / export Excel/PDF
- ❌ JANGAN pakai WebSocket (polling saja)
- ❌ JANGAN upload gambar menu (emoji saja)
- ❌ JANGAN multi-bahasa (Indonesia saja)
- ❌ JANGAN pakai library auth pihak ketiga kecuali `djangorestframework-simplejwt`
- ❌ JANGAN skip test, minimal smoke test untuk setiap endpoint utama

═══════════════════════════════════════════════════════════════════
URUTAN KERJA (PHASE-BASED, JANGAN SKIP)
═══════════════════════════════════════════════════════════════════

Kerjakan per phase. SETIAP PHASE harus diakhiri dengan:
1. Commit git dengan pesan jelas
2. Verifikasi manual (jalankan command test)
3. Lapor ke user: phase X selesai, deliverable apa, bisa lanjut

──────────────────────────────────────────────────────────────────
PHASE 0: SCAFFOLDING (15-30 menit)
──────────────────────────────────────────────────────────────────

Tujuan: struktur repo dan setup awal, tidak ada business logic.

Steps:
1. Inisialisasi git repo (`git init`, `.gitignore` untuk Python + Flutter +
   IDE, initial commit)
2. Buat struktur folder sesuai spec section 13
3. `backend/`: scaffold Django project `martabak` dengan apps:
   `accounts`, `menus`, `orders`, `reports`, `settings_app`
4. `frontend/`: scaffold Flutter project (`flutter create` di dalam
   `frontend/`, bukan di subfolder)
5. `README.md` singkat: apa project ini, cara run lokal
6. Setup `requirements.txt` (Django, DRF, simplejwt, psycopg2, dll) dan
   `pubspec.yaml` (dio/http, flutter_bloc, qr_flutter, intl, dll)

Deliverable: `git log` menunjukkan 1-2 commit, kedua folder bisa di-install
tanpa error.

──────────────────────────────────────────────────────────────────
PHASE 1: DATABASE & MODELS (1-2 jam)
──────────────────────────────────────────────────────────────────

Tujuan: models Django sesuai spec section 5.

Steps:
1. Definisikan model `Kasir` (atau extend `AbstractUser`):
   - name, pin_hash, role, is_active, timestamps
2. Model `Menu`: name, price, category, emoji, is_active, sort_order
3. Model `Order` + `OrderItem` sesuai spec
4. Model `Settings` singleton
5. Migration: `python manage.py makemigrations && migrate`
6. Setup PostgreSQL lokal (atau SQLite untuk dev), konfigurasi DATABASE_URL
7. Seed data via management command atau fixture:
   - 1 owner (PIN default "000000" — owner harus ganti setelah login)
   - 2 kasir contoh (Budi, Andi, PIN "1234")
   - 8-10 menu contoh (5 manis, 3 telur, 2 tipis)
8. Tulis unit test untuk model invariants (misal: order_items subtotal =
   qty * price_at_order)

Deliverable: `python manage.py migrate` jalan tanpa error, `python manage.py
shell` bisa query semua model, test pass.

──────────────────────────────────────────────────────────────────
PHASE 2: AUTHENTICATION (1 jam)
──────────────────────────────────────────────────────────────────

Tujuan: PIN-based auth sesuai spec section 6.

Steps:
1. Endpoint `POST /api/v1/auth/pin`:
   - Input: name + PIN
   - Lookup kasir, verify PIN (pakai `hashlib.pbkdf2_sha256` atau
     Django's `check_password`)
   - Return JWT token (pakai `djangorestframework-simplejwt`)
   - Rate limiting: max 5 attempt per 5 menit per IP
2. Endpoint `GET /api/v1/me`: return info user dari token
3. Endpoint `POST /api/v1/auth/change-pin`: ganti PIN sendiri
4. Custom permission class `IsKasir` dan `IsOwner` (extend dari
   `IsAuthenticated`)
5. Tulis test: PIN benar, PIN salah, rate limit, change PIN

Deliverable: bisa login via curl/Postman, dapat JWT valid, permission
class enforce dengan benar.

──────────────────────────────────────────────────────────────────
PHASE 3: MENU API (30 menit)
──────────────────────────────────────────────────────────────────

Tujuan: CRUD menu sesuai spec section 6.

Steps:
1. `GET /menus` — list menu aktif (untuk kasir)
2. `GET /menus/all` — list semua menu (owner only)
3. `POST /menus` (owner only) — buat menu
4. `PATCH /menus/{id}` (owner only) — edit menu
5. `DELETE /menus/{id}` (owner only) — soft delete (set is_active=False)
6. Pakai DRF ViewSet + Router, Serializer dengan validasi
7. Tulis test untuk setiap endpoint + permission

Deliverable: full CRUD menu via API, test pass.

──────────────────────────────────────────────────────────────────
PHASE 4: ORDER + GOQRIS INTEGRATION (3-4 jam) ← INTI
──────────────────────────────────────────────────────────────────

Tujuan: order creation + payment integration sesuai spec section 6 & 7.

Steps:
1. Setup `GoQrisService` di `orders/services/goqris.py`:
   - Method `create_order(amount, ref_id, project_name) → dict`
   - Method `check_status(ref_id) → dict`
   - Pakai `requests` library, timeout 10 detik
   - Handle error: timeout, 4xx, 5xx, invalid response
   - Tulis unit test dengan mock (pakai `pytest-mock` atau
     `unittest.mock`)
2. Setup `OrderService` di `orders/services/orders.py`:
   - `create_order(kasir, items_data, note) → Order`:
     a. Generate ref_id: "INV-YYYYMMDD-NNN" (sequential per hari)
     b. Snapshot harga menu ke `price_at_order`
     c. Hitung total
     d. Simpan ke DB (status=pending)
     e. Panggil GoQris create_order
     f. Simpan qr_string, expires_at, goqris_data ke DB
     g. Return order object
3. Endpoints:
   - `POST /orders` (kasir+owner) — pakai OrderService di atas
   - `GET /orders/{id}` (auth)
   - `GET /orders/{id}/status` (auth) — panggil GoQrisService.check_status,
     update DB jika paid, return status
   - `POST /orders/{id}/cancel` (owner only) — set status='cancelled',
     catat siapa yang cancel
4. Antrian: `GET /orders/queue?status=pending,paid&limit=50` (auth)
5. Riwayat: `GET /orders/me?date=YYYY-MM-DD` (filter by current kasir)
6. Owner view: `GET /orders?date=&kasir_id=` (full filter)
7. Tulis integration test end-to-end dengan GoQris mocked

Deliverable: bisa create order via API, dapat qr_string, polling status
berfungsi (dengan mock), test pass.

──────────────────────────────────────────────────────────────────
PHASE 5: REPORTS (1-2 jam)
──────────────────────────────────────────────────────────────────

Tujuan: 3 endpoint laporan sesuai spec section 6.

Steps:
1. `ReportService` di `reports/services.py`:
   - `daily_report(date) → dict` — summary, per_kasir, top_menus
   - `top_menus(from_date, to_date, limit=5) → list`
   - `kasir_performance(date) → list`
2. Gunakan Django ORM aggregation (`Sum`, `Count`, `Avg`,
   `annotate`, `values`)
3. Endpoints:
   - `GET /reports/daily?date=YYYY-MM-DD` (owner only)
   - `GET /reports/top-menus?from=&to=` (owner only)
   - `GET /reports/kasir-performance?date=` (owner only)
4. Edge case: hari dengan 0 transaksi (return zeros, bukan error)
5. Tulis test dengan seed data

Deliverable: 3 endpoint report return data akurat untuk sample data.

──────────────────────────────────────────────────────────────────
PHASE 6: KASIR & SETTINGS MANAGEMENT (1-2 jam)
──────────────────────────────────────────────────────────────────

Tujuan: owner bisa manage kasir & settings via API dengan rules yang ketat.

⚠️  BACA spec section 9.1 "Kasir Management Rules" SEBELUM MULAI PHASE INI.
Rules WAJIB di-enforce di backend, jangan cuma di UI.

Steps:
1. CRUD kasir: `GET/POST/PATCH/DELETE /kasirs` (owner only)
   - Password = PIN, di-hash pakai `Django's make_password` (pbkdf2_sha256)
   - JANGAN hard delete — DELETE selalu soft delete (set is_active=false)
   - JANGAN izinkan edit role kasir lain jadi owner (kecuali diri sendiri,
     yg berarti demote — juga dilarang)
   - JANGAN izinkan owner hapus akunnya sendiri
   - Owner BISA reactivate kasir via PATCH is_active=true
2. Settings: `GET/PATCH /settings` (owner only, singleton)
   - Field: nama_lapak, goqris_apikey, goqris_project_name
   - Validasi: project_name harus match dengan yg di GoQris dashboard
3. Implementasi rate limiting untuk endpoint PIN
4. Audit log sederhana: log siapa yang create/edit/delete kasir (simpan
   di file log, JANGAN di DB agar MVP simpel)
5. Tulis test:
   - Owner bisa CRUD kasir ✅
   - Owner tidak bisa hapus diri sendiri ❌ (assert 400)
   - Owner tidak bisa promote kasir lain ke owner ❌ (assert 400)
   - Kasir yang dihapus (is_active=false) tidak bisa login ❌
   - Reactivate kasir → bisa login lagi ✅

Deliverable: owner bisa manage kasir & settings via API dengan rules
ter-enforce, semua test pass.

──────────────────────────────────────────────────────────────────
PHASE 7: FLUTTER SCAFFOLDING + AUTH UI (1-2 jam)
──────────────────────────────────────────────────────────────────

Tujuan: Flutter app bisa login & navigate.

Steps:
1. Setup `flutter_bloc` + `dio` + `flutter_secure_storage`
2. Konfigurasi base URL via `--dart-define=API_BASE_URL=...`
3. Theme: Material 3, warna brand martabak (coklat/emas), typography
4. Folder structure per spec section 8 (lib/data, lib/features, dll)
5. `AuthBloc`: login, logout, restore session dari secure storage
6. Login screen: grid user + PIN input + error handling
7. After login: routing sesuai role (kasir → 4 tab, owner → 7 tab)
8. Bottom nav skeleton (placeholder screens dulu, diisi phase berikutnya)
9. Test: login flow, session restore

Deliverable: app jalan di Android emulator, bisa login, navigate.

──────────────────────────────────────────────────────────────────
PHASE 8: FLUTTER — ORDER FLOW (3-4 jam)
──────────────────────────────────────────────────────────────────

Tujuan: kasir bisa bikin order & lihat QRIS.

Steps:
1. API client wrapper: `ApiClient` dengan interceptor (attach token,
   handle 401 → logout)
2. `MenuRepository` + `OrderRepository` + `QueueRepository`
3. Order Baru screen (sesuai spec section 8):
   - Pilih kategori (tab/segmented)
   - Grid menu card (emoji + nama + harga)
   - Cart drawer/bottom sheet
   - Field catatan
   - Submit → loading → QR screen
4. QR screen:
   - Render `qr_string` ke QR image (pakai `qr_flutter`)
   - Tampil nominal + countdown expires_at
   - Background polling status setiap 5 detik (pakai
     `Timer.periodic`)
   - Saat paid: animasi ✓ + auto-return ke order baru
5. Edge case: QR expired, network error, double-tap submit
6. Test: widget test untuk Order Baru screen

Deliverable: end-to-end order → QR → paid flow jalan di emulator.

──────────────────────────────────────────────────────────────────
PHASE 9: FLUTTER — ANTRIAN, RIWAYAT, KELOLA (3-4 jam)
──────────────────────────────────────────────────────────────────

Tujuan: semua screen utama sesuai spec section 8.

Steps:
1. Antrian screen: list shared, pull-to-refresh + auto-refresh
2. Riwayat Saya screen: list, date picker, total di header
3. Kelola Menu (owner): list, switch aktif/nonaktif, form tambah/edit
4. Kelola Kasir (owner): list, form tambah, reset PIN
5. Laporan (owner): date picker + tampil summary + tabel kasir + top menu
6. Pengaturan (owner): form edit nama lapak, GoQris API key
7. Profil: ganti PIN, logout
8. Loading & error state untuk semua screen
9. Test: widget test untuk tiap screen

Deliverable: semua screen MVP jalan, end-to-end flow dari berbagai role
tested.

──────────────────────────────────────────────────────────────────
PHASE 10: DEPLOYMENT PREP (1-2 jam)
──────────────────────────────────────────────────────────────────

Tujuan: app siap deploy ke VPS.

Steps:
1. Backend:
   - `settings.py` pisahkan `base.py`, `dev.py`, `prod.py`
   - Production: `DEBUG=False`, `ALLOWED_HOSTS`, `SECURE_*` flags,
     Whitenoise untuk static
   - `collectstatic` jalan tanpa error
   - `gunicorn martabak.wsgi:application --bind 0.0.0.0:8000` jalan
2. Buat `deploy.sh` script: git pull, venv, migrate, collectstatic,
   restart services
3. Tulis `DEPLOYMENT.md` step-by-step untuk user:
   - Setup VPS Ubuntu 22.04
   - Install PostgreSQL, create db & user
   - Install Python 3.11, venv, deps
   - Setup Nginx config (reverse proxy, SSL via Certbot)
   - Setup systemd service untuk Gunicorn
   - Pointing subdomain ke VPS IP
4. Frontend: build APK release (`flutter build apk --release`)
5. Backup script: `backup.sh` untuk `pg_dump` harian

Deliverable: deployment guide lengkap, app siap push ke VPS.

═══════════════════════════════════════════════════════════════════
PEDOMAN KERJA
═══════════════════════════════════════════════════════════════════

- COMMIT setiap phase selesai. Pesan commit bahasa Inggris, format
  konvensional: `phase(N): <apa yang dikerjakan>`
- Jangan batch banyak phase dalam 1 commit
- Sebelum commit, PASTIKAN test pass dan code linter bersih
- Kalau ada pilihan library, jelaskan trade-offnya, jangan langsung pilih
- Kalau ada requirement ambigu yang TIDAK ada di spec, BERHENTI dan tanya
  user. Jangan asumsi.
- Kalau ketemu bug, fix immediately, jangan defer
- Code harus clean, commented secukupnya (JANGAN over-comment)
- Type hints di Python (mypy-friendly), null-safety di Dart
- ENV var wajib, JANGAN hardcode secret/URL apapun
- BACKUP state database sebelum migration destruktif
- Pakai conventional commits: feat:, fix:, refactor:, test:, docs:

═══════════════════════════════════════════════════════════════════
KRITERIA SELESAI
═══════════════════════════════════════════════════════════════════

Project dianggap selesai SEMUA phase di atas DAN:
✓ Semua test pass (backend coverage > 70%)
✓ APK release bisa diinstall di Android & connect ke API
✓ API bisa di-deploy ke VPS sesuai DEPLOYMENT.md
✓ README.md jelas cara run lokal (dev) & production (deploy)
✓ Spec file di-commit
✓ Zero hardcoded secret/credential
```

---

## CARA PAKAI

### Di droid CLI (Factory):
```bash
cd app-martabak
droid  # atau sesuai command di environment kamu
# paste prompt MASTER PROMPT di atas
```

### Di opencode CLI:
```bash
cd app-martabak
opencode
# pilih mode interactive, paste prompt MASTER PROMPT
```

### Tips
- **Pecah per phase** kalau agent kewalahan: paste MASTER PROMPT, lalu
  setelah phase N selesai, paste prompt lanjutan "Lanjut ke phase N+1"
- **Selalu referensi spec**: agent harus baca spec sebelum ngerjain
- **Tanya balik kalau ambigu**: agent diinstruksikan berhenti & tanya,
  bukan ngarang

---

## CHECKLIST SEBELUM MULAI

Pastikan:
- [ ] Spec file `2026-07-29--martabak-app-design.md` sudah di-review
- [ ] Spec file di-commit ke git
- [ ] Folder structure kosong (belum ada kode)
- [ ] GoQris API key sudah di-daftar di https://goqris.web.id
- [ ] GoQris BaseQR (QR statis) sudah di-setup di dashboard
- [ ] VPS sudah disewa (untuk phase 10)
- [ ] Subdomain sudah di-pointing (atau siap dipointing)
- [ ] Android SDK terinstall untuk testing emulator
- [ ] Python 3.11+ terinstall
- [ ] Flutter SDK terinstall (versi stable terakhir)
- [ ] PostgreSQL terinstall lokal (untuk dev)
- [ ] Git terinstall

---

## TROUBLESHOOTING UMUM

| Masalah | Solusi |
|---|---|
| Agent skip phase | Re-paste MASTER PROMPT, eksplisit "Jangan skip phase" |
| Agent ngubah spec | Ingatkan: spec adalah source of truth, tanya user kalau mau ubah |
| Agent stuck di error | Minta agent tampilkan full error + stack trace + apa yang sudah dicoba |
| Test fail | Minta agent fix sebelum lanjut, jangan disable test |
| Library conflict | Minta agent jelaskan trade-off, pilih yang paling ringan |
| Ingin ubah scope | Update spec file DULU, baru re-paste MASTER PROMPT |

---

Setelah MVP jadi dan deployed, kita bisa brainstorm iterasi berikutnya
(multi-outlet, struk digital, dll) menggunakan spec yang sama sebagai
foundation.
