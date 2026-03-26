---
phase: 01-foundation
plan: 02
subsystem: database
tags: [drift, sqlite, dart, wal, path_provider, code-generation]

requires:
  - phase: 01-01
    provides: pubspec.yaml with drift 2.31.0, drift_dev 2.31.0, path_provider 2.1.5, build_runner declared

provides:
  - lib/db/database.dart — AppDatabase with Urls table, WAL mode, getApplicationSupportDirectory path
  - lib/db/url_dao.dart — UrlDao with insertUrl and findBySlug methods
  - lib/db/database.g.dart — drift-generated database code (_$AppDatabase)
  - lib/db/url_dao.g.dart — drift-generated DAO mixin (_$UrlDaoMixin)

affects:
  - 01-03
  - 01-04
  - all plans that insert or query URLs

tech-stack:
  added:
    - path 1.9.1 (explicit direct dependency for p.join path construction)
    - drift/native.dart (NativeDatabase.createInBackground — correct import for drift 2.31.0)
  patterns:
    - "Database schema: drift Table class with IntColumn id (autoIncrement), TextColumn slug (unique), TextColumn originalUrl, DateTimeColumn createdAt"
    - "Database path: getDatabaseFile() via getApplicationSupportDirectory() + p.join — stable across debug/release"
    - "Connection: LazyDatabase wrapping NativeDatabase.createInBackground with PRAGMA journal_mode=WAL"
    - "DAO pattern: @DriftAccessor class extending DatabaseAccessor, part .g.dart mixin"

key-files:
  created:
    - lib/db/database.dart
    - lib/db/url_dao.dart
    - lib/db/database.g.dart
    - lib/db/url_dao.g.dart
  modified:
    - pubspec.yaml (added path ^1.9.0 as direct dependency)
    - pubspec.lock (resolved path to 1.9.1 direct dependency)

key-decisions:
  - "Replaced package:drift_flutter/drift_flutter.dart import with package:drift/native.dart — drift_flutter 0.2.8 exports driftDatabase() helper only, not NativeDatabase; NativeDatabase is in drift's own native.dart"
  - "Added path as explicit direct dependency (was transitive) — depend_on_referenced_packages lint requires explicit declaration when imported directly"
  - "schema version set to 1 — first and only schema, no migrations needed for v1"

patterns-established:
  - "WAL journal mode enabled at connection time via setup callback — allows concurrent reads during server + UI access"
  - "Database file at getApplicationSupportDirectory()/urls.db — survives app restarts, stable across build modes"

requirements-completed:
  - FOUND-05

duration: 8min
completed: 2026-03-26
---

# Phase 01 Plan 02: Drift Database Schema and DAO Summary

**SQLite database schema and DAO with WAL mode at a stable path (getApplicationSupportDirectory) and drift-generated type-safe query layer for URL slug storage**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-26T22:32:31Z
- **Completed:** 2026-03-26T22:40:51Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- AppDatabase schema defined: `urls` table with `id` (autoIncrement), `slug` (UNIQUE, 5-10 chars), `original_url`, `created_at` (defaulting to currentDateAndTime)
- Database file path resolves to `getApplicationSupportDirectory()/urls.db` — stable across debug/release builds, not CWD
- WAL journal mode enabled via `PRAGMA journal_mode=WAL` in connection setup — allows concurrent reads from server and UI
- UrlDao provides type-safe `insertUrl(slug, originalUrl)` and `findBySlug(slug) -> Url?` methods
- `dart run build_runner build` generates `database.g.dart` and `url_dao.g.dart` without errors
- `flutter analyze lib/` reports "No issues found"

## Task Commits

Each task was committed atomically:

1. **Task 1: Create AppDatabase with Urls table (drift schema)** - `e2989c8` (feat)
2. **Task 2: Create UrlDao and run drift code generation** - `a01041d` (feat)

**Plan metadata:** _(pending final docs commit)_

## Files Created/Modified

- `lib/db/database.dart` — AppDatabase class with Urls table, getDatabaseFile(), NativeDatabase.createInBackground with WAL
- `lib/db/url_dao.dart` — UrlDao with @DriftAccessor, insertUrl and findBySlug methods
- `lib/db/database.g.dart` — drift-generated: _$AppDatabase mixin, Url data class, UrlsCompanion
- `lib/db/url_dao.g.dart` — drift-generated: _$UrlDaoMixin
- `pubspec.yaml` — added path ^1.9.0 as explicit direct dependency
- `pubspec.lock` — path resolved to 1.9.1 (promoted from transitive to direct)

