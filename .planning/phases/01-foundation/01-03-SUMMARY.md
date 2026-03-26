---
phase: 01-foundation
plan: 03
subsystem: server
tags: [dart, shelf, shelf_router, http, server, loopback, port-scan]

requires:
  - 01-01 (pubspec.yaml with shelf ^1.4.2 and shelf_router ^1.1.4)
provides:
  - lib/server/server_controller.dart with ServerController and ServerStatus
  - Embedded HTTP server that binds to 127.0.0.1, tries ports 8080-8082, and exposes lifecycle via stream
affects:
  - 01-04 (will wire ServerController into main.dart / app lifecycle)
  - Phase 2 (URL shortener routes added to ServerController._buildHandler)

tech-stack:
  added:
    - shelf 1.4.2 (used: shelf_io.serve, Pipeline, logRequests, Handler, Request, Response)
    - shelf_router 1.1.4 (used: Router for /health and fallback routes)
  patterns:
    - "ServerController wraps shelf_io.serve() — no Isolate.spawn needed for localhost traffic"
    - "Port-scan fallback via loop over _candidatePorts, catching SocketException per attempt"
    - "statusStream via StreamController.broadcast() — UI observes without polling"
    - "stop() uses server.close(force: true) to release port immediately (hot-restart safe)"

key-files:
  created:
    - lib/server/server_controller.dart
  modified: []

key-decisions:
  - "Doc comment used [slug] instead of <slug> to avoid unintended_html_in_doc_comment lint (auto-fixed)"
  - "No Isolate.spawn — shelf_io is non-blocking async; isolate adds complexity with no benefit for localhost"
  - "Idempotent start()/stop() — guards against double-start/double-stop without throwing"

requirements-completed:
  - FOUND-02
  - FOUND-03
  - FOUND-04

duration: 2min
completed: 2026-03-26
---

# Phase 01 Plan 03: ServerController Implementation Summary

**shelf-based ServerController with loopback-only binding, port-scan fallback [8080, 8081, 8082], SocketException handling, force-close shutdown, and ServerStatus stream**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-26T22:32:34Z
- **Completed:** 2026-03-26T22:34:30Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- `lib/server/server_controller.dart` created with `ServerController` class and `ServerStatus` enum
- Binds exclusively to `InternetAddress.loopbackIPv4` (127.0.0.1) — never 0.0.0.0, closing off the network exposure pitfall
- Port-scan fallback: `_candidatePorts = [8080, 8081, 8082]` — each attempted via `_tryBind()` which catches `SocketException` and returns null, allowing the loop to advance
- Clean shutdown: `stop()` calls `server.close(force: true)` ensuring immediate port release and eliminating "Address already in use" on hot restart
- `statusStream` exposes `Stream<ServerStatus>` via `StreamController.broadcast()` for reactive UI observation
- `port` getter returns the actual bound port after `start()` (not hardcoded 8080)
- Foundation handler: `GET /health` returns `200 OK`; all other routes return `404 Not Found`
- `flutter analyze lib/server/` reports "No issues found"

## ServerController Public API

| Member | Type | Description |
|--------|------|-------------|
| `start()` | `Future<void>` | Attempts ports 8080 → 8082; throws StateError if all fail |
| `stop()` | `Future<void>` | Closes server with `force: true`; idempotent |
| `dispose()` | `Future<void>` | Calls stop() then closes the status StreamController |
| `statusStream` | `Stream<ServerStatus>` | Broadcasts stopped / starting / running / error |
| `port` | `int?` | Actual bound port; null when not running |
| `isRunning` | `bool` | Convenience getter: `_server != null` |

## Key Technical Confirmations

| Concern | Implementation | Pitfall addressed |
|---------|----------------|-------------------|
| Network exposure | `InternetAddress.loopbackIPv4` (127.0.0.1) | Security — never 0.0.0.0 |
| Port conflicts | `SocketException` catch in `_tryBind()` | Pitfall 1: bind failure handling |
| Hot-restart port leak | `server.close(force: true)` | Pitfall 2: port not released |
| UI jank | Direct `shelf_io.serve()` (async I/O, no Isolate) | No over-engineering |

## Task Commits

1. **Task 1: Implement ServerController** - `dc10ed8` (feat)

## Files Created/Modified

- `lib/server/server_controller.dart` — ServerController class + ServerStatus enum (118 lines)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Doc comment `<slug>` triggered unintended_html_in_doc_comment lint**
- **Found during:** Task 1 (flutter analyze run post-write)
- **Issue:** The plan's source code comment `GET /<slug>` triggered `unintended_html_in_doc_comment` lint warning, causing `flutter analyze` to report 1 issue instead of "No issues found"
- **Fix:** Changed `GET /<slug>` to `GET /[slug]` in the doc comment — semantically identical, lint-compliant
- **Files modified:** lib/server/server_controller.dart (line 101)
- **Commit:** dc10ed8 (fix applied before commit, included in task commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — doc comment lint)
**Impact:** Zero — comment-only change, no behavior difference.

## Issues Encountered

None beyond the doc comment lint deviation documented above.

## User Setup Required

None.

## Next Phase Readiness

- `ServerController` is ready to be instantiated from `main.dart` or a top-level `AppController` in Plan 04
- Phase 2 will add `POST /shorten` and `GET /<slug>` routes to `_buildHandler()`
- No migration or schema changes needed — this plan is pure server infrastructure

## Self-Check: PASSED

- FOUND: lib/server/server_controller.dart
- FOUND commit: dc10ed8 (feat(01-03): implement ServerController)
- FOUND: 01-03-SUMMARY.md

---
*Phase: 01-foundation*
*Completed: 2026-03-26*
