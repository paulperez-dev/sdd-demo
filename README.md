# SDD demo — local URL shortener

Companion demo for **[Flutter Meetup 2026 Kickoff: AI, Agents & the Future of Development](https://www.youtube.com/watch?v=GUbLTiK76tA)** (26 March 2026), illustrating **Spec-Driven Development (SDD)**: specifications and phased plans as first-class artifacts. Requirements, architecture notes, pitfalls, and step-by-step plans live under `[.planning/](.planning/)` alongside the Flutter code.

**Recording:** [YouTube — Flutter Meetup 2026 Kickoff](https://www.youtube.com/watch?v=GUbLTiK76tA)

## What this app does

A **Flutter desktop** app that runs a **small HTTP server on localhost** (Shelf). You paste a long URL; it stores a random slug in **SQLite** (Drift) and shows a short link like `http://127.0.0.1:8080/your-slug`. Opening that link in a browser **302-redirects** to the original URL. Everything stays on your machine—no third-party shortening service.

The server binds only to **loopback** (`127.0.0.1`) and tries ports **8080–8082** if the default is busy.

## Specs and planning (SDD)


| Path                                                     | Purpose                                 |
| -------------------------------------------------------- | --------------------------------------- |
| `[.planning/REQUIREMENTS.md](.planning/REQUIREMENTS.md)` | Checked requirements (v1 / v2)          |
| `[.planning/ROADMAP.md](.planning/ROADMAP.md)`           | Phased delivery                         |
| `[.planning/research/](.planning/research/)`             | Architecture, stack, features, pitfalls |
| `[.planning/phases/](.planning/phases/)`                 | Per-phase plans and summaries           |


Workshop notes under `.planning/` may include non-English text; this README and most source comments are English.

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (SDK compatible with `pubspec.yaml`, currently **Dart ^3.7**)
- Desktop support enabled for your platform (this repo includes **Windows**; add macOS/Linux in Flutter if you use those)

## Run

```bash
flutter pub get
flutter run -d windows
```

> You can also use `-d macos`.

Drift **generated** files (`*.g.dart`) are committed so a clean clone builds without running codegen. If you change the schema or DAOs, regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## HTTP API (local)

- `**POST /shorten**` — Body: plain text URL, or JSON `{"url":"https://..."}`. Response JSON includes `shortUrl`.
- `**GET /{slug}**` — Redirects to the stored URL, or **404** if unknown.

## Stack (high level)

Flutter · Shelf + shelf_router · Drift (SQLite) · window_manager · url_launcher · path_provider

## License

[MIT](LICENSE) 