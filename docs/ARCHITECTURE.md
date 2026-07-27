# StudentOS Flutter architecture

## Design goals

The conversion keeps the supplied prototype's breadth while separating UI, navigation, state, persistence, and future backend integration. Feature screens depend on typed models and Riverpod providers instead of directly owning cross-screen mutable state.

## Application layer

- `lib/main.dart` initializes `SharedPreferences` before the provider graph starts.
- `lib/app/student_os_app.dart` owns Material 3 app configuration and theme selection.
- `lib/app/router.dart` owns protected navigation, redirect rules, shell branches, deep links, and root-level detail routes.
- `StatefulShellRoute.indexedStack` preserves navigation and scroll state independently across Career, Shop, Home, Food, and More.

## Authentication and session flow

`AuthController` exposes immutable `AuthState`. `AuthRepository` is an interface, while `SharedPreferencesAuthRepository` is the local demo implementation. The router watches auth state and:

- sends signed-out users to `/auth`;
- prevents signed-in users from returning to `/auth`;
- keeps all feature routes protected;
- clears the session on logout.

This boundary allows a production REST, Firebase, Supabase, OAuth, or custom identity implementation to replace local storage without rewriting the presentation layer.

## State management

Riverpod notifier providers own state that is shared, persistent, or behaviorally meaningful:

- authentication and profile;
- student verification;
- settings and theme mode;
- tasks;
- budget and transactions;
- favorites and cart quantities;
- notes;
- event registrations.

Disposable UI-only values, such as a temporary search string or a selected local filter, remain in the screen widget that owns them.

## Data and repository boundary

`lib/data/demo_data.dart` preserves the prototype's catalog, career, food, events, tuition, and marketplace content as typed in-memory data. Real services should be added behind repositories rather than called directly from widgets.

Recommended production layers:

```text
presentation -> application/controller -> repository interface -> API/local data source
```

## Student verification

The converted flow supports:

- university email entry and demo confirmation;
- native document selection through `file_picker`;
- JPG, JPEG, PNG, and PDF filtering;
- a 10 MB client-side size boundary;
- explicit reviewing and verified states.

The current review result is simulated. Production verification must upload securely, validate MIME/content server-side, encrypt documents, enforce retention rules, provide audit logs, and never trust client-side status.

## Persistence

`SharedPreferences` is used only for lightweight prototype state such as session/profile data and settings. Sensitive production tokens should use platform-secure storage, and larger/offline datasets should use an appropriate encrypted database.

## Testing and validation

- `test/controllers_test.dart` covers state transitions for tasks, budget, favorites, and auth.
- `test/widget_test.dart` verifies the signed-out entry experience.
- `tool/validate_structure.py` checks internal imports, source delimiters, declared assets, required files, route count, and controller count.
- `setup.sh` generates native runners and executes Flutter analysis/tests on a machine with Flutter installed.

## Production work still required

Production release requires backend authentication, secure token storage, server-side student verification, payment processing, commerce fulfillment, food ordering, tuition/tutor matching, messaging, push notifications, employer/application APIs, analytics consent, accessibility QA, localization, device testing, crash reporting, API retries, observability, and platform signing/release configuration.
