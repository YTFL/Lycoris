# 🌺 Lycoris — Personal Gaming Library & ROI Tracker

<p align="center">
  <img src="assets/icons/icon_transparent.png" alt="Lycoris Logo" width="128" height="128">
</p>

<p align="center">
  <strong>Know what your playtime is actually worth.</strong><br>
  An offline-first personal gaming library, backlog manager, and financial ROI tracker for sovereign gamers.
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://pub.dev/packages/hive"><img src="https://img.shields.io/badge/Storage-Hive%20NoSQL-FFA000?logo=dart&logoColor=white" alt="Hive NoSQL"></a>
  <a href="https://developers.google.com/drive"><img src="https://img.shields.io/badge/Sync-Google%20Drive-4285F4?logo=googledrive&logoColor=white" alt="Google Drive"></a>
  <a href="docs/privacy.html"><img src="https://img.shields.io/badge/Privacy-Zero%20Telemetry-10B981" alt="Zero Telemetry"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-AGPL--3.0-E53935?logo=gnu" alt="AGPL-3.0 License"></a>
</p>

---

## 🌟 Why Lycoris?

Modern gaming is fragmented. We own games across **Steam, Nintendo Switch, PlayStation, Xbox, GOG, and itch.io**. Between seasonal sales, subscription bundles, microtransactions, and DLC passes, two critical questions are almost impossible to answer:

1. *How much have I actually invested in this game across all platforms?*
2. *Was it actually worth the price based on how many hours I enjoyed playing it?*

Most existing game trackers force you to create cloud accounts, load sluggish web views, or sell your gaming habits to advertising networks. 

**Lycoris changes that.** It is a fast, offline-first personal library and tracker that organizes your multi-storefront ownership, itemizes every dollar spent on DLCs, and automatically calculates your real **cost-per-hour return on investment (ROI)**—all backed up safely to your own personal Google Drive.

---

## ✨ Features at a Glance

### 🌺 Dual Display Modes
- **The Shelf (Visual Box Art Grid)**: Responsive 3:4 game cover art cards with dynamic gradient vignettes and glowing ROI tier badges.
- **The List View (Clean Compact View)**: Dense, high-information table for quickly reviewing storefronts, logged hours, itemized costs, ratings, and $/hour efficiency.

### 💎 Financial ROI & Value Tier Engine
Every game calculates an effective cost-per-hour (`Total Investment ÷ Total Hours`):
- 💜 **Free / Gift**: Free-to-play, gifted, or inherited titles ($0.00 spend).
- 🔘 **Unplayed Backlog**: Games waiting in your queue to be experienced.
- 🟢 **Great Value (≤ $1.00/hr)**: Legendary mileage where every dollar gave you maximum entertainment.
- 🔵 **Fair Value (≤ $3.50/hr)**: Healthy return on investment, typical of solid single-player campaigns.
- 🟡 **Costly (> $3.50/hr)**: High initial investment or early-abandoned titles.

### 🛒 Itemized DLC & Microtransaction Tracking
Track season passes, cosmetic bundles, story expansions, and microtransactions independently. Lycoris automatically recalculates your game's total cost and real-time cost/hour as your spending evolves.

### 🎮 Multi-Storefront Composite Ownership
Own *Elden Ring* on Steam and *Hollow Knight* on Switch, but also double-dipped on PC? Lycoris uses composite keys (`${igdbId}_${storefront}`) so you can track each platform's purchase price, platform-specific playtime, and notes separately without collision.

### ⏱️ 3-Mode Playtime Normalizer
Input your playtime in whatever format you prefer:
- **Hours + Minutes** (e.g. `14h 30m`)
- **Decimal Hours** (e.g. `14.5 hrs`)
- **Pure Minutes** (e.g. `870 mins`)
All inputs live-sync to a canonical format with zero conversion drift.

### 🌐 Multi-Currency Normalizer
Track purchases in their native currency (USD, EUR, GBP, INR, JPY, CAD, AUD) while standardizing aggregate library analytics into your chosen Primary Display Currency.

### 📊 Interactive Analytics Dashboard
- Storefront spending distribution donut chart.
- Best ROI Leaderboard & Most Played Time Sinks.
- Backlog Capital investment tracking.

---

