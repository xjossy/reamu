#!/bin/bash

# Build script for debug mode
echo "Building in DEBUG mode..."

# Update debug config to enable debug mode
sed -i '' 's/static const bool debugMode = false;/static const bool debugMode = true;/' lib/core/debug_config.dart

# Build the app
flutter build apk --debug

echo "Debug build completed!"
echo "Debug features enabled:"
echo "- Debug button in main menu"
echo "- Floating debug button on all screens"
echo "- Debug logs enabled"
echo "- Debug actions enabled"
