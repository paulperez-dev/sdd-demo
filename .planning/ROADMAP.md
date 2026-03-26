# Roadmap: SDD — URL Shortener Local

## Overview

Two phases deliver the complete v1 product. Phase 1 builds the invisible infrastructure — the embedded HTTP server, SQLite database, and app lifecycle wiring — that everything else depends on. Phase 2 builds the full URL shortening loop on top: user pastes a URL, gets a short link, opens it in a browser, and the server redirects correctly. When Phase 2 is done, the product is done.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- **Phase 1: Foundation** - Embedded HTTP server starts with the app, binds to a stable port with fallback, shuts down cleanly, and persists data to SQLite at the correct path
- **Phase 2: URL Shortener** - User can shorten a URL, see the short link in the UI, and have the browser redirect to the original via the embedded server

## Phase Details

### Phase 1: Foundation

**Goal**: The app launches with a working embedded HTTP server and a reliable local database — the infrastructure is solid before any URL features are built
**Depends on**: Nothing (first phase)
**Requirements**: FOUND-01, FOUND-02, FOUND-03, FOUND-04, FOUND-05
**Success Criteria** (what must be TRUE):

1. The Flutter desktop app opens a window on launch
2. The embedded HTTP server starts automatically on a port between 8080-8082 and the app displays the actual bound port
3. The server stops cleanly when the window is closed — no port leak on re-launch
4. If the default port is occupied, the server binds to an alternative port without crashing
5. The SQLite database file is created in the application support directory and survives between debug and release runs
**Plans**: TBD
**UI hint**: yes

### Phase 2: URL Shortener

**Goal**: Users can shorten URLs and have the embedded server redirect them — the complete core value loop works end to end
**Depends on**: Phase 1
**Requirements**: SHORT-01, SHORT-02, SHORT-03, SHORT-04, SHORT-05, REDIR-01, REDIR-02, REDIR-03
**Success Criteria** (what must be TRUE):

1. User pastes a long URL into a text field and submits it; the app displays the generated short URL (e.g. `http://localhost:8080/abc123`)
2. Opening the short URL in a browser redirects to the original URL using HTTP 302
3. Short URLs created in one session are still functional after restarting the app
4. Visiting a short URL that does not exist returns a 404 response in the browser
**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2


| Phase            | Plans Complete | Status      | Completed |
| ---------------- | -------------- | ----------- | --------- |
| 1. Foundation    | 0/?            | Not started | -         |
| 2. URL Shortener | 0/?            | Not started | -         |


