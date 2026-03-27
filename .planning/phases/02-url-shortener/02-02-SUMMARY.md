---
phase: 02-url-shortener
plan: "02"
subsystem: api
tags: [shelf, shelf_router, dart, http, url-shortening, redirect, drift]

# Dependency graph
requires:
  - phase: 02-01
    provides: SlugGenerator.generate(int id) — base62 row ID encoding
  - phase: 01-foundation
    provides: AppDatabase, UrlDao (insertUrl, findBySlug), ServerController skeleton
provides:
  - POST /shorten handler with URL validation, normalization, and base62 slug generation
  - GET /<slug> handler with HTTP 302 redirect and Cache-Control: no-store
  - UrlDao.updateSlug method for insert-placeholder-then-update pattern
  - ServerController updated to accept AppDatabase and register both routes
affects:
  - 02-03 (ShortenerScreen: POST /shorten is now functional)
  - 02-04 (wiring/integration tests)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - insert-placeholder-slug then updateSlug to avoid SELECT-before-INSERT and guarantee uniqueness
    - shelf_router context key shelf_router/params used to pass route params to standalone handlers
    - URL normalization pattern: auto-prefix https:// for schemeless URLs, reject non-http(s) schemes

key-files:
  created:
    - lib/server/handlers/shorten_handler.dart
    - lib/server/handlers/redirect_handler.dart
  modified:
    - lib/db/url_dao.dart
    - lib/server/server_controller.dart
    - lib/main.dart

key-decisions:
  - "shelf_router/params context key used to inject route slug into standalone redirect handler (request.change has no params param)"
  - "insert-placeholder slug then updateSlug pattern ensures uniqueness without SELECT-before-INSERT"
  - "302 not 301 for redirects to prevent browser caching of slug mappings (Pitfall 5)"
  - "ServerController accepts AppDatabase in constructor — database dependency injected at creation"

patterns-established:
  - "Standalone handler factory pattern: makeShortenHandler(urlDao, port) returns Handler — testable, injectable"
  - "URL normalization: trim, auto-prefix https://, validate scheme before DB insert"
  - "shelf_router context injection: request.change(context: {'shelf_router/params': {'key': val}}) for custom param passing"

requirements-completed: [SHORT-01, SHORT-02, SHORT-03, SHORT-04, REDIR-01, REDIR-02, REDIR-03]

# Metrics
duration: 6min
completed: 2026-03-27
---

# Phase 2 Plan 02: HTTP Route Handlers Summary

**POST /shorten and GET /<slug> shelf handlers wired into ServerController with drift updateSlug and 302 redirect pattern**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-27T11:46:42Z
- **Completed:** 2026-03-27T11:53:16Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- POST /shorten handler: validates and normalizes URL, inserts with temp slug, generates base62 slug via SlugGenerator, updates row, returns JSON `{"shortUrl": "http://localhost:PORT/SLUG"}`
- GET /<slug> handler: looks up slug in DB, returns HTTP 302 with Cache-Control: no-store or 404 if unknown
- UrlDao.updateSlug added: allows insert-placeholder-then-update pattern to guarantee collision-free slugs
- ServerController now accepts AppDatabase and registers both /shorten and /<slug> routes
- main.dart updated to pass database to ServerController constructor

## Task Commits

Each task was committed atomically:

1. **Task 1: Create shorten_handler and redirect_handler** - `1af6204` (feat — previously committed in 02-03 session)
2. **Task 2: Add UrlDao.updateSlug, wire routes into ServerController** - `41a25c7` (feat)

**Plan metadata:** (docs commit follows)

_Note: Task 1 handler files were already committed in the 02-03 execution session. This plan completed Task 2 work (updateSlug + ServerController wiring + main.dart fix) that was missing._

## Files Created/Modified

- `lib/server/handlers/shorten_handler.dart` - POST /shorten handler factory with URL validation and slug generation
- `lib/server/handlers/redirect_handler.dart` - GET /<slug> handler with 302 redirect and Cache-Control: no-store
- `lib/db/url_dao.dart` - Added updateSlug method (update by row ID using drift UrlsCompanion)
- `lib/server/server_controller.dart` - Updated: accepts AppDatabase, registers /shorten and /<slug> routes
- `lib/main.dart` - Passes database to ServerController constructor

## Decisions Made

- **shelf_router/params context injection:** `request.change(params: ...)` is not a valid shelf API. Route params must be passed via `request.change(context: {'shelf_router/params': {'slug': slug}})` to make them available to `request.params['slug']` in standalone handlers.
- **insert-placeholder pattern:** Insert with `_t{timestamp}` temp slug to get the auto-increment row ID, then call updateSlug to set the real base62-encoded slug. Avoids SELECT-before-INSERT and guarantees uniqueness without retry loops.
- **302 not 301:** Permanent (301) redirects are browser-cached — if a mapping is updated/deleted, browsers would still use the cached destination. 302 forces a fresh request each time.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Missing shelf_router import in redirect_handler.dart**
- **Found during:** Task 1 (handler creation)
- **Issue:** `request.params` is an extension method (`RouterParams`) defined in `shelf_router`. Without the import, the `params` getter is not available on `Request`.
- **Fix:** Added `import 'package:shelf_router/shelf_router.dart';` to redirect_handler.dart
- **Files modified:** lib/server/handlers/redirect_handler.dart
- **Verification:** `flutter analyze lib/server/handlers/redirect_handler.dart` reports "No issues found"
- **Committed in:** 1af6204 (Task 1 commit)

**2. [Rule 1 - Bug] `request.change(params: ...)` is not a valid shelf API**
- **Found during:** Task 2 (ServerController route wiring)
- **Issue:** The plan's code used `request.change(params: {'slug': slug})` but shelf's `Request.change()` has no `params` parameter — only `headers`, `context`, `path`, `body`.
- **Fix:** Replaced with `request.change(context: {'shelf_router/params': <String, String>{'slug': slug}})` which is the actual internal key that `RouterParams.params` reads from.
- **Files modified:** lib/server/server_controller.dart
- **Verification:** `flutter analyze lib/` reports "No issues found"
- **Committed in:** 41a25c7 (Task 2 commit)

**3. [Rule 1 - Bug] main.dart was not passing database to ServerController**
- **Found during:** Task 2 (flutter analyze after ServerController update)
- **Issue:** `main.dart` called `ServerController()` without the now-required `database` named parameter, causing `missing_required_argument` analyzer error.
- **Fix:** Updated `ServerController()` call to `ServerController(database: database)` — the `database` variable was already instantiated just above.
- **Files modified:** lib/main.dart
- **Verification:** `flutter analyze lib/` reports "No issues found"
- **Committed in:** 41a25c7 (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (3 Rule 1 bugs)
**Impact on plan:** All auto-fixes necessary for correctness. The shelf API mismatch was a plan error; the other two were missing wiring. No scope creep.

## Issues Encountered

- 02-03 had executed before 02-02 and committed the handler files (Task 1 artifacts), but did not complete Task 2 (updateSlug, ServerController wiring). This plan picked up from Task 2 with handler files already in git.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- POST /shorten and GET /<slug> routes are fully functional and analyze clean
- ShortenerScreen (02-03) already exists and POSTs to /shorten — it will now work end-to-end
- 02-04 (main.dart wiring and integration verification) is the final plan in phase 02

## Self-Check: PASSED

All required files present and commits verified.

---
*Phase: 02-url-shortener*
*Completed: 2026-03-27*
