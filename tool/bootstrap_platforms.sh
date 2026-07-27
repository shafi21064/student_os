#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed or is not on PATH." >&2
  echo "Install Flutter, run 'flutter doctor', then execute ./setup.sh again." >&2
  exit 1
fi

cd "$(dirname "$0")/.."

flutter create \
  --project-name studentos \
  --org app.studentos \
  --platforms=android,ios \
  .
flutter pub get
flutter analyze
flutter test

echo "StudentOS is ready. Connect a device or start an emulator, then run: flutter run"
