---
phase: 01-foundation
plan: 04
subsystem: ui
tags: [flutter, shelf, dart, applifecyclelistener, streambuilder, desktop]

# Dependency graph
requires:
  - phase: 01-03
    provides: ServerController with port-scan fallback (8080→8082) and statusStream
  - phase: 01-02
    provides: AppDatabase with drift/SQLite at stable application support path
provides:
  - Running Flutter desktop app wired with embedded HTTP server and SQLite
  - AppLifecycleListener-based clean shutdown (server stop + db close on window close)
  - FoundationScreen showing live server status dot and actual bound port URL
  - ServerController started before runApp so port is bound before first frame
affects:
  - 02-url-shortener

# Tech tracking
tech-stack:
  added: []
  patterns:
    - AppLifecycleListener for desktop window-close lifecycle (NOT widget dispose)
    - ServerController started before runApp; passed down via constructor
    - StreamBuilder<ServerStatus> for reactive UI driven by server status stream
    - initialData on StreamBuilder using isRunning getter to avoid flicker on first frame

key-files:
  created:
    - lib/ui/foundation_screen.dart
  modified:
    - lib/main.dart
    - lib/app.dart

key-decisions:
  - "AppLifecycleListener used for server/db shutdown — widget dispose() is unreliable on Flutter desktop (flutter/flutter#113220)"
  - "serverController.start() called before runApp so port is bound and UI shows correct port on first frame"
  - "StreamBuilder initialData derives from serverController.isRunning to prevent stopped-state flicker"
  - "FoundationScreen displays serverController.port (actual bound port) not hardcoded 8080 — validates port fallback behaviour"

patterns-established:
  - "Infrastructure-first launch: start server/db before runApp, pass via constructor"
  - "Desktop lifecycle: AppLifecycleListener onExitRequested for clean resource shutdown"
  - "Reactive status UI: StreamBuilder + status enum + color-coded indicator dot"

requirements-completed: [FOUND-01, FOUND-02, FOUND-03, FOUND-04, FOUND-05]

# Metrics
duration: ~35min
completed: 2026-03-26
---

# Phase 1 Plan 04: Foundation Wiring Summary

**Flutter desktop app wired end-to-end: shelf server starts before runApp, AppLifecycleListener shuts down server and DB on window close, FoundationScreen shows live green-dot status and actual bound port**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-03-26 (session)
- **Completed:** 2026-03-26
- **Tasks:** 2 implementation tasks + 1 human-verify checkpoint
- **Files modified:** 3

## Accomplishments

- main.dart starts ServerController and AppDatabase before runApp, passing both into the App widget
- app.dart registers AppLifecycleListener.onExitRequested to call serverController.stop() and database.close() on window close — port is reliably freed on shutdown
- lib/ui/foundation_screen.dart renders a StreamBuilder-driven status card: green dot + "Server Running" + actual `http://localhost:PORT` URL using serverController.port (never hardcoded)
- Human verification confirmed: window opens, curl /health returns OK, lsof shows port freed after close, DB file lazy-initialised as expected (no DB ops in Phase 1 so urls.db appears on first DB write)

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire ServerController into main.dart and app.dart with lifecycle shutdown** - `5773f72` (feat)
2. **Task 2: Build FoundationScreen showing server status and actual bound port** - `da77c5f` (feat)
3. **Checkpoint: Verify Phase 1 Foundation end-to-end** - Human approval received ("approved")

## Files Created/Modified

- `lib/main.dart` - Initializes AppDatabase and ServerController, starts server before runApp
- `lib/app.dart` - StatefulWidget with AppLifecycleListener for clean shutdown on window close
- `lib/ui/foundation_screen.dart` - Status card with StreamBuilder<ServerStatus>, colored dot, and actual bound port URL

## Decisions Made

- AppLifecycleListener chosen over widget dispose() for shutdown — Flutter desktop does not reliably call dispose() on window close (known issue flutter/flutter#113220)
- serverController.start() placed before runApp() so port is determined before the first UI frame; prevents UI briefly showing "stopped"
- StreamBuilder initialData set from serverController.isRunning to cover the window between app start and first stream event
- FoundationScreen uses serverController.port in the URL string — not a string literal — so port fallback (8081/8082) displays correctly

## Deviations from Plan

None — plan executed exactly as written. Both tasks matched their acceptance criteria. flutter analyze reported zero issues. Human verification passed all checks.

## Issues Encountered

None. The human verifier noted the DB file was not yet visible (urls.db not created), which was expected behaviour: AppDatabase uses lazy NativeDatabase.createInBackground and the file is only written on the first SQL operation. No DB operations occur in Phase 1, so the file is created when Phase 2 URL insertion runs.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 1 complete. All five foundation requirements verified (FOUND-01 through FOUND-05).
- Phase 2 can build on: AppDatabase (UrlDao), ServerController (shelf_router ready for routes), FoundationScreen (replace with full URL shortener UI).
- No blockers. Port fallback, clean shutdown, and stable DB path all confirmed working.

---
*Phase: 01-foundation*
*Completed: 2026-03-26*
