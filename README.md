# Planner CLI (Dart)

A simple Dart command-line planner for tracking tasks/events with local JSON storage. It supports creating, updating, listing, deleting, filtering, and sorting planner items with validation and basic error handling.

## Prerequisites

- [Dart SDK 3.3+](https://dart.dev/get-dart)

## Getting started

Install dependencies:

```bash
dart pub get
```

Run the interactive CLI:

```bash
dart run bin/main.dart
```

## Usage overview

After launching the CLI, choose an action by number:

1. **Create** – enter title, optional description, due date (ISO 8601 or `YYYY-MM-DD`), and priority (low/medium/high).
2. **Update** – pick an item by ID, then supply new values or press Enter to keep existing ones.
3. **List** – view all items sorted by due date.
4. **Delete** – remove an item by ID.
5. **Filter & sort** – optionally filter by priority/status, show overdue-only, and sort by date/priority/status.

Data is stored in `data/planner_data.json` relative to the repository root. The file is created automatically on first run.

## Testing

Run automated tests:

```bash
dart test
```

## Project structure

- `bin/main.dart` – entrypoint wiring the CLI and storage location.
- `lib/models/planner_item.dart` – core model plus enums and JSON helpers.
- `lib/services/planner_repository.dart` – JSON persistence and filtering/sorting helpers.
- `lib/cli` – interactive menu flow and input validation utilities.
- `test/` – model and workflow coverage.
