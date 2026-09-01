@echo off
cd /d "%~dp0"
if not exist "pubspec.yaml" (
  echo File pubspec.yaml tidak ditemukan.
  pause
  exit /b 1
)

echo Menjalankan Flutter Desktop...
echo Pastikan Flutter SDK sudah terinstall dan ada di PATH.
flutter pub get
flutter run -d windows
pause
