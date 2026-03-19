# Bass Builder

Bass Builder is a Flutter port of the original Streamlit enclosure design tool. It provides subwoofer preset selection, enclosure sizing, blueprint views, acoustic charts, exports, and a desktop or web-friendly UI from a single codebase.

## Features

- Sealed, ported, and bandpass enclosure workflows
- Migrated subwoofer preset library from the Python app
- Vehicle template support for common fitment constraints
- Interactive 3D enclosure preview with component placement controls
- Blueprint and cut-list views
- Acoustic response, group delay, and excursion charts
- Export actions for JSON, PDF, PNG, and SVG outputs
- Windows and web build targets from the same Flutter project

## Project Structure

- `lib/models`: app domain models and enums
- `lib/services`: calculations, repositories, exports, and file save adapters
- `lib/state`: provider-based controller and persistence logic
- `lib/widgets`: UI panels, charts, previews, forms, and exports
- `assets/data`: migrated subwoofer and vehicle template datasets

## Local Setup

### Prerequisites

- Flutter stable installed and on `PATH`
- A working Flutter toolchain for your target platforms
- For Windows desktop builds: Visual Studio Build Tools with the C++ workload

### Install dependencies

```bash
flutter pub get
```

### Run on Chrome

```bash
flutter run -d chrome
```

### Run on Windows

```bash
flutter run -d windows
```

### Validate locally

```bash
flutter analyze
flutter test
```

## Build Outputs

### Web

```bash
flutter build web --release
```

### Windows

```bash
flutter build windows --release
```

The generated binaries are placed under `build/web` and `build/windows/x64/runner/Release`.

## GitHub Automation

The repository includes two GitHub Actions workflows:

- `CI`: runs `flutter analyze`, `flutter test`, and a release-mode web build on pushes to `master` and on pull requests
- `Release`: builds zipped web and Windows artifacts and publishes them to a GitHub Release when a tag matching `v*` is pushed

You can also run the release workflow manually from the GitHub Actions tab.

## Versioned Releases

To publish a release with attached artifacts:

```bash
git tag v1.0.0
git push origin v1.0.0
```

That will trigger the release workflow, produce zipped web and Windows artifacts, and attach them to a GitHub Release.

## Current Scope

This repository is the Flutter implementation. The original Streamlit source remains separate. Feature parity is substantial, but this codebase should be treated as an actively evolving port rather than a line-for-line clone of the Python app.
