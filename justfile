# Flutter Project Workflow Commands
# Install just: sudo pacman -S just

# Default recipe - show help
default:
    @just --list

# Launch the Android emulator (pixel_api34)
emu:
    @echo "Launching emulator..."
    emulator @pixel_api34 &
    @sleep 3
    adb wait-for-device
    @echo "Emulator ready"

# Run flutter app on connected device/emulator
run:
    flutter run

# Run flutter app in release mode
run-release:
    flutter run --release

# Run flutter app in profile mode (for performance testing)
run-profile:
    flutter run --profile

# Run all tests
test:
    flutter test

# Run tests with coverage
test-coverage:
    flutter test --coverage

# Analyze code for issues
analyze:
    flutter analyze

# Format all Dart code
fmt:
    dart format .

# Check formatting without changes
fmt-check:
    dart format --set-exit-if-changed .

# Clean build artifacts
clean:
    flutter clean

# Get dependencies
pub-get:
    flutter pub get

# Upgrade dependencies
pub-upgrade:
    flutter pub upgrade

# Run flutter doctor
doctor:
    flutter doctor -v

# List connected devices
devices:
    flutter devices

# Build APK (debug)
apk:
    flutter build apk --debug

# Build APK (release)
apk-release:
    flutter build apk --release

# Build App Bundle (for Play Store)
bundle:
    flutter build appbundle

# Generate code (build_runner)
gen:
    dart run build_runner build --delete-conflicting-outputs

# Watch for code generation changes
gen-watch:
    dart run build_runner watch --delete-conflicting-outputs

# Full check: format, analyze, test
check: fmt analyze test
    @echo "All checks passed!"

# Kill running emulator
emu-kill:
    adb emu kill || true
