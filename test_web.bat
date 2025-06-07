@echo off
echo Building and serving Flutter web app...
flutter build web --release
cd build/web
python -m http.server 8000 