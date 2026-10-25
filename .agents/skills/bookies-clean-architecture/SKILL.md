---
name: bookies-clean-architecture
description: >-
  Standard architecture guidelines, compliance checklists, and layer boundaries for modifying,
  adding features, or debugging the Bookies Flutter codebase. Use whenever implementing or updating
  features in Bookies to ensure Clean Architecture compliance, NestJS backend compatibility, and zero layer leakage.
---

# Bookies Clean Architecture Standard Operating Procedure

This skill governs all architectural patterns, layer boundaries, and code modifications for the **Bookies** application. Every future feature, bug fix, or refactor MUST comply with these rules.

---

## 1. The Core Architectural Hierarchy

```
┌───────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                         │
│   • lib/features/<feature>/views/ (Widgets, Screens, Dialogs) │
│   • lib/features/<feature>/bloc/  (BLoCs, Cubits, Events)     │
│   RULE: ONLY talks to Domain Repositories/UseCases or BLoC    │
└───────────────────────────────┬───────────────────────────────┘
                                │ Uses
                                ▼
┌───────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER (Pure)                      │
│   • lib/domain/entities/     (Pure Dart data classes)         │
│   • lib/domain/repositories/ (Abstract repository contracts)  │
│   • lib/domain/failures/     (Domain Failure classes)         │
│   RULE: ZERO dependencies on Flutter UI, Dio, or DB drivers   │
└───────────────────────────────▲───────────────────────────────┘
                                │ Implements
┌───────────────────────────────┴───────────────────────────────┐
│                       DATA LAYER                              │
│   • lib/data/dtos/           (fromJson / toJson models)       │
│   • lib/data/datasources/    (Remote API, Socket.IO, Storage) │
│   • lib/data/repositories/   (Concrete Repository Impls)      │
│   RULE: Coordinates remote network and local cache            │
└───────────────────────────────────────────────────────────────┘
```

---

## 2. Strict Architectural Invariants (DO NOT VIOLATE)

> [!CAUTION]
> **1. NO RAW DATA ACCESS FROM WIDGETS**:
> Never call `context.read<LocalDataService>()`, `context.watch<LocalDataService>()`, or any concrete data source from a `Widget`, `StatefulWidget`, `Dialog`, or `BottomSheet`. All user interactions must dispatch an event to a **BLoC** or **Cubit**.
>
> **2. NO INFRASTRUCTURE IN BLOCS**:
> BLoCs must only orchestrate presentation state. Never put file copying (`File.copy`), regex path sanitization, 3rd-party parser execution (`FlutterReadium().loadPublication()`), or direct HTTP/DB calls inside a BLoC. Delegate these to the repository.
>
> **3. PURE DOMAIN ENTITIES**:
> Files in `lib/domain/entities/` must be pure Dart (extending `Equatable`). They must **never** import `flutter/material.dart`, `package:dio`, or define `fromJson`/`toJson` factory constructors. Serialization belongs strictly to Data DTOs in `lib/data/dtos/` or `lib/data/models/`.
>
> **4. NO VOICE / AUDIO CHAT**:
> Live reading is strictly text-based, synchronized location/progress, presence indicators, and live comments/reactions. Never add microphone/voice/audio widgets.
>
> **5. NESTJS & SOCKET.IO ALIGNMENT**:
> Real-time streaming for discussions and live reading must align with the NestJS `@WebSocketGateway`. Use `socket_io_client` in remote data sources; do not introduce conflicting real-time protocols.

---

## 3. Step-by-Step Feature Implementation Runbook

Whenever adding or updating a feature in Bookies, follow this exact 7-step sequence:

### Step 1: Define the Domain Entity
Create `lib/domain/entities/<entity_name>_entity.dart`:
```dart
import 'package:equatable/equatable.dart';

class BookEntity extends Equatable {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String? localPath;

  const BookEntity({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.localPath,
  });

  @override
  List<Object?> get props => [id, title, author, coverUrl, localPath];
}
```

### Step 2: Define Domain Repository Interface & Failures
Create `lib/domain/repositories/<name>_repository.dart` and `lib/domain/failures/failures.dart`:
```dart
abstract class BookRepository {
  Future<List<BookEntity>> getBooks();
  Future<BookEntity> importBook(String filePath);
  Future<void> updateReadingProgress(String bookId, String cfi, double progression);
}
```

### Step 3: Create Data Transfer Object (DTO)
Create `lib/data/models/` or `lib/data/dtos/` extending or mapping to the Domain Entity:
```dart
class BookModel extends BookEntity {
  const BookModel({
    required super.id,
    required super.title,
    required super.author,
    super.coverUrl,
    super.localPath,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) => BookModel(...);
  Map<String, dynamic> toJson() => {...};
}
```

### Step 4: Implement Data Sources
- **Remote Data Source**: Calls NestJS REST API via `Dio` or listens to Socket.IO events.
- **Local Data Source**: Reads/writes to `SharedPreferences`, `flutter_secure_storage`, or local file storage.

### Step 5: Implement Repository
In `lib/data/repositories/<name>_repository_impl.dart`, coordinate remote and local data sources, catch network exceptions, and map them to Domain `Failure`s.

### Step 6: Create or Update Presentation BLoC
Inject the abstract repository interface into the BLoC:
```dart
class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final BookRepository _bookRepository;

  LibraryBloc(this._bookRepository) : super(LibraryInitial()) { ... }
}
```

### Step 7: Build UI Views
Consume state using `BlocBuilder` or `BlocConsumer`. Trigger changes with `context.read<LibraryBloc>().add(...)`.

---

## 4. Verification Checklist Before Marking Done

- [ ] `flutter analyze` runs with 0 errors.
- [ ] `flutter test` passes 100% of tests.
- [ ] No `context.watch<LocalDataService>()` or `context.read<LocalDataService>()` added to views.
- [ ] All new network/socket calls are isolated inside `lib/data/datasources/`.
- [ ] No hardcoded mock IDs (e.g. `creatorId = 'user-1'`) in new logic; use authenticated `UserEntity`.
