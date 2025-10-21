#!/bin/bash

# Build script for production mode
echo "Building in PRODUCTION mode..."

# Update debug config to disable debug mode
sed -i '' 's/static const bool debugMode = true;/static const bool debugMode = false;/' lib/core/debug_config.dart

# Build the app
flutter build apk --release

echo "Production build completed!"
echo "Debug features disabled:"
echo "- No debug buttons"
echo "- No debug logs"
echo "- No debug actions"
