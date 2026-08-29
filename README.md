# StudentOS Flutter

A production-structured Flutter conversion of the supplied `demo.app.studentos.com-main` React/Figma prototype.

## What is included

- Sign-in, sign-up, six-digit demo verification, Google demo continuation, persisted local session, profile editing, and logout.
- Protected navigation with 27 routes and five state-preserving main branches: Career, Shop, Home, Food, and More.
- Home dashboard, notifications, global search, profile, and reusable StudentOS design components.
- Shop, wishlist, cart actions, product filtering, details, and saved items.
- Career courses, roadmap content, internships, and typed detail routes.
- Food discovery, restaurant/cuisine filtering, cart interactions, and detail routes.
- Budget Manager, Task Manager, Student ID verification, tuition, Buy & Sell, Marketplace, Events, Notes, Calculator, Bookmarks, Settings, Help, Privacy, and About.
- Student verification through university email or native JPG/JPEG/PNG/PDF selection with a 10 MB validation boundary.
- Material 3 light/dark themes using the updated StudentOS teal, purple, green, coral, and pink palette.
- Riverpod notifier-based state and repository boundaries for auth, settings, tasks, budget, favorites/cart, notes, registrations, and verification.
- Widget/controller tests, attribution preservation, source mapping, and structural validation tooling.

## Run the project

### Prerequisites

1. Install Flutter and add it to `PATH`.
2. Run `flutter doctor` and resolve the Android/iOS requirements for your machine.
3. From this project directory, run:

```bash
chmod +x setup.sh
./setup.sh
```

`setup.sh` generates the standard Android and iOS runner directories, resolves packages, runs static analysis, and runs the test suite. It is equivalent to:

```bash
flutter create \
  --project-name studentos \
  --org app.studentos \
  --platforms=android,ios \
  .
flutter pub get
flutter analyze
flutter test
```

Then connect a device or start an emulator and run:

```bash
flutter run
```

## Demo account

```text
Country code: +880
Mobile:       01700000000
Password:     studentos123
```

The prototype also permits unknown credentials to create a local demo account, matching the supplied front-end behavior.

## Project structure

```text
lib/
  app/                         application bootstrap and protected routing
  core/                       theme, storage providers, and shared widgets
  data/                       typed prototype models and local demo content
  features/
    auth/                     local auth repository, state, and screens
    student_verification/     verification state
    ...                       feature-first screens
  state/                      shared Riverpod domain controllers
assets/
  branding/                   StudentOS source logo
  reference/                  retained source reference images
docs/
  ARCHITECTURE.md
  SCREEN_MAPPING.md
  SOURCE_CONVERSION.md
```

## Backend and security boundary

The supplied project is a front-end prototype, so this package implements safe local demo behavior rather than pretending to include production services. Credentials and sessions are stored locally only for demonstration. Before release, replace the demo auth repository with a secure backend, use platform-secure token storage, verify student documents server-side, and connect real payment, commerce, delivery, messaging, notification, and employer APIs.

## Validation status

The package includes `tool/validate_structure.py` for route, import, asset, and delimiter checks. The official Flutter SDK was not available in the conversion environment, so `flutter analyze`, `flutter test`, simulator/emulator execution, and native builds must be run through `./setup.sh` on a Flutter-enabled machine.
