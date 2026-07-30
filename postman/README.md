# Postman Collection

## Files

- `App-Martabak-API.json` - API collection
- `App-Martabak-Environment.json` - Environment variables

## Import Instructions

### 1. Import Collection
1. Open Postman
2. Click **Import**
3. Select `App-Martabak-API.json`

### 2. Import Environment
1. Click **Environments** (gear icon)
2. Click **Import**
3. Select `App-Martabak-Environment.json`
4. Select "App Martabak Environment" from dropdown

### 3. Set Active Environment
1. Click environment dropdown (top-right)
2. Select **App Martabak Environment**

## Usage

### Auto-set Token
Login requests have a test script that automatically sets `accessToken` and `refreshToken` variables.

1. Run **Login PIN (Owner)** or any login request
2. Token is automatically saved to environment variable
3. Subsequent requests will use the token automatically

### Manual Token Set
If token doesn't auto-set:
1. Run login request
2. Copy `access` value from response
3. In environment, set `accessToken` = copied value

## Test Credentials

| Role | Username | PIN |
|------|----------|-----|
| Owner | `owner` | `000000` |
| Kasir | `Budi` | `1234` |
| Kasir | `Andi` | `1234` |

## Collection Structure

```
App Martabak API
├── Health
│   └── Health Check
├── Authentication
│   ├── Login PIN (Owner)
│   ├── Login PIN (Kasir Budi)
│   ├── Login PIN (Kasir Andi)
│   ├── Get Me (Current User)
│   └── Change PIN
├── Menus
│   ├── List Menu (Public)
│   ├── List All Menu (Owner Only)
│   ├── Create Menu (Owner Only)
│   ├── Update Menu (Owner Only)
│   └── Delete Menu (Owner Only - Soft Delete)
├── Orders
│   ├── Create Order
│   ├── List Orders (Me)
│   ├── List All Orders (Owner Only)
│   ├── Get Order Detail
│   ├── Queue (Pending & Paid Orders)
│   ├── Check Order Status
│   └── Cancel Order (Owner Only)
├── Kasirs (Owner Only)
│   ├── List Kasirs
│   ├── Create Kasir
│   ├── Update Kasir
│   ├── Delete Kasir (Soft Delete)
│   └── Reset PIN Kasir (Owner Only)
├── Settings (Owner Only)
│   ├── Get Settings
│   └── Update Settings
└── GoQris (Owner Only)
    └── Get Profile
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `baseUrl` | API base URL | `http://localhost:8000/api/v1` |
| `accessToken` | JWT access token | `eyJ...` |
| `refreshToken` | JWT refresh token | `eyJ...` |

## Rate Limiting

Some endpoints have rate limiting. If you get 429 errors:
- Wait ~1 minute and retry
- Or use different test accounts

## GoQris Setup

1. Daftar di https://goqris.web.id
2. Set API key di `.env`: `GOQRIS_API_KEY=GO_your_key`
3. Set project name via API:
   ```
   PATCH /api/v1/settings/
   {"goqris_project_name": "Nama Toko Anda"}
   ```
4. Cek status: `GET /api/v1/goqris/profile/`

## Related

- [API Endpoints](../backend/api-endpoints.md)
- [Backend Setup](../backend/setup.md)
