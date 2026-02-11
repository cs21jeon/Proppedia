# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Propedia (부동산백과) is a Flutter real estate encyclopedia app targeting multiple platforms (Android, iOS, Web, Windows, macOS, Linux).

## Build and Development Commands

```bash
# Get dependencies
flutter pub get

# Run code generators (freezed, json_serializable, retrofit, riverpod, isar)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation during development
dart run build_runner watch --delete-conflicting-outputs

# Run the app
flutter run

# Run on specific device
flutter run -d windows
flutter run -d chrome
flutter run -d android

# Analyze code
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart
```

## Architecture

The project follows **Clean Architecture** with the following layer structure:

```
lib/
├── main.dart              # Entry point with ProviderScope
├── app.dart               # Root MaterialApp with theme configuration
├── core/                  # Framework-level utilities
│   ├── constants/         # App-wide colors (AppColors), typography (AppTextStyles)
│   ├── network/           # Dio/Retrofit network configuration
│   ├── router/            # go_router configuration
│   └── utils/             # Utility functions
├── data/                  # Data layer
│   ├── datasources/       # Remote (API) and local (Isar) data sources
│   ├── dto/               # Data Transfer Objects for API
│   ├── models/            # Isar database models
│   └── repositories/      # Repository implementations
├── domain/                # Domain layer (business logic)
│   ├── entities/          # Business entities (freezed)
│   ├── repositories/      # Repository interfaces (abstract classes)
│   └── usecases/          # Use case classes
├── presentation/          # UI layer
│   ├── providers/         # Riverpod providers
│   ├── screens/           # Feature screens (auth, home, search, result, favorites, history, profile)
│   └── widgets/           # Reusable widgets (building, common, property)
└── shared/                # Cross-cutting concerns
    ├── extensions/        # Dart extension methods
    └── theme/             # AppTheme (light/dark Material3 themes)
```

## Key Technologies

- **State Management**: Riverpod with code generation (`@riverpod` annotations)
- **Networking**: Dio + Retrofit with generated API clients
- **Local Storage**: Isar database (generated models), SharedPreferences, FlutterSecureStorage
- **Routing**: go_router for declarative navigation
- **Data Classes**: Freezed for immutable models with JSON serialization
- **Maps**: Kakao Map Plugin with Geolocator for location services

## Code Generation

This project heavily relies on code generation. After modifying files with:
- `@freezed` annotations (entities, DTOs)
- `@riverpod` annotations (providers)
- `@RestApi` annotations (Retrofit clients)
- `@Collection` annotations (Isar models)

Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `.g.dart` and `.freezed.dart` files.

## Design System

- Colors defined in `lib/core/constants/app_colors.dart`
- Typography defined in `lib/core/constants/app_text_styles.dart`
- Complete light/dark themes in `lib/shared/theme/app_theme.dart`
- Uses Material 3 design system
