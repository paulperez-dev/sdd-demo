# Feature Research

**Domain:** Local/personal URL shortener — desktop app with embedded HTTP server
**Researched:** 2026-03-26
**Confidence:** HIGH (core redirect loop is well-understood; feature categorization adapted from self-hosted tools YOURLS and Shlink)

## Context: Local Tool vs SaaS

This is a **single-user, offline-first, desktop application**. That changes the feature calculus significantly compared to SaaS URL shorteners like Bit.ly or Rebrandly:

- No multi-user, no auth, no billing, no rate limiting
- "Availability" means the local server is running, not uptime SLAs
- Analytics serve personal curiosity, not campaign reporting
- "Sharing" a link means pasting `http://localhost:PORT/abc123` — useful mainly for local testing, bookmarks, or same-machine browser use

Competitor tools surveyed: [Shlink](https://shlink.io/features/), [YOURLS](https://yourls.org/), [Polr](https://polrproject.org/), [Snapp](https://noted.lol/snapp/)

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels broken, not just incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Shorten a URL (input long → output short) | Core purpose of the tool | LOW | Input field + slug generation + persist to SQLite |
| HTTP 301/302 redirect on short URL visit | Without this, there's no "shortener" | LOW | Handled by embedded Dart HTTP server |
| Embedded server starts with app | User expects one launch, not two steps | MEDIUM | Server lifecycle tied to Flutter app lifecycle |
| Persistence across restarts | User expects links to survive closing the app | LOW | SQLite file on disk covers this |
| Copy short URL to clipboard | Users paste links; manual selection is friction | LOW | `Clipboard.setData()` in Flutter |
| Display generated short URL in UI | The one visible result of the core action | LOW | Show in result card after generation |
| Links list / history | Users need to retrieve previously shortened URLs | LOW | Simple SQLite query + ListView |
| Delete a link | Manage link list, remove mistakes | LOW | SQLite DELETE + list refresh |

### Differentiators (Competitive Advantage)

Features that set this tool apart from browser-based SaaS tools. Not required to ship, but valuable for a local tool specifically.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Custom slug (vanity URL) | `localhost/gh` is easier to remember than `localhost/a3f8k` | LOW | Allow user to specify the short code before saving |
| QR code generation | Point phone camera at desktop screen to open URL on mobile | MEDIUM | `qr_flutter` package on pub.dev; purely additive |
| Link expiration (date or click count) | Temporary links for testing flows or sharing with a time window | MEDIUM | Requires a check on every redirect request |
| Click counter per link | See which links are actually used; personal usage insight | LOW | Increment counter on each redirect hit in SQLite |
| Search / filter links list | When list grows, finding a link becomes annoying | LOW | SQLite `LIKE` query or client-side filter |
| One-click re-copy | Tap any link in history to copy it again without re-shortening | LOW | Tap action on list item |
| Open short URL in browser from app | Launch browser directly from link list | LOW | `url_launcher` package |

### Anti-Features (Commonly Requested, Often Problematic)

Features that appear reasonable but add complexity without proportionate value for a local, personal tool.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Click analytics (geo, device, referrer) | Mirrors SaaS URL shorteners | Requires collecting and parsing HTTP headers, storage schema changes, and a UI to display data. Overkill for single-user local tool. | Simple click counter (total hits) is 95% of the value at 5% of the cost |
| Link sharing / public access | "Others should use my short links" | Contradicts the local premise; requires port forwarding, auth, and uptime management. Scope explosion. | Document that links work only on localhost; out of scope by design |
| Custom domain (not localhost) | Branding, professional look | Requires DNS control, TLS certs, reverse proxy config. Completely outside the tool's scope. | Use a self-hosted server-based shortener (Shlink, YOURLS) instead |
| OAuth / social login | Seen in SaaS tools | Single-user local app has no auth problem to solve. Adds complexity with zero benefit. | No auth — access = running the app |
| Import / export from Bit.ly, YOURLS | Migration path | Niche use case for v1; format parsing complexity. | Manual re-entry or defer to v2 |
| API endpoint for external consumers | Automation, CLI use | Adds a separate API design concern; the HTTP server is for redirects, not a REST API | Scope to redirect-only server for now; revisit if scripting use case emerges |
| Browser extension / OS shortcut integration | Frictionless capture | Large scope, platform-specific packaging, security review. Not a v1 concern. | Manual paste into app is acceptable for personal use |

---

## Feature Dependencies

```
[Embedded HTTP server]
    └──required-by──> [Short URL redirect]
    └──required-by──> [Click counter]
    └──required-by──> [Link expiration check]

[SQLite persistence]
    └──required-by──> [Links list / history]
    └──required-by──> [Delete a link]
    └──required-by──> [Click counter]
    └──required-by──> [Custom slug]
    └──required-by──> [Link expiration]

[Links list / history]
    └──enhanced-by──> [Search / filter]
    └──enhanced-by──> [One-click re-copy]
    └──enhanced-by──> [Open in browser from app]

[Shorten a URL]
    └──enhanced-by──> [Custom slug]
    └──enhanced-by──> [QR code generation]

[Click counter] ──enhanced-by──> [Click analytics]
    (analytics deliberately deferred as anti-feature for v1)
```

### Dependency Notes

- **Embedded HTTP server is the foundation**: Every user-facing feature that involves visiting a short URL depends on the server being healthy. Server lifecycle management (start on launch, stop on close, error recovery) must be rock solid before building on top.
- **SQLite required before any link management**: Persistence is the prerequisite for history, delete, custom slugs, and counters. Must be in phase 1.
- **Click counter has no UX value without history list**: A counter that the user never sees is pointless. Pair these together in the same phase.
- **Custom slug conflicts with auto-generation UX**: Need to decide whether slug is always editable (user types it) or generated first with an option to override. Design decision, not a blocker.

---

## MVP Definition

### Launch With (v1)

Minimum viable product — validates that the concept works end to end.

- [ ] Shorten a URL — core value, without this nothing works
- [ ] HTTP redirect on short URL visit — without this there's no "shortener"
- [ ] Embedded server starts/stops with Flutter app — single launch experience
- [ ] SQLite persistence — links survive app restarts
- [ ] Display generated short URL in UI — user sees the result
- [ ] Copy short URL to clipboard — user can actually use the result
- [ ] Links list / history — user can retrieve past links

### Add After Validation (v1.x)

Add once the core redirect loop is proven working and daily-use friction is identified.

- [ ] Delete a link — triggered when user accumulates test links they want to clean up
- [ ] Click counter per link — triggered when user wants to see which links are active
- [ ] Custom slug — triggered when user wants memorable aliases
- [ ] One-click re-copy from history — triggered if re-opening app to get a link is reported as friction
- [ ] Search / filter links list — triggered when list exceeds ~20 entries

### Future Consideration (v2+)

Defer until there's clear personal demand.

- [ ] QR code generation — useful for mobile hand-off but adds a dependency; defer until mobile use case arises
- [ ] Link expiration — niche use case; requires more complex redirect logic
- [ ] Open in browser from app — small convenience; low priority

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Shorten URL (core) | HIGH | LOW | P1 |
| HTTP redirect | HIGH | LOW | P1 |
| Embedded server lifecycle | HIGH | MEDIUM | P1 |
| SQLite persistence | HIGH | LOW | P1 |
| Display short URL | HIGH | LOW | P1 |
| Copy to clipboard | HIGH | LOW | P1 |
| Links list / history | HIGH | LOW | P1 |
| Delete a link | MEDIUM | LOW | P2 |
| Click counter | MEDIUM | LOW | P2 |
| Custom slug | MEDIUM | LOW | P2 |
| One-click re-copy | MEDIUM | LOW | P2 |
| Search / filter | MEDIUM | LOW | P2 |
| QR code | LOW | MEDIUM | P3 |
| Link expiration | LOW | MEDIUM | P3 |
| Open in browser | LOW | LOW | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

---

## Competitor Feature Analysis

| Feature | Shlink (self-hosted server) | YOURLS (self-hosted PHP) | This project |
|---------|-----------------------------|-----------------------------|--------------|
| URL shortening | Yes | Yes | Yes (P1) |
| HTTP redirect | Yes (301/302) | Yes | Yes (P1) |
| Persistence | MySQL/Postgres/SQLite | MySQL | SQLite only |
| Link history | Yes (full UI) | Yes | Yes (P1) |
| Click analytics | Full (geo, device, referrer) | Basic (total clicks) | Counter only (P2) |
| Custom slugs | Yes | Yes | Yes (P2) |
| Multi-user / auth | Yes (API keys) | Yes (admin UI) | No — by design |
| REST API | Yes (full API-first) | Yes | No — not needed |
| QR codes | No | Via plugin | Optional P3 |
| Link expiration | Yes (date + click limit) | Via plugin | Optional P3 |
| Desktop GUI | No (web client) | No (web UI) | Yes — Flutter |
| Offline-first | No (needs server) | No (needs server) | Yes — embedded server |

**Key insight:** Shlink and YOURLS are network services designed for teams or shared infrastructure. This project's differentiator is the **single-process, offline-first, desktop-native** model. Features that require network coordination or multi-user state are explicitly out of scope and represent a different product category.

---

## Sources

- [Shlink features page](https://shlink.io/features/) — HIGH confidence, official docs
- [YOURLS project site](https://yourls.org/) — HIGH confidence, official
- [Shlink GitHub repository](https://github.com/shlinkio/shlink) — HIGH confidence
- [Best self-hosted URL shorteners 2026 — selfhosting.sh](https://selfhosting.sh/best/url-shorteners/) — MEDIUM confidence
- [Snapp self-hosted shortener review — noted.lol](https://noted.lol/snapp/) — MEDIUM confidence
- [Kutt self-hosted shortener review — noted.lol](https://noted.lol/kutt/) — MEDIUM confidence
- PROJECT.md Out of Scope list — HIGH confidence (authoritative for this project)

---
*Feature research for: Local personal URL shortener (Flutter desktop + embedded Dart HTTP server)*
*Researched: 2026-03-26*