## 🔒 Privacy & Your Data (Sovereignty First)

Lycoris is engineered on the principle that **you own your data**:

| Storage Layer | Location | Details |
| :--- | :--- | :--- |
| **Local Device Storage** | On your phone (`Hive NoSQL`) | 100% offline. Instant loading. No account creation required. |
| **Google Drive Cloud Sync** | Your Personal Google Drive | Opt-in backup using restricted `drive.file` scope. |
| **IGDB Metadata Proxy** | Cloudflare Worker Edge | Proxies game covers and search queries anonymously. Zero logging. |

### 🛡️ How Google Drive Sync Works:
- **Restricted Access (`drive.file`)**: Lycoris **only** has permission to access the files and folders it creates itself. It is technically impossible for Lycoris to view, read, or modify your personal photos, emails, spreadsheets, or other Drive files.
- **Dedicated Folder**: Backups are saved in an open JSON file at `Lycoris/lycoris_vault_backup.json` in your Google Drive root.
- **Delta Conflict Resolution**: Uses Last-Write-Wins (LWW) based on ISO-8601 timestamps to sync changes cleanly across devices.
- **Google API Limited Use Compliance**: We strictly adhere to the [Google API Services User Data Policy](https://developers.google.com/terms/api-services-user-data-policy), ensuring your data is never transferred, sold, or used for AI training.

---

## 📱 Quick Start for Gamers

1. **Download APK**: Grab the latest release APK from the [Releases](https://github.com/YTFL/Lycoris/releases) page and install it on your Android device.
2. **Add Your Games**: Tap `+` to search over 300,000+ titles via IGDB, or use the **Manual Entry** modal for indie games and retro ROMs.
3. **Log Playtime & Spend**: Enter your purchase price, storefront, and playtime to immediately reveal your ROI tier!
4. **(Optional) Enable Google Drive Sync**:
   - Go to **Settings > Google Drive Backup**.
   - Tap **Sign in with Google**.
   - Tap **Backup Now** to create your private cloud archive.

---

## 🛠️ Developer & Self-Hosting Guide

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`^3.12.2` or later)
- Android Studio / Android SDK
- (Optional) Cloudflare Wrangler CLI for self-hosting the IGDB proxy

### 1. Clone & Install Dependencies
```bash
git clone https://github.com/YTFL/Lycoris.git
cd Lycoris
flutter pub get
```

### 2. Configure Environment
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Fill in your Google Cloud OAuth Client ID (for Drive sync) and project ID:
```env
GOOGLE_CLIENT_ID=your-android-client-id.apps.googleusercontent.com
GOOGLE_PROJECT_ID=your-google-project-id
```

### 3. Run Locally
```bash
flutter run --dart-define-from-file=.env
```

### 4. Build Release APK
```bash
flutter build apk --release --dart-define-from-file=.env
```

### 5. (Optional) Deploy Cloudflare Worker Proxy
The proxy in `cloudflare-worker/` handles IGDB v4 APICalypse queries and securely caches Twitch OAuth tokens:
```bash
cd cloudflare-worker
npm install -g wrangler
wrangler login
wrangler secret put TWITCH_CLIENT_ID
wrangler secret put TWITCH_CLIENT_SECRET
wrangler deploy
```
Then paste your worker URL in Lycoris under **Settings > Cloudflare Worker Proxy URL**.

### 6. Run Test Suite
```bash
flutter test
```
All unit and widget tests verify time normalization, currency conversions, composite keys, and LWW delta sync.

---

## 📄 Documentation & Legal

- 🌐 **[Product Website](docs/index.html)** — Interactive showcase, Shelf vs. List view preview, and live ROI calculator.
- 🔒 **[Privacy Policy](docs/privacy.html)** — Detailed Google Drive Limited Use disclosure and data handling policies.
- ⚖️ **[Terms of Service](docs/terms.html)** — Open source license and usage terms.

---

## 📜 License & Acknowledgements

- **License**: Released under the [GNU Affero General Public License v3.0 (AGPL-3.0)](LICENSE).
- **Game Metadata**: Game information and box art are retrieved from the [IGDB.com](https://www.igdb.com) API, a service of Twitch Interactive, Inc.
- **Built With Love**: Flutter, Hive, Riverpod, and Google APIs.
