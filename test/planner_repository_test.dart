import 'dart:io';

import 'package:planner_cli/models/planner_item.dart';
import 'package:planner_cli/services/planner_repository.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late PlannerRepository repository;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync();
    final file = File('${tempDir.path}/planner.json');
    repository = PlannerRepository(storageFile: file);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('adds, updates, and deletes items', () async {
    final item = PlannerItem(
      id: 'abc',
      title: 'My Task',
      description: 'Do something',
      dueDate: DateTime.parse('2025-01-01T00:00:00Z'),
    );

    await repository.addItem(item);
    var saved = await repository.loadItems();
    expect(saved, hasLength(1));

    final updated = item.copyWith(status: Status.completed);
    final updateResult = await repository.updateItem(item.id, updated);
    expect(updateResult, isTrue);

    saved = await repository.loadItems();
    expect(saved.first.status, equals(Status.completed));

    final deleteResult = await repository.deleteItem(item.id);
    expect(deleteResult, isTrue);
    expect(await repository.loadItems(), isEmpty);
  });

  test('filters and sorts items', () async {
    final items = [
      PlannerItem(
        id: '1',
        title: 'Low priority',
        description: '',
        dueDate: DateTime.parse('2024-01-01T00:00:00Z'),
        priority: Priority.low,
      ),
      PlannerItem(
        id: '2',
        title: 'High priority',
        description: '',
        dueDate: DateTime.parse('2024-02-01T00:00:00Z'),
        priority: Priority.high,
        status: Status.inProgress,
      ),
    ];

    for (final item in items) {
      await repository.addItem(item);
    }

    final highPriority = await repository.filteredItems(priority: Priority.high);
    expect(highPriority, hasLength(1));
    expect(highPriority.first.id, '2');

    final sortedByPriority =
        await repository.filteredItems(sortOption: SortOption.priority);
    expect(sortedByPriority.first.priority, Priority.high);

    final sortedByStatus = await repository.filteredItems(sortOption: SortOption.status);
    expect(sortedByStatus.last.status, equals(Status.inProgress));
  });
}
