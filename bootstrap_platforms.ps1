$ErrorActionPreference = "Stop"
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter SDK не найден. Установите Flutter stable и добавьте flutter/bin в PATH."
}
flutter create --platforms=android,ios --org com.ladno --project-name ladno .
if ($LASTEXITCODE -ne 0) { throw "flutter create завершился с ошибкой" }
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get завершился с ошибкой" }
