# Planner CLI & Flutter UI

A simple planner with both a Dart command-line interface and a Flutter client. Tasks are stored locally in JSON and support creating, updating, listing, deleting, filtering, and sorting with validation and basic error handling.

## Prerequisites

- [Flutter SDK 3.19+](https://docs.flutter.dev/get-started/install) (includes `dart` for the CLI)

## Getting started

Install dependencies:

```bash
flutter pub get
```

### Run the CLI

```bash
dart run bin/main.dart
```

The CLI persists data to `data/planner_data.json` in the repository root.

### Run the Flutter UI

Launch the Flutter experience on a supported device/emulator (mobile or desktop):

```bash
flutter run -d macos   # or windows, linux, ios, android
```

The UI uses the same models and repository as the CLI. Data is stored in a JSON file named `planner_data.json` inside the platform-specific application documents/support directory (mobile/desktop). On unsupported platforms, the app falls back to a local `data/` folder.

## Usage overview

After launching, you can:

1. **Create** – enter title, optional description, due date (ISO 8601 or `YYYY-MM-DD`), and priority (low/medium/high).
2. **Update** – edit an existing item’s fields and status.
3. **List** – view all items with overdue/high-priority indicators.
4. **Delete** – remove an item with confirmation.
5. **Filter & sort** – filter by priority/status, toggle overdue-only, and sort by date/priority/status.

## Testing

Run automated tests (CLI/Flutter-aware):

```bash
flutter test
```

## Project structure

- `bin/main.dart` – CLI entrypoint wiring the repository and storage location.
- `lib/main.dart` – Flutter entrypoint that resolves the platform storage path and launches the UI.
- `lib/ui` – Flutter presentation layer, routing, forms, filters, and list views.
- `lib/models/planner_item.dart` – core model plus enums and JSON helpers.
- `lib/services/planner_repository.dart` – JSON persistence and filtering/sorting helpers.
- `lib/cli` – interactive menu flow and input validation utilities.
- `test/` – model and workflow coverage.
