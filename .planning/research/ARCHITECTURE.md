# Architecture Research

**Domain:** Local URL shortener — Flutter desktop app with embedded HTTP server
**Researched:** 2026-03-26
**Confidence:** HIGH (core patterns verified via official Dart/Flutter docs and pub.dev)

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Flutter Desktop Process                      │
│                                                                  │
│  ┌──────────────────────────────┐  ┌──────────────────────────┐ │
│  │        UI Layer              │  │     Server Isolate        │ │
│  │  ┌────────────────────────┐  │  │  ┌────────────────────┐  │ │
│  │  │   UrlShortenerWidget   │  │  │  │   shelf + Router   │  │ │
│  │  │  (paste URL, show      │  │  │  │  POST /shorten     │  │ │
│  │  │   short URL result)    │  │  │  │  GET  /<slug>      │  │ │
│  │  └──────────┬─────────────┘  │  │  └────────┬───────────┘  │ │
│  │             │                │  │           │               │ │
│  │  ┌──────────▼─────────────┐  │  │  ┌────────▼───────────┐  │ │
│  │  │   ServerController     │  │  │  │  UrlRepository     │  │ │
│  │  │  (start/stop/status)   │◄─┼──┼─►│  (read/write DB)   │  │ │
│  │  └────────────────────────┘  │  │  └────────────────────┘  │ │
│  └──────────────────────────────┘  └──────────────────────────┘ │
│                                                                  │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ SendPort/ReceivePort ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                   Database Layer                          │   │
│  │   drift NativeDatabase (WAL mode, background isolate)    │   │
│  │   urls table: id | slug | original_url | created_at      │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

External browser → http://localhost:8080/<slug> → Server Isolate → DB → 302 redirect
```

### Component Responsibilities

| Component | Responsibility | Implementation |
|-----------|----------------|----------------|
| `ServerController` | Start/stop server isolate, bridge UI ↔ server | Dart class using `Isolate.spawn` + `SendPort`/`ReceivePort` |
| Server Isolate | Accept HTTP requests, execute business logic | `shelf` + `shelf_router`, runs in background isolate |
| `UrlRepository` | All SQLite read/write operations | `drift` with `NativeDatabase.createInBackground()` |
| `UrlShortenerWidget` | Paste URL, trigger shortening, display result | Flutter widget, calls `ServerController` |
| Slug Generator | Produce random 6-char base62 slugs | Pure Dart utility function, no external dependency needed |

## Recommended Project Structure

```
lib/
├── main.dart                  # App entry point, starts ServerController
├── app.dart                   # MaterialApp, lifecycle observer
│
├── server/                    # Everything HTTP — runs in server isolate
│   ├── server_isolate.dart    # Isolate entry point (top-level function)
│   ├── router.dart            # shelf_router route definitions
│   ├── handlers/
│   │   ├── shorten_handler.dart   # POST /shorten → create slug, return short URL
│   │   └── redirect_handler.dart  # GET /<slug>  → look up, 302 redirect
│   └── server_message.dart    # Sealed classes for IPC messages
│
├── db/                        # Database — drift schema and queries
│   ├── database.dart          # AppDatabase, table definitions
│   ├── url_dao.dart           # Data Access Object: insertUrl, findBySlug
│   └── migrations.dart        # Schema migrations (v1 only for now)
│
├── controller/
│   └── server_controller.dart # Start/stop isolate, expose status stream
│
├── ui/
│   ├── shortener_screen.dart  # Main screen: input + result display
│   └── widgets/
│       └── short_url_card.dart # Shows generated URL + copy button
│
└── utils/
    └── slug_generator.dart    # Random 6-char base62 slug generation
```

### Structure Rationale

- **server/:** All HTTP logic lives here. This entire subtree runs inside the server isolate — isolating it prevents accidental UI framework calls from server code.
- **db/:** Drift generates type-safe query code from the schema. Keeping it separate lets both the server isolate and UI share the same database interface without coupling to HTTP or Flutter concerns.
- **controller/:** `ServerController` is the only object that knows about both the Flutter widget tree and the server isolate — it is the bridge, nothing else should be.
- **utils/:** Slug generation has no dependencies and can be tested standalone.

## Architectural Patterns

### Pattern 1: Server in a Background Isolate

**What:** Spawn the HTTP server in a Dart `Isolate` separate from the Flutter UI thread. Communicate via `SendPort`/`ReceivePort` message passing.

**When to use:** Always, for any long-lived server embedded in Flutter. The UI thread must stay free for rendering. Even though `shelf_io.serve()` is async and won't block in simple cases, database I/O and connection handling under load can cause jank if co-located with the UI.

**Trade-offs:** Adds message-passing boilerplate; objects cannot be shared across isolate boundaries (only primitive values and `SendPort`s). Worth it because it is the only safe pattern for non-trivial I/O in Flutter.

**Example:**
```dart
// server_message.dart — IPC contracts
sealed class ServerMessage {}
class StartServer extends ServerMessage { final SendPort replyTo; ... }
class ServerStarted extends ServerMessage { final int port; ... }
class ShortenRequest extends ServerMessage { final String url; final SendPort replyTo; ... }
class ShortenResponse extends ServerMessage { final String shortUrl; ... }

