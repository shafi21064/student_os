# Conversion notes

## Source inspected

The uploaded project is a React/TypeScript Figma Make prototype centered in `src/app/App.tsx`, with source branding and attribution files. It is broader than a static visual mockup and includes authentication, profile/session behavior, five main tabs, student services, catalogs, productivity tools, details, and verification flows.

## Flutter translation decisions

- React view state became local Flutter widget state when it was temporary and screen-specific.
- Cross-screen state became Riverpod notifier state.
- React navigation/modal transitions became `go_router` routes.
- The five main sections use an indexed shell to preserve state.
- The source logo is retained under `assets/branding/`.
- Source attribution is preserved in the project root.
- Browser file selection became native `file_picker` document selection.
- Browser local session behavior became a replaceable `AuthRepository` backed by `SharedPreferences` for the demo.

## Deliberately simulated behavior

The following remain local prototype implementations because the source did not contain production backends:

- identity verification and password authentication;
- Google sign-in;
- student document review;
- payments and tuition transactions;
- marketplace, shop, and food checkout;
- employer applications and course enrollment;
- real notifications and messaging.

These flows are clearly separated so production repositories and APIs can replace the mock implementations without redesigning every screen.
