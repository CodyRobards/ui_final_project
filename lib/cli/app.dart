import 'dart:io';

import '../models/planner_item.dart';
import '../services/planner_repository.dart';
import 'input_validators.dart';

class PlannerApp {
  PlannerApp({required this.repository});

  final PlannerRepository repository;

  Future<void> run() async {
    stdout.writeln('Welcome to the Dart Planner!');
    while (true) {
      stdout.writeln('\nChoose an action:');
      stdout.writeln('1. Create a new item');
      stdout.writeln('2. Update an item');
      stdout.writeln('3. List items');
      stdout.writeln('4. Delete an item');
      stdout.writeln('5. Filter & sort items');
      stdout.writeln('0. Exit');
      stdout.write('Selection: ');
      final selection = stdin.readLineSync();
      switch (selection) {
        case '1':
          await _createItem();
          break;
        case '2':
          await _updateItem();
          break;
        case '3':
          await _listItems();
          break;
        case '4':
          await _deleteItem();
          break;
        case '5':
          await _filterAndSort();
          break;
        case '0':
          stdout.writeln('Goodbye!');
          return;
        default:
          stdout.writeln('Invalid selection. Please choose again.');
      }
    }
  }

  Future<void> _createItem() async {
    final title = _promptNonEmpty('Enter title: ');
    final description = _promptOptional('Enter description (optional): ');
    final dueDate =
        _promptDate('Enter due date (YYYY-MM-DD or full ISO 8601): ') ?? DateTime.now();
    final priority = _promptPriority();

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final item = PlannerItem(
      id: id,
      title: title,
      description: description ?? '',
      dueDate: dueDate,
      priority: priority,
    );
    await repository.addItem(item);
    stdout.writeln('Item created with id $id.');
  }

  Future<void> _updateItem() async {
    final items = await repository.loadItems();
    if (items.isEmpty) {
      stdout.writeln('No items to update.');
      return;
    }
    _printItems(items);
    stdout.write('Enter the id to update: ');
    final id = stdin.readLineSync();
    final existing = items.firstWhere(
      (item) => item.id == id,
      orElse: () => PlannerItem(
        id: '',
        title: '',
        description: '',
        dueDate: DateTime.now(),
      ),
    );
    if (existing.id.isEmpty) {
      stdout.writeln('Item not found.');
      return;
    }

    final newTitle = _promptOptional('Enter new title (blank to keep "${existing.title}"): ');
    final newDescription = _promptOptional(
      'Enter new description (blank to keep existing): ',
      allowEmpty: true,
    );
    final newDueDate = _promptDate(
      'Enter new due date (blank to keep ${existing.dueDate.toIso8601String()}): ',
      allowBlank: true,
    );
    final newPriority = _promptPriority(allowBlank: true, current: existing.priority);
    final newStatus = _promptStatus(allowBlank: true, current: existing.status);

    final updated = existing.copyWith(
      title: newTitle?.isNotEmpty == true ? newTitle : null,
      description: newDescription ?? existing.description,
      dueDate: newDueDate ?? existing.dueDate,
      priority: newPriority ?? existing.priority,
      status: newStatus ?? existing.status,
    );

    final success = await repository.updateItem(existing.id, updated);
    stdout.writeln(success ? 'Item updated.' : 'Failed to update item.');
  }

  Future<void> _listItems() async {
    final items = await repository.filteredItems(sortOption: SortOption.dueDate);
    if (items.isEmpty) {
      stdout.writeln('No items to display.');
      return;
    }
    _printItems(items);
  }

  Future<void> _deleteItem() async {
    final items = await repository.loadItems();
    if (items.isEmpty) {
      stdout.writeln('No items to delete.');
      return;
    }
    _printItems(items);
    stdout.write('Enter the id to delete: ');
    final id = stdin.readLineSync();
    if (id == null || id.trim().isEmpty) {
      stdout.writeln('Deletion cancelled.');
      return;
    }
    final success = await repository.deleteItem(id.trim());
    stdout.writeln(success ? 'Item deleted.' : 'Item not found.');
  }

