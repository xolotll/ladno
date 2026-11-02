#!/usr/bin/env bash
set -euo pipefail
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK не найден. Установите Flutter stable и добавьте flutter/bin в PATH." >&2
  exit 1
fi
flutter create --platforms=android,ios --org com.ladno --project-name ladno .
flutter pub get
