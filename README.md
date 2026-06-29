# BillParty

> Split group expenses without anyone having to sign up. Offline-first, no backend, no accounts — your data never leaves the phone.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-Dart-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey.svg)](#)
[![Offline-first](https://img.shields.io/badge/offline-first-success.svg)](#)

**BillParty** is a small app for splitting shared expenses across a group — a trip, a flat, a night out. One person (the *organizer*) installs it and keeps the group's accounts. There are no accounts to create, no servers, and no cloud.

*Tagline: "Split the bill, keep the party going."*

---

## Why

When several people share expenses, tracking them on paper is tedious and error-prone, and existing apps **force everyone to create an account**. BillParty removes that friction: **only the organizer installs the app**, and everyone else just receives a summary to read.

This isn't an accidental limitation — it's the whole point. Keeping the state on a single device is exactly what makes BillParty **100% offline and a good fit for F-Droid**, and it's the main difference from tools like Splitwise.

## Features

- **Plans** — a group/event with its own people and expenses (e.g. "Trip to Cartagena").
- **Flexible splitting** — split an expense *equally*, by *exact amounts*, or by *shares* (e.g. "the couple counts double").
- **Balances** — see at a glance who is owed and who owes.
- **Settle up** — the app computes the *minimum* set of payments to make everyone even.
- **Share a snapshot** — export the summary as text or a QR code. No live sync, no servers.
- **Exact money** — amounts are stored as integers, so balances are always exact (no floating-point drift).

## Privacy by design

- **Offline-first** — works in airplane mode, always.
- **No accounts** — open the app and use it.
- **No network** — the data never leaves your device. There is nothing to leak.

## Tech stack

- **Flutter** + **Dart** — cross-platform UI (Android & iOS).
- **SQLite** — local, multi-plan persistence.
- **Hexagonal architecture** — a pure domain at the core, with infrastructure (database, sharing) at the edges.
- **Tested domain** — the money math (splitting, balances, debt simplification) is covered by unit and property-based tests.

## Architecture

The domain knows nothing about Flutter or SQLite. The rules that must always hold live in the center; the database and UI are just details at the boundary.

```
lib/
├─ domain/          ← pure business logic (models, splitting, balances, settle-up)
├─ application/     ← use cases that orchestrate the domain
├─ infrastructure/  ← SQLite repositories, share/QR generation
└─ ui/              ← screens and widgets
```

## Getting started

```bash
flutter pub get
flutter run
```

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install).

## Roadmap

- [ ] MVP: plans, people, expenses, the three split modes, balances and settle-up.
- [ ] Share summary as text.
- [ ] Share as image / read-only QR.
- [ ] Distribution via F-Droid (and optionally Google Play).
- [ ] Extra split modes (percentage, per-item), multi-currency, JSON backup.

## Contributing

Contributions are welcome. BillParty is community-owned and intentionally simple — adding a feature should mean adding a small, well-tested piece, not rewiring the core.

## License

Released under the [MIT License](LICENSE).