  Future<void> _filterAndSort() async {
    stdout.writeln('\nFilter options (press Enter to skip):');
    stdout.writeln('Priority [1=low, 2=medium, 3=high]: ');
    final priority = InputValidators.parsePriority(stdin.readLineSync());

    stdout.writeln('Status [1=pending, 2=in progress, 3=completed]: ');
    final status = InputValidators.parseStatus(stdin.readLineSync());

    stdout.writeln('Show overdue only? [y/N]: ');
    final overdueOnly = (stdin.readLineSync() ?? '').trim().toLowerCase() == 'y';

    stdout.writeln('\nSorting:');
    stdout.writeln('1. Due date (default)');
    stdout.writeln('2. Priority');
    stdout.writeln('3. Status');
    stdout.write('Choose sort option: ');
    final sortSelection = stdin.readLineSync();
    final sortOption = switch (sortSelection) {
      '2' => SortOption.priority,
      '3' => SortOption.status,
      _ => SortOption.dueDate,
    };

    final results = await repository.filteredItems(
      priority: priority,
      status: status,
      overdueOnly: overdueOnly,
      sortOption: sortOption,
    );

    if (results.isEmpty) {
      stdout.writeln('No items matched your filters.');
      return;
    }

    _printItems(results);
  }

  String _promptNonEmpty(String label) {
    while (true) {
      stdout.write(label);
      final input = stdin.readLineSync();
      final validation = InputValidators.validateTitle(input);
      if (validation == null) return input!.trim();
      stdout.writeln(validation);
    }
  }

  String? _promptOptional(String label, {bool allowEmpty = false}) {
    stdout.write(label);
    final input = stdin.readLineSync();
    if (allowEmpty) return input;
    return input?.trim().isEmpty == true ? null : input?.trim();
  }

  DateTime? _promptDate(String label, {bool allowBlank = false}) {
    while (true) {
      stdout.write(label);
      final input = stdin.readLineSync();
      if (allowBlank && (input == null || input.trim().isEmpty)) {
        return null;
      }
      final parsed = InputValidators.parseDueDate(input);
      if (parsed != null) return parsed;
      stdout.writeln('Please enter a valid date.');
    }
  }

  Priority _promptPriority({bool allowBlank = false, Priority? current}) {
    while (true) {
      stdout.write('Priority [1=low, 2=medium, 3=high${current != null ? ', current ${current.name}' : ''}]: ');
      final input = stdin.readLineSync();
      if (allowBlank && (input == null || input.trim().isEmpty)) {
        return current ?? Priority.medium;
      }
      final priority = InputValidators.parsePriority(input);
      if (priority != null) return priority;
      stdout.writeln('Please enter 1, 2, or 3.');
    }
  }

  Status _promptStatus({bool allowBlank = false, Status? current}) {
    while (true) {
      stdout.write('Status [1=pending, 2=in progress, 3=completed${current != null ? ', current ${current.name}' : ''}]: ');
      final input = stdin.readLineSync();
      if (allowBlank && (input == null || input.trim().isEmpty)) {
        return current ?? Status.pending;
      }
      final status = InputValidators.parseStatus(input);
      if (status != null) return status;
      stdout.writeln('Please enter 1, 2, or 3.');
    }
  }

  void _printItems(List<PlannerItem> items) {
    stdout.writeln('\nItems:');
    for (final item in items) {
      final due = item.dueDate.toIso8601String();
      final overdue = item.isOverdue ? ' (overdue)' : '';
      stdout.writeln('- ${item.id}: ${item.title}');
      stdout.writeln('  Description: ${item.description.isEmpty ? '—' : item.description}');
      stdout.writeln('  Due: $due$overdue');
      stdout.writeln('  Priority: ${item.priority.name} | Status: ${item.status.name}');
    }
  }
}
