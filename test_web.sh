#!/bin/bash
echo "Building and serving Flutter web app..."
flutter build web --release
cd build/web
python3 -m http.server 8000 