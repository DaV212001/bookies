# Bookies 📖✨

> A modern, social EPUB reading client built with Flutter, Clean Architecture, and real-time co-presence. Experience books together with synchronized participant tracks, floating passage reactions, contextual community discussions, and instant catalog ingestion.

---

## 🌟 Overview

**Bookies** reimagines digital reading as a shared, collaborative experience without sacrificing the quiet intimacy of solo reading. Readers can explore contemporary and classic titles, download EPUBs directly from catalog streams, synchronize reading locations across devices, and join live reading sessions where fellow readers appear as ambient avatars along the progress bar.

### Core Highlights

- 📚 **Immersive Reader Engine**: Fluid EPUB pagination powered by epub.js / foliate-js integration with exact Canonical Fragment Identifier (`CFI`) tracking.
- 🎨 **Adaptive Reading Themes**: Carefully curated palettes—*Parchment*, *Warm Sepia*, *Charcoal*, and true *OLED Black*—with dynamic typography and font scaling.
- 👥 **Real-time Live Reading Co-presence**: See co-readers reading alongside you in real-time. Participant avatars glide across the ambient progression track as they turn pages.
- 🔥 **Live Passage Reactions**: Non-intrusive, floating emoji reaction bubbles anchored to specific paragraphs and CFIs in the text.
- 🛡️ **Role-Based Community Governance**: Create reading clubs, assign Admin/Moderator privileges, restrict disruptive users with reasoned timeouts, and curate book-specific clubs.
- 💬 **Contextual Discussions & Quote Annotations**: Start chapter-level or passage-level discussion threads with upvoting, quote ratings, and real-time chat replies.
- 🔐 **Dual Auth Flow**: Seamless email/password authentication and Google Single Sign-On (SSO) with auto-persisted JWT tokens.

---

## 🏗️ Architecture & System Design

Bookies adheres strictly to **Clean Architecture** principles to guarantee separation of concerns, testability, and backend platform independence.

```
┌─────────────────────────────────────────────────────────────────┐
│                       PRESENTATION LAYER                        │
│   • Views: lib/features/*/views/ (Widgets, Screens, Dialogs)    │
│   • State: lib/features/*/bloc/  (BLoCs, Events, States)        │
│   RULE: Presentation ONLY communicates with Domain Repositories │
└────────────────────────────────┬────────────────────────────────┘
                                 │ Dispatches / Observes
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER (Pure Dart)                  │
│   • Entities:     lib/domain/entities/ (Equatable data classes) │
│   • Repositories: lib/domain/repositories/ (Abstract contracts) │
│   • Failures:     lib/domain/failures/ (Domain error models)    │
│   RULE: Pure Dart. ZERO dependencies on Flutter UI, Dio, or DB  │
└────────────────────────────────▲────────────────────────────────┘
                                 │ Implements
┌────────────────────────────────┴────────────────────────────────┐
│                          DATA LAYER                             │
│   • DTOs:         lib/data/models/ (JSON serialization)         │
│   • Data Sources: lib/core/network/ (ApiClient, SocketService)  │
│   • Repos:        lib/data/repositories/ (API & Local Cache)    │
│   RULE: Coordinates remote NestJS backend & local storage cache │
└─────────────────────────────────────────────────────────────────┘
```

### Architectural Invariants
1. **Zero UI-Data Leakage**: Widgets never access raw network clients or SQLite/SharedPreferences directly. All actions flow through BLoC events.
2. **Pure Domain Entities**: Entities in `lib/domain/entities/` are immutable and have no serialization logic or Flutter dependencies.
3. **Resilient Offline Fallback**: In the absence of network connectivity or auth tokens, the repository layer automatically falls back to local cached models.
4. **Text-Only Co-Presence**: Live reading uses presence indicators and reaction bubbles; no voice/audio streams are permitted to preserve reading focus.

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── network/             # Dio ApiClient & SocketService (Socket.IO client)
│   ├── routing/             # GoRouter declarations & deep links
│   ├── theme/               # Reader palettes, typography & ThemeCubit
│   ├── utils/               # AppLogger, debouncers, helpers
│   └── widgets/             # Reusable UI (AmbientProgressBar, PassageReactionBubble, Dialogs)
├── data/
│   ├── models/              # Data models with fromJson/toJson serialization
│   ├── providers/           # LocalDataService (SharedPreferences & cache manager)
│   └── repositories/        # Concrete implementations of Domain repositories
├── domain/
│   ├── entities/            # Pure domain entities (Book, User, Community, LiveSession)
│   ├── failures/            # Typed domain failures
│   └── repositories/        # Abstract repository contracts (Auth, Catalog, Community, etc.)
├── features/
│   ├── auth/                # Login, Register, Google SSO views & AuthBloc
│   ├── community/           # Community roster, moderation dialogs & CommunityBloc
│   ├── discover/            # Catalog browsing, genre filtering, search & CatalogBloc
│   ├── reader/              # EPUB Foliate reader, social presence track & ReaderBloc
│   └── settings/            # Appearance, typography & cache settings
└── main.dart                # Dependency injection & MultiRepositoryProvider root
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: `>= 3.24.0`
- **Dart SDK**: `>= 3.5.0`
- **Bookies NestJS Backend**: Running locally on `http://localhost:3000` (or configured remote URL).

### 1. Clone & Install Dependencies

```bash
git clone https://github.com/DaV212001/bookies.git
cd bookies
flutter pub get
```

### 2. Configure Backend Endpoint

By default, the application connects to the local NestJS backend at `http://localhost:3000/api/v1` (with WebSocket fallback for Android emulators at `10.0.2.2:3000`). To configure a production or remote backend:

```bash
flutter run --dart-define=API_BASE_URL=https://api.bookies.example.com/api/v1 \
            --dart-define=WS_BASE_URL=wss://api.bookies.example.com
```

### 3. Run Application

```bash
# Run on connected device or emulator
flutter run
```

---

## 🧪 Testing & Verification

Bookies maintains rigorous automated testing with full flow integration suites covering end-to-end user journeys:

### Run Full Test Suite

```bash
flutter test
```

### Run End-to-End Flow Integration Tests

```bash
flutter test test/integration/full_flow_integration_test.dart
```

#### Covered Integration Journeys:
- **Flow 1: Authentication & User Lifecycle**: Registration, JWT persistence, profile queries, logout, email/password login, and Google SSO.
- **Flow 2: Discover Catalog & Ingestion**: Trending catalog queries, genre filtering, real-time search, streaming EPUB downloads, and library importing.
- **Flow 3: Community Lifecycle & Moderation RBAC**: Club creation, member joining, roster queries, role escalation (Member $\rightarrow$ Admin), and reasoned member restrictions.
- **Flow 4: Live Reading Co-Presence & Reactions**: Book loading, ambient progression sync, live participant roster tracking, and floating passage reaction broadcasts.

### Run Static Analysis

```bash
flutter analyze --no-pub lib test
```

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
