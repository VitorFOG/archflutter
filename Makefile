# Flutter Project Workflow Commands
.PHONY: help emu run run-release run-profile test test-coverage analyze fmt fmt-check clean pub-get pub-upgrade doctor devices apk apk-release bundle gen gen-watch check emu-kill

help:
	@echo "Flutter workflow commands:"
	@echo "  make emu          - Launch Android emulator"
	@echo "  make run          - Run app on device/emulator"
	@echo "  make run-release  - Run app in release mode"
	@echo "  make test         - Run all tests"
	@echo "  make analyze      - Analyze code for issues"
	@echo "  make fmt          - Format all Dart code"
	@echo "  make clean        - Clean build artifacts"
	@echo "  make doctor       - Run flutter doctor"
	@echo "  make devices      - List connected devices"
	@echo "  make apk          - Build debug APK"
	@echo "  make apk-release  - Build release APK"
	@echo "  make check        - Run fmt, analyze, test"

emu:
	@echo "Launching emulator..."
	@emulator @pixel_api34 &
	@sleep 3
	@adb wait-for-device
	@echo "Emulator ready"

run:
	flutter run

run-release:
	flutter run --release

run-profile:
	flutter run --profile

test:
	flutter test

test-coverage:
	flutter test --coverage

analyze:
	flutter analyze

fmt:
	dart format .

fmt-check:
	dart format --set-exit-if-changed .

clean:
	flutter clean

pub-get:
	flutter pub get

pub-upgrade:
	flutter pub upgrade

doctor:
	flutter doctor -v

devices:
	flutter devices

apk:
	flutter build apk --debug

apk-release:
	flutter build apk --release

bundle:
	flutter build appbundle

gen:
	dart run build_runner build --delete-conflicting-outputs

gen-watch:
	dart run build_runner watch --delete-conflicting-outputs

check: fmt analyze test
	@echo "All checks passed!"

emu-kill:
	-adb emu kill
