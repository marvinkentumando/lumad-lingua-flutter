#!/bin/bash
set -e

echo "Installing Flutter SDK..."

git clone https://github.com/flutter/flutter.git \
  --depth 1 \
  -b stable \
  "$HOME/flutter"

export PATH="$HOME/flutter/bin:$PATH"

echo "Checking Flutter installation..."
flutter --version

echo "Enabling Flutter Web..."
flutter config --enable-web

echo "Getting Flutter dependencies..."
flutter pub get

echo "Building Flutter Web..."
flutter build web --release

echo "Flutter Web build completed!"