// server_controller.dart — UI side
class ServerController {
  Isolate? _isolate;
  SendPort? _serverPort;

  Future<void> start() async {
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_serverIsolateEntry, receivePort.sendPort);
    _serverPort = await receivePort.first as SendPort;
  }

  Future<void> stop() async {
    _serverPort?.send('shutdown');
    _isolate?.kill();
  }
}

// server_isolate.dart — top-level entry point (required by Isolate.spawn)
void _serverIsolateEntry(SendPort mainSendPort) async {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort); // handshake

  final app = Router();
  // ... register routes
  final server = await shelf_io.serve(app.call, 'localhost', 8080);

  receivePort.listen((msg) {
    if (msg == 'shutdown') { server.close(force: true); receivePort.close(); }
  });
}
```

### Pattern 2: Drift with WAL + Background Database Isolate

**What:** Use `NativeDatabase.createInBackground()` so drift hosts the SQLite connection in its own isolate. Enable WAL mode so the server isolate (reader) and the drift isolate (writer) don't block each other.

**When to use:** Always when SQLite is accessed from more than one Dart isolate. The server isolate handles HTTP requests concurrently; without WAL, reads block writes and vice versa, causing latency spikes.

**Trade-offs:** Drift is more setup than `sqflite` for simple cases, but provides compile-time query safety, reactive streams for the UI, and first-class desktop support without extra FFI wiring.

**Example:**
```dart
// db/database.dart
@DriftDatabase(tables: [Urls])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(
    NativeDatabase.createInBackground(
      File(await getDatabasePath()),
      setup: (db) => db.execute('PRAGMA journal_mode=WAL;'),
    ),
  );
}
```

### Pattern 3: 302 Redirect (Not 301)

**What:** The redirect handler responds with HTTP 302 (temporary) rather than 301 (permanent).

**When to use:** For a local tool where URLs can be updated or deleted. A 301 causes browsers to cache the mapping permanently — once cached, the browser never re-requests the short URL, making updates invisible without clearing browser cache.

**Trade-offs:** 302 means the browser always hits the local server for each redirect, which is desirable here since the user may update or delete links and expects changes to take effect immediately.

## Data Flow

### Flow 1: Shortening a URL (UI-initiated)

```
User pastes URL → UrlShortenerWidget
    ↓ calls
ServerController.shorten(originalUrl)
    ↓ sends ShortenRequest via SendPort
Server Isolate (shelf POST /shorten handler)
    ↓
SlugGenerator.generate() → 6-char base62 slug
    ↓
UrlRepository.insertUrl(slug, originalUrl)
    ↓ drift INSERT INTO urls
SQLite file (WAL mode)
    ↓ returns inserted row
Server Isolate → HTTP 200 { "shortUrl": "http://localhost:8080/<slug>" }
    ↓ sends ShortenResponse via ReceivePort
ServerController → updates UI state stream
    ↓
UrlShortenerWidget rebuilds with short URL displayed
```

### Flow 2: Redirect (browser-initiated)

```
Browser → GET http://localhost:8080/<slug>
    ↓ shelf_router matches GET /<slug>
RedirectHandler
    ↓
UrlRepository.findBySlug(slug)
    ↓ drift SELECT * FROM urls WHERE slug = ?
SQLite file
    ↓ returns original_url (or null)
if found  → HTTP 302 Location: <original_url>
if missing → HTTP 404 plain text "Not found"
    ↓
Browser follows redirect to original URL
```

### Flow 3: Server Lifecycle

```
App starts (main.dart)
    ↓
AppDatabase initialized (drift background isolate spawned)
    ↓
ServerController.start() called
    ↓
Isolate.spawn(_serverIsolateEntry, receivePort.sendPort)
    ↓ handshake: server isolate sends back its SendPort
ServerController holds _serverPort (ready for requests)
    ↓
WidgetsBindingObserver.didChangeAppLifecycleState(detached)
    ↓
ServerController.stop() → sends shutdown message
    ↓
Server isolate: server.close() → receivePort.close() → isolate exits
    ↓
AppDatabase.close()
    ↓
Process exits cleanly
```

### State Management (UI)

```
AppDatabase (drift)
    ↓ watchAllUrls() → Stream<List<Url>>   [optional for v1 history feature]
ServerController
    ↓ statusStream → Stream<ServerStatus>  [running / stopped / error]
UrlShortenerWidget
    ↓ StreamBuilder on statusStream
    displays: server status + last generated short URL
