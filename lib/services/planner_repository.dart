import 'dart:convert';
import 'dart:io';

import '../models/planner_item.dart';

/// Provides persistence and operations for planner items.
class PlannerRepository {
  PlannerRepository({required this.storageFile});

  final File storageFile;

  /// Loads all planner items from disk. Returns an empty list when none exist.
  Future<List<PlannerItem>> loadItems() async {
    if (!await storageFile.exists()) {
      await storageFile.create(recursive: true);
      await storageFile.writeAsString(jsonEncode(<PlannerItem>[]));
      return <PlannerItem>[];
    }

    final content = await storageFile.readAsString();
    if (content.trim().isEmpty) {
      return <PlannerItem>[];
    }

    final dynamic data = jsonDecode(content);
    if (data is! List) {
      throw const FormatException('Invalid planner data.');
    }

    return data.map((item) => PlannerItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Saves items to disk.
  Future<void> saveItems(List<PlannerItem> items) async {
    final payload = jsonEncode(items.map((item) => item.toJson()).toList());
    await storageFile.writeAsString(payload);
  }

  /// Adds a new item and persists the updated collection.
  Future<void> addItem(PlannerItem item) async {
    final items = await loadItems();
    items.add(item);
    await saveItems(items);
  }

  /// Updates an existing item by id.
  Future<bool> updateItem(String id, PlannerItem updated) async {
    final items = await loadItems();
    final index = items.indexWhere((item) => item.id == id);
    if (index == -1) {
      return false;
    }
    items[index] = updated;
    await saveItems(items);
    return true;
  }

  /// Deletes an item by id.
  Future<bool> deleteItem(String id) async {
    final items = await loadItems();
    final updated = items.where((item) => item.id != id).toList();
    if (items.length == updated.length) {
      return false;
    }
    await saveItems(updated);
    return true;
  }

  /// Returns items filtered by optional criteria and sorted.
  Future<List<PlannerItem>> filteredItems({
    Priority? priority,
    Status? status,
    bool overdueOnly = false,
    SortOption sortOption = SortOption.dueDate,
  }) async {
    final items = await loadItems();
    final filtered = items.where((item) {
      final priorityMatch = priority == null || item.priority == priority;
      final statusMatch = status == null || item.status == status;
      final overdueMatch = !overdueOnly || item.isOverdue;
      return priorityMatch && statusMatch && overdueMatch;
    }).toList();

    filtered.sort((a, b) => sortOption.compare(a, b));
    return filtered;
  }
}

/// Sorting options supported by the CLI.
enum SortOption { dueDate, priority, status }

extension on SortOption {
  int compare(PlannerItem a, PlannerItem b) {
    switch (this) {
      case SortOption.dueDate:
        return a.dueDate.compareTo(b.dueDate);
      case SortOption.priority:
        return _priorityRank(a.priority).compareTo(_priorityRank(b.priority));
      case SortOption.status:
        return _statusRank(a.status).compareTo(_statusRank(b.status));
    }
  }

  int _priorityRank(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 2;
      case Priority.medium:
        return 1;
      case Priority.high:
        return 0;
    }
  }

  int _statusRank(Status status) {
    switch (status) {
      case Status.pending:
        return 0;
      case Status.inProgress:
        return 1;
      case Status.completed:
        return 2;
    }
  }
}
