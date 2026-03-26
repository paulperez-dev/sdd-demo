<!-- GSD:project-start source:PROJECT.md -->
## Project

**SDD — URL Shortener Local**

Un acortador de URLs que corre completamente en local como una aplicación Flutter de escritorio. Embebe un servidor HTTP en Dart que recibe URLs largas, genera versiones cortas, y redirige cuando se visita la URL corta. Almacena todo en SQLite local.

**Core Value:** Acortar una URL y que la URL corta redirija correctamente a la original — todo sin depender de servicios externos.

### Constraints

- **Stack**: Dart + Flutter — decisión del usuario, no negociable
- **Runtime**: Ejecución 100% local, sin dependencias de red para funcionar
- **Persistencia**: SQLite — archivo local, sin servidor de base de datos
- **Arquitectura**: Servidor embebido en el proceso Flutter, no procesos separados
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Recommended Stack
### Core Technologies
| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Flutter | 3.41.x (stable) | Desktop UI framework | Non-negotiable per project constraints; stable desktop support on macOS, Windows, Linux since Flutter 3.x; ships with Dart SDK |
| Dart SDK | 3.11.x (bundled with Flutter) | Language runtime + HTTP server | Bundled with Flutter; `dart:io` and `shelf` run on same Dart VM as the Flutter UI — enables single-process embedded server |
| shelf | 1.4.2 | Embedded HTTP server middleware | Official Dart team package; the only mature, actively maintained HTTP server abstraction for Dart; function-based handlers, composable middleware pipeline |
| shelf_router | 1.1.4 | URL routing for the HTTP server | Official Dart team companion to shelf; handles `GET /r/:slug` redirect routes and `POST /shorten` API route cleanly with path parameter extraction |
| drift | 2.32.1 | Type-safe SQLite ORM | Works on all desktop platforms (Windows, macOS, Linux) without extra setup since 2.32.0; compile-time query validation; reactive streams for UI state; the most complete SQLite solution in the Dart ecosystem |
| drift_flutter | 0.3.0 | Flutter-specific drift setup | Bridges drift (pure Dart) to Flutter; handles platform database path resolution via `path_provider` automatically; avoids manual platform boilerplate |
### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| window_manager | 0.5.1 | Set initial window size, center on screen, prevent resize | Use at app startup to constrain the window to a sensible fixed size (e.g., 480x640) — critical for desktop apps that should not feel like a web page |
| url_launcher | 6.3.2 | Open URLs in the system default browser | Use when user clicks the generated short URL to verify it works in their actual browser |
| path_provider | latest | Resolve platform database file path | drift_flutter depends on this; also useful if you need to know where the SQLite file lives |
### Development Tools
| Tool | Purpose | Notes |
|------|---------|-------|
| drift_dev | 2.32.1 | Code generator for drift table/query classes | Run via `dart run build_runner build`; must match drift version exactly |
| build_runner | ^2.4.0 | Dart code generation runner | Required by drift_dev; run once after changing schema |
| flutter_lints | ^5.0.0 | Lint rules | Ships with Flutter; enforce style from day one |
## Installation
# pubspec.yaml dependencies
# After adding to pubspec.yaml
# Generate drift code after defining tables
## Alternatives Considered
| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| shelf | dart:io HttpServer (raw) | Never for this project — shelf wraps dart:io and adds middleware composition with no performance penalty; raw HttpServer requires manual request parsing |
| shelf | Dart Frog | Dart Frog is a CLI-first framework designed for standalone server apps, not embedded servers inside Flutter; adds unnecessary process boundary and complexity |
| drift | sqflite + sqflite_common_ffi | Use sqflite if you need raw SQL control and don't want a build step; sqflite_common_ffi bridges desktop but requires separate `databaseFactoryFfi` init; drift is strictly better for new projects due to type safety |
| drift | isar | Isar is a NoSQL document database — good for key/value but doesn't model the URL mapping table (slug → original_url) as naturally as a SQL row; overkill here |
| window_manager | bitsdojo_window | bitsdojo_window last published December 2023, no 2024/2025 updates; window_manager (leanflutter.dev) actively maintained through 2025; same feature set |
## What NOT to Use
| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `dart:io` HttpServer directly | No middleware, no routing, no pipeline — every feature must be hand-rolled; shelf wraps it with zero overhead | `shelf` + `shelf_router` |
| Dart Frog | Designed for standalone servers with its own CLI and project structure; embedding it inside a Flutter process is unsupported and undocumented | `shelf` (runs in-process, no CLI needed) |
| `sqflite` without `sqflite_common_ffi` | Core sqflite targets mobile only; silently fails on Linux/Windows if the FFI bridge is not initialized | `drift` + `drift_flutter` (handles this automatically) |
| Serverpod | Full-stack server framework requiring a separate database server process (PostgreSQL); antithetical to the "100% local, no external dependencies" constraint | `shelf` + `drift` |
| `bitsdojo_window` | No updates since December 2023; forks exist but are unmaintained community patches | `window_manager` (actively maintained by leanflutter.dev, published 2025) |
| `Isolate.spawn` for the HTTP server | Not necessary — `shelf_io.serve()` is non-blocking by default (uses async I/O); spawning an isolate adds message-passing complexity with no benefit for low-traffic localhost | Direct `shelf_io.serve()` call in `main()` before `runApp()` |
## Stack Patterns by Variant
- Call `shelf_io.serve(handler, 'localhost', 8080)` before `runApp()` in `main()`
- The shelf server shares the Dart event loop with Flutter; this is fine for localhost-only traffic
- Store the `HttpServer` reference returned by `serve()` and call `.close()` when the app disposes
- Use `Isolate.spawn` with `ReceivePort`/`SendPort` for communication
- Only necessary if benchmarking shows jank; start without this and add only if needed
- Flutter cannot pass `BuildContext` or platform channels across isolate boundaries
- Use `dart:math` `Random.nextInt` on base62 character set — no package needed
- 6-character base62 slug gives 56+ billion combinations: sufficient for personal use
## Version Compatibility
| Package | Compatible With | Notes |
|---------|-----------------|-------|
| drift ^2.32.1 | drift_dev ^2.32.1 | drift and drift_dev versions must match exactly — mismatches cause code gen failures |
| drift ^2.32.1 | drift_flutter ^0.3.0 | drift_flutter 0.3.0 targets drift 2.x; confirmed compatible |
| shelf ^1.4.2 | shelf_router ^1.1.4 | Both maintained by dart-lang team; no known conflicts |
| window_manager ^0.5.1 | Flutter 3.x | Requires Flutter 3.0+; works on macOS, Windows, Linux |
| drift_flutter ^0.3.0 | path_provider ^2.1.0 | drift_flutter pulls path_provider transitively; no need to pin separately |
## Sources
- [pub.dev/packages/shelf](https://pub.dev/packages/shelf) — version 1.4.2 confirmed
- [pub.dev/packages/shelf_router](https://pub.dev/packages/shelf_router) — version 1.1.4 confirmed
- [pub.dev/packages/drift](https://pub.dev/packages/drift) — version 2.32.1 confirmed (published 4 days prior to research date)
- [pub.dev/packages/drift_flutter](https://pub.dev/packages/drift_flutter) — version 0.3.0 confirmed
- [pub.dev/packages/sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) — version 2.4.0+2, desktop support confirmed; used to validate why drift is preferred
- [pub.dev/packages/window_manager](https://pub.dev/packages/window_manager) — version 0.5.1 confirmed, active maintenance by leanflutter.dev
- [pub.dev/packages/url_launcher](https://pub.dev/packages/url_launcher) — version 6.3.2, desktop support confirmed
- [drift.simonbinder.eu/platforms/vm/](https://drift.simonbinder.eu/platforms/vm/) — Desktop platform support details (MEDIUM confidence via WebSearch verification)
- [blog.flutter.dev/whats-new-in-flutter-3-41](https://blog.flutter.dev/whats-new-in-flutter-3-41-302ec140e632) — Flutter 3.41 current stable confirmed
- [WebSearch: dart flutter embedded HTTP server isolate] — Shelf + async I/O pattern confirmed, no isolate needed for low-traffic localhost (MEDIUM confidence, multiple sources agree)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