```

## Scaling Considerations

This is a single-user local tool. Scaling is not a concern. Notes for completeness:

| Scale | Architecture |
|-------|--------------|
| 1 user, localhost | Current architecture is exactly right — one process, one SQLite file |
| Multi-user (out of scope) | Would require external DB, authentication, deployed server — contradicts project constraints |

### Practical Limits to Know

1. **SQLite WAL mode:** Handles concurrent reads fine. Writes serialize. For a personal URL shortener, this is never a bottleneck.
2. **Port conflicts:** If port 8080 is taken, `shelf_io.serve()` throws. The server controller should handle `SocketException` and surface it to the UI.
3. **Isolate startup time:** `Isolate.spawn` takes ~50-100ms. Start the server isolate in `main()` or during the splash, not on first user action.

## Anti-Patterns

### Anti-Pattern 1: Running the HTTP Server on the UI Isolate

**What people do:** Call `shelf_io.serve()` directly in `main()` or inside a widget without spawning an isolate.

**Why it's wrong:** SQLite I/O and simultaneous HTTP connections will block the event loop, causing UI jank or dropped frames. Flutter's rendering is not immune to long-running async tasks that starve the event loop.

**Do this instead:** Always spawn a dedicated isolate for the server using `Isolate.spawn()`. The small boilerplate cost pays off immediately.

### Anti-Pattern 2: Sharing a Drift Database Instance Across Isolates

**What people do:** Create the `AppDatabase` in the UI isolate, then pass it to the server isolate.

**Why it's wrong:** Dart isolates do not share heap memory. Passing a `AppDatabase` object across an isolate boundary is not possible — only primitives and `SendPort`s can cross. Attempting this causes a runtime error.

**Do this instead:** Create a separate `AppDatabase` instance in each isolate, both pointing to the same SQLite file path. With WAL mode enabled, drift coordinates concurrent access safely at the SQLite level, not at the Dart object level.

### Anti-Pattern 3: Using 301 Redirects

**What people do:** Return `Response.movedPermanently()` (301) from the redirect handler to be "correct."

**Why it's wrong:** Browsers aggressively cache 301 responses. If the user updates or deletes a short URL, the browser continues redirecting to the old destination until cache is cleared manually.

**Do this instead:** Return HTTP 302. Since this is a local tool and analytics are out of scope, 302 provides the same user experience with zero cache-related surprises.

### Anti-Pattern 4: Registering WidgetsBindingObserver Without Removing It

**What people do:** Add the lifecycle observer in `initState()` but forget to call `removeObserver()` in `dispose()`.

**Why it's wrong:** The server controller continues receiving lifecycle events after the widget is destroyed, causing double-shutdown calls or null pointer errors.

**Do this instead:** Always pair `addObserver(this)` in `initState()` with `removeObserver(this)` in `dispose()`.

## Integration Points

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| UI Isolate ↔ Server Isolate | `SendPort`/`ReceivePort` message passing | Only primitive values and sealed message classes cross this boundary |
| Server Isolate ↔ SQLite | drift `AppDatabase` (own instance in server isolate) | WAL mode required; both isolates open the same file path |
| UI Isolate ↔ SQLite | drift `AppDatabase` (own instance in UI isolate) | Needed only if UI shows URL history; out of scope for v1 |
| `ServerController` ↔ `UrlShortenerWidget` | `Stream<ServerStatus>` exposed by controller | Widget listens; controller does not depend on Flutter widgets |

### External Contacts

| Contact | Interface | Notes |
|---------|-----------|-------|
| Browser (user's system) | HTTP on `localhost:8080` | Browser hits the server directly; no Flutter involvement at redirect time |
| SQLite file on disk | drift `NativeDatabase` via FFI | File path resolved via `path_provider` at startup |

## Build Order Implications

The component dependency graph determines what to build first:

```
1. Slug Generator (no deps) ──────────────────────────────► test standalone
2. Database schema (drift tables + DAO) ──────────────────► test with drift test helpers
3. Server handlers (depend on UrlRepository) ─────────────► test with shelf_test
4. Server Isolate wiring (depends on handlers) ───────────► integration test
5. ServerController (depends on isolate entry point) ─────► test start/stop
6. Flutter UI (depends on ServerController) ──────────────► widget tests + manual
```

**Phase recommendation:**
- Phase 1: DB schema + slug generator (pure logic, zero Flutter dependency)
- Phase 2: HTTP server in isolation (shelf routes + redirect logic, testable without Flutter)
- Phase 3: Isolate wiring + lifecycle integration (ServerController + app startup)
- Phase 4: Flutter UI (widget layer consumes ServerController stream)

This ordering means each phase produces a working, testable artifact before the next phase begins.

## Sources

- [shelf 1.4.2 — pub.dev](https://pub.dev/packages/shelf)
- [shelf_router 1.1.4 — pub.dev](https://pub.dev/packages/shelf_router)
- [Dart Isolates — dart.dev](https://dart.dev/language/isolates)
- [Concurrency and isolates — Flutter docs](https://docs.flutter.dev/perf/isolates)
- [Drift NativeDatabase VM/Desktop — drift.simonbinder.eu](https://drift.simonbinder.eu/platforms/vm/)
- [AppLifecycleState — Flutter API](https://api.flutter.dev/flutter/dart-ui/AppLifecycleState.html)
- [WidgetsBindingObserver — Flutter API](https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver-class.html)

---
*Architecture research for: Local URL shortener — Flutter desktop with embedded HTTP server*
*Researched: 2026-03-26*
