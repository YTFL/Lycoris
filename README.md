# 🌺 Lycoris — Personal Gaming Ledger & Vault

Lycoris is an offline-first personal gaming ledger and vault built with Flutter, Riverpod, and Hive. It connects to the IGDB v4 API via a dedicated Cloudflare Worker proxy, backed up securely to user-owned Google Drive AppData storage.

---

## ✨ Features

- **Offline-First Vault**: Fast local storage with Hive NoSQL box (`games_vault`) with zero loading latency.
- **Dual Display Modes**:
  - **The Shelf (Cover Grid)**: Responsive 3:4 box art cards with dynamic gradient vignettes and glowing ROI badges.
  - **The Ledger (Compact List)**: Dense tabular view for quick auditing of hours, prices, ratings, and ROI.
- **Multi-Storefront Ownership**: Composite key architecture (`${igdbId}_${storefront.name}`) allows owning the same game on multiple platforms (Steam, Epic, Switch, PS, GOG, itch.io, Physical) with separate spend and playtime tracking.
- **3-Mode Playtime Normalizer**: Input time as **Hours + Mins**, **Decimal Hours**, or **Pure Minutes** with live canonical conversion and formatting.
- **Financial Investment & ROI Engine**:
  - Itemized DLC, Season Pass, and microtransaction ledger with instant cost recalculations.
  - Value Tiers: **Free / Gift**, **Unplayed**, **Great Value** (≤ \$1.00/hr), **Fair Value** (≤ \$3.50/hr), **Costly** (> \$3.50/hr).
- **Multi-Currency Normalizer**: Set a Primary Display Currency (USD, EUR, GBP, INR, JPY, CAD, AUD) for unified analytics aggregation without raw addition errors.
- **Cloudflare Worker Proxy (IGDB v4)**:
  - Proxies APICalypse queries securely to `api.igdb.com/v4/games`.
  - Caches Twitch OAuth2 tokens server-side.
  - Included template in [`cloudflare-worker/`](cloudflare-worker/).
- **Manual / Indie Game Entry Fallback**: Add non-IGDB indie titles, retro ROM hacks, or custom projects with manual cover art and metadata.
- **Google Drive Sync & Offline JSON**:
  - Transparent backup directly to a dedicated `Lycoris/` folder in your Google Drive (visible and accessible in your Drive).
  - Conflict-free **Last-Write-Wins (LWW)** delta synchronization based on `updatedAt`.
  - Direct offline JSON export/import and clipboard backup.
- **Analytics & ROI Stats**:
  - Storefront spend distribution interactive donut chart powered by `fl_chart`.
  - Best ROI Leaderboard & Most Played Time Sinks.
  - Backlog Investment tracking.

---

## 🏗️ Architecture

```
lib/
├── core/
│   ├── constants/
│   │   ├── colors.dart               # Lycoris Crimson, Obsidian, Slate
│   │   └── api_constants.dart
│   ├── storage/
│   │   ├── hive_registrar.dart       # Adapter initialization & Box management
│   │   └── hive_adapters.dart
│   └── utils/
│       ├── time_normalizer.dart      # Canonical minutes conversion
│       ├── value_metric_evaluator.dart # ROI tiers & cost/hr
│       └── currency_converter.dart   # Multi-currency normalization
├── features/
│   ├── tracker/
│   │   ├── domain/models/            # Storefront, GameStatus, AdditionalExpense, GameEntry
│   │   ├── data/game_repository.dart # Hive box CRUD, duplicates, seed library
│   │   └── presentation/             # VaultScreen, DossierScreen, CoverCard, LedgerRow
│   ├── search/
│   │   ├── data/igdb_service.dart    # APICalypse Dio client, proxy & mock fallback
│   │   └── presentation/             # ManualGameModal
│   ├── analytics/
│   │   └── presentation/             # AnalyticsDashboard & FL Chart donut
│   └── sync/
│       ├── data/                     # SettingsRepository, DriveVaultService
│       └── presentation/             # SettingsScreen & backup controls
└── main.dart
```

---

## 🚀 Cloudflare Worker Setup

Deploy the proxy in `cloudflare-worker/` to handle Twitch OAuth2 tokens:

```bash
cd cloudflare-worker
npm install -g wrangler
wrangler login
wrangler secret put TWITCH_CLIENT_ID
wrangler secret put TWITCH_CLIENT_SECRET
wrangler deploy
```

Then in Lycoris, go to **Settings > Cloudflare Worker Proxy URL**, paste your worker URL, and tap **Test Connection**.

---

## 🚀 Running & Building

Copy `.env.example` to `.env` and fill in your Google Cloud OAuth credentials:
```bash
cp .env.example .env
```

### Run Locally:
```bash
flutter run --dart-define-from-file=.env
```

### Build Release APK:
```bash
flutter build apk --release --dart-define-from-file=.env
```

---

## 🧪 Testing

Run the test suite:
```bash
flutter test
```
All unit and widget tests verify time normalization, value metrics, currency conversions, composite keys, and LWW delta sync.

