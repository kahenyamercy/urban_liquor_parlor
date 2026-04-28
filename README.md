# 🍾 Urban Liquor Parlor

> **Kayole's corner store, now in your pocket.**  
> A Flutter + Supabase mobile app that takes Urban Liquor Parlor from WhatsApp orders and handwritten ledgers to a fully digital storefront — with real-time order tracking, live inventory, and boda boda dispatch.

---

## 📱 What Is This?

Urban Liquor Parlor is a single-store Android app built for a real liquor shop in Kayole, Nairobi. Before this app, the store ran entirely on phone calls, WhatsApp messages, and handwritten stock books — missed orders on busy Fridays, unrecorded payments, and wrong deliveries were a weekly headache.

This app fixes that. Customers browse and order from their phone. The owner confirms and dispatches from a live dashboard. Riders get their assignments instantly. Every order, every payment, every stock movement — recorded automatically in Supabase.

---

## ✨ Features

| # | Feature | Who Uses It |
|---|---------|-------------|
| F1 | **Product Catalogue** — Browse by category with photos, prices, and live stock | Customer |
| F2 | **Cart & Checkout** — Add items, choose delivery or pickup, confirm order | Customer |
| F3 | **Order Tracking** — Live status: Received → Confirmed → Out for Delivery → Delivered | Customer |
| F4 | **Admin Order Dashboard** — See all orders in real time, confirm and dispatch | Admin |
| F5 | **Product & Stock Manager** — Add/edit products, update stock, low-stock alerts | Admin |
| F6 | **Daily Sales Summary** — Total orders and revenue on the admin home screen | Admin |

---

## 👥 User Roles

```
Customer       →  Browse, order, track delivery, view history
Admin          →  Manage products, confirm orders, view sales
Delivery Rider →  View assigned orders, mark as delivered
```

---

## 🗂️ App Screens

```
├── Splash / Welcome
├── Login / Register
├── Home — Product Categories        (Customer)
├── Product Listing                  (Customer)
├── Product Detail                   (Customer)
├── Cart & Checkout                  (Customer)
├── Order Tracking                   (Customer)
├── Admin Dashboard                  (Admin)
├── Admin Product Manager            (Admin)
└── Admin Order Manager              (Admin)
```

---

## 🛠️ Tech Stack

```
Flutter (Dart)        All screens, navigation, logic — one language for everything
Supabase PostgreSQL   Products, orders, users — all data lives here
Supabase Auth         Customer and admin login / register
Supabase Realtime     Live order status updates without refresh (WebSocket)
Supabase Storage      Product photos stored in the cloud
flutter build apk     One command → deployable Android APK
```

---

## 🗃️ Database Schema

```sql
products      (id, name, category, price, stock, image_url)
orders        (id, customer_id, total, status, delivery_address)
order_items   (id, order_id, product_id, quantity, unit_price)
profiles      (id, full_name, phone, role)
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0` installed and on PATH
- Android phone with USB Debugging enabled
- Supabase project set up with the 4 tables above

### Clone and install

```bash
git clone https://github.com/yourusername/urban_liquor_parlor.git
cd urban_liquor_parlor
flutter pub get
```

### Configure Supabase

Create a `.env` file or update `lib/main.dart` with your project credentials:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### Run on your phone

Connect your Android phone via USB, then:

```bash
flutter devices        # confirm your phone is detected
flutter run            # build and launch on device
```

Hot reload: press `r` · Hot restart: press `R` · Quit: press `q`

### Build a release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
```

---

## 🗓️ Build Plan

| Week | Focus |
|------|-------|
| 1–2 | Flutter basics — screens, navigation, Dart fundamentals |
| 3 | Supabase setup — 4 tables, connect Flutter with Supabase keys |
| 4 | Customer screens — Home, listing, detail, cart |
| 5 | Auth + order system — login, register, place orders |
| 6 | Order tracking — live status via Supabase Realtime |
| 7 | Admin panel — dashboard, order management, stock alerts |
| 8 | Test + APK — real device testing, bug fixes, final build |

---

## 📁 Project Structure

```
lib/
├── main.dart
├── screens/
│   ├── splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── customer/
│   │   ├── home_screen.dart
│   │   ├── product_listing_screen.dart
│   │   ├── product_detail_screen.dart
│   │   ├── cart_screen.dart
│   │   └── order_tracking_screen.dart
│   └── admin/
│       ├── admin_dashboard_screen.dart
│       ├── admin_product_manager_screen.dart
│       └── admin_order_manager_screen.dart
├── models/
│   ├── product.dart
│   ├── order.dart
│   └── profile.dart
└── services/
    └── supabase_service.dart
```

---

## 🏪 The Real Problem This Solves

| Before | After |
|--------|-------|
| Orders via WhatsApp and phone calls | Customer places order in the app |
| Handwritten ledger books | Every transaction recorded in Supabase |
| No inventory system | Live stock levels with low-stock alerts |
| Verbal boda boda dispatch | Rider sees assignment instantly on their phone |
| Missed orders during network outages | Orders queued and confirmed via dashboard |
| Stock discrepancies on busy Fridays | Real-time stock deduction on every order |

---

## 👨‍💻 Built With

- **Flutter** — [flutter.dev](https://flutter.dev)
- **Supabase** — [supabase.com](https://supabase.com)
- **Dart** — [dart.dev](https://dart.dev)

---

## 📄 License

This project is for educational purposes — a school project submission.  
Built for Urban Liquor Parlor, Kayole, Nairobi. 🇰🇪