## Decisions Made

- **drift/native.dart import:** `NativeDatabase` is in `package:drift/native.dart`, not re-exported by `drift_flutter` 0.2.8. The plan specified `import 'package:drift_flutter/drift_flutter.dart'` to get `NativeDatabase`, but that only works in drift_flutter 0.3.0+. Using drift 2.31.0 / drift_flutter 0.2.8, the correct import is `package:drift/native.dart`.
- **Explicit path dependency:** The plan noted `path` is a transitive dep of drift_flutter. With drift_flutter 0.2.8 it still resolves transitively, but the `depend_on_referenced_packages` lint requires direct imports to be in direct dependencies. Added `path: ^1.9.0` to pubspec.yaml.
- **Schema version 1:** No migrations needed for v1. Single schema, no history to track.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] NativeDatabase not exported by drift_flutter 0.2.8**
- **Found during:** Task 2 (flutter analyze after code generation)
- **Issue:** Plan specified `import 'package:drift_flutter/drift_flutter.dart'` as the source of `NativeDatabase`. drift_flutter 0.3.0 re-exports it, but drift_flutter 0.2.8 only exports `driftDatabase()`. Flutter analyze reported: `error • Undefined name 'NativeDatabase'`
- **Fix:** Changed import from `package:drift_flutter/drift_flutter.dart` to `package:drift/native.dart` in database.dart
- **Files modified:** lib/db/database.dart
- **Verification:** `flutter analyze lib/` reports "No issues found"
- **Committed in:** a01041d (Task 2 commit)

**2. [Rule 2 - Missing Critical] Added path as explicit dependency**
- **Found during:** Task 2 (flutter analyze after code generation)
- **Issue:** `package:path/path.dart` is imported in database.dart but was only a transitive dependency. Lint reported: `info • The imported package 'path' isn't a dependency of the importing package`
- **Fix:** Added `path: ^1.9.0` to pubspec.yaml dependencies; ran `flutter pub get`
- **Files modified:** pubspec.yaml, pubspec.lock
- **Verification:** `flutter analyze lib/` reports "No issues found"
- **Committed in:** a01041d (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 Rule 1 — wrong import for drift version, 1 Rule 2 — missing explicit dependency)
**Impact on plan:** Both fixes are consequences of the drift 2.31.0 / drift_flutter 0.2.8 downgrade from Plan 01. No scope creep. All plan goals achieved.

## Issues Encountered

Both issues stem from the version downgrade documented in Plan 01. drift_flutter 0.2.8 has a different API surface than 0.3.0: it does not re-export `NativeDatabase`. The fix (import from `drift/native.dart` directly) is the canonical approach for drift on native platforms regardless of version.

## Build / Analyze Results

- `dart run build_runner build --delete-conflicting-outputs`: exits 0, "Built with build_runner/jit in 69s; wrote 16 outputs"
- `flutter analyze lib/`: "No issues found! (ran in 31.0s)"
- Schema version: 1
- Database file path: `getApplicationSupportDirectory()/urls.db` (print path via getDatabaseFile() in debug mode)
- Column definitions confirmed: id (INTEGER, autoIncrement), slug (TEXT, UNIQUE, length 5-10), original_url (TEXT), created_at (DATETIME, default currentDateAndTime)

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `AppDatabase` + `UrlDao` are the only database layer needed for v1; Phase 2 plans can import and use directly
- `insertUrl(slug: ..., originalUrl: ...)` is ready for the URL shortening handler
- `findBySlug(slug)` is ready for the redirect handler
- Note: If upgrading Flutter to 3.41.x, drift/drift_dev can be bumped to 2.32.1 and drift_flutter to 0.3.0; the `drift_flutter` import in database.dart can revert to the plan-specified form

## Self-Check: PASSED

- FOUND: lib/db/database.dart
- FOUND: lib/db/url_dao.dart
- FOUND: lib/db/database.g.dart
- FOUND: lib/db/url_dao.g.dart
- FOUND commit: e2989c8 (feat(01-02): create AppDatabase with Urls table and WAL mode)
- FOUND commit: a01041d (feat(01-02): create UrlDao and generate drift code via build_runner)

---
*Phase: 01-foundation*
*Completed: 2026-03-26*
