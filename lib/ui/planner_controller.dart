import 'package:flutter/foundation.dart';

import '../models/planner_item.dart';
import '../services/planner_repository.dart';

/// Coordinates data access and presentation filters for the Flutter UI.
class PlannerController extends ChangeNotifier {
  PlannerController({required this.repository});

  final PlannerRepository repository;

  List<PlannerItem> _items = <PlannerItem>[];
  bool _loading = false;
  String? _error;

  Priority? priorityFilter;
  Status? statusFilter;
  bool overdueOnly = false;
  SortOption sortOption = SortOption.dueDate;

  List<PlannerItem> get items => _items;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> initialize() async {
    await refresh();
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await repository.filteredItems(
        priority: priorityFilter,
        status: statusFilter,
        overdueOnly: overdueOnly,
        sortOption: sortOption,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(PlannerItem item) async {
    await repository.addItem(item);
    await refresh();
  }

  Future<bool> updateItem(String id, PlannerItem updated) async {
    final success = await repository.updateItem(id, updated);
    await refresh();
    return success;
  }

  Future<bool> deleteItem(String id) async {
    final success = await repository.deleteItem(id);
    await refresh();
    return success;
  }

  void updateFilters({
    Priority? priority,
    Status? status,
    bool? overdue,
    SortOption? sort,
  }) {
    priorityFilter = priority;
    statusFilter = status;
    overdueOnly = overdue ?? overdueOnly;
    sortOption = sort ?? sortOption;
    refresh();
  }
}
