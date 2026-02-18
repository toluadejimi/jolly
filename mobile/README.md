# Gift Store – Flutter app

Mobile app for the Giftfr Laravel backend. Browse products and track orders by order number.

## Requirements

- Flutter SDK 3.0+
- Backend running (Laravel app with API)

## Setup

1. **Clone / open project**
   ```bash
   cd mobile
   flutter pub get
   ```

2. **Set server URL (tunnel or local)**

   So the app can reach your backend (stops endless loading on a real device):

   - **Option A – Tunnel (recommended for wireless device):**  
     From the project root (giftfr/), run:
     ```bash
     chmod +x tunnel.sh && ./tunnel.sh
     ```
     Use **ngrok** if installed, or **npx localtunnel** (Node.js). Copy the HTTPS URL, add `/giftfr/core/public`, then in the app tap **Settings (gear)** → paste as **Base URL** → **Save**. Example: `https://abc123.ngrok-free.app/giftfr/core/public`

   - **Option B – In-app:** Open the app → tap the **gear icon** → paste your tunnel or local URL (e.g. `http://192.168.1.x/giftfr/core/public`) → **Save**.

3. **Run**
   ```bash
   flutter run
   ```

## Features

- **Browse products** – List and detail from `GET /api/products` and `GET /api/products/{id}`.
- **Track order** – Enter order number, get status, estimated delivery range, tracking number and tracking link from `GET /api/order-tracking/{orderNumber}`.

## Backend API used

| Endpoint | Auth | Description |
|----------|------|-------------|
| `GET /api/products` | No | Paginated product list (optional: category_id, brand_id, search) |
| `GET /api/products/{id}` | No | Product detail |
| `GET /api/order-tracking/{orderNumber}` | No | Order tracking (status, estimated delivery, tracking URL/number) |

For **orders list**, **order detail**, and **checkout** you need an API key from the user dashboard (API Keys). The app is prepared to send `X-API-Key` and `Authorization: Bearer <key>` once you add a login/settings screen where the user can paste their key.

## Project structure

```
lib/
├── config/
│   └── api_config.dart    # Base URL and optional API key
├── models/
│   ├── api_response.dart
│   ├── order_tracking.dart
│   └── product.dart
├── screens/
│   ├── home_screen.dart
│   ├── product_list_screen.dart
│   ├── product_detail_screen.dart
│   └── track_order_screen.dart
├── services/
│   └── api_service.dart   # HTTP calls to backend
└── main.dart
```

## Next steps (optional)

- Add API key input (e.g. in profile/settings) to call orders and payment endpoints.
- Add login/register if the backend gets token-based auth (e.g. Laravel Sanctum).
- Add cart and checkout screens when corresponding API endpoints are available.
- Add product images (backend already returns image data; use `cached_network_image` with your image URL pattern).
