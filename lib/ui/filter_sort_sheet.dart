import 'package:flutter/material.dart';

import '../models/planner_item.dart';
import '../services/planner_repository.dart';

class FilterSortSheet extends StatefulWidget {
  const FilterSortSheet({
    super.key,
    this.priority,
    this.status,
    required this.overdueOnly,
    required this.sortOption,
    required this.onChanged,
  });

  final Priority? priority;
  final Status? status;
  final bool overdueOnly;
  final SortOption sortOption;
  final void Function({Priority? priority, Status? status, bool? overdueOnly, SortOption? sort}) onChanged;

  @override
  State<FilterSortSheet> createState() => _FilterSortSheetState();
}

class _FilterSortSheetState extends State<FilterSortSheet> {
  Priority? _priority;
  Status? _status;
  late bool _overdueOnly;
  late SortOption _sortOption;

  @override
  void initState() {
    super.initState();
    _priority = widget.priority;
    _status = widget.status;
    _overdueOnly = widget.overdueOnly;
    _sortOption = widget.sortOption;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filters & sorting', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Priority?>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem<Priority?>(value: null, child: Text('All')),
                DropdownMenuItem<Priority?>(value: Priority.low, child: Text('Low')),
                DropdownMenuItem<Priority?>(value: Priority.medium, child: Text('Medium')),
                DropdownMenuItem<Priority?>(value: Priority.high, child: Text('High')),
              ],
              onChanged: (value) => setState(() => _priority = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Status?>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem<Status?>(value: null, child: Text('All')),
                DropdownMenuItem<Status?>(value: Status.pending, child: Text('Pending')),
                DropdownMenuItem<Status?>(value: Status.inProgress, child: Text('In progress')),
                DropdownMenuItem<Status?>(value: Status.completed, child: Text('Completed')),
              ],
              onChanged: (value) => setState(() => _status = value),
            ),
            SwitchListTile(
              value: _overdueOnly,
              title: const Text('Show overdue only'),
              onChanged: (value) => setState(() => _overdueOnly = value),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Sort by', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ...SortOption.values.map(
              (option) => RadioListTile<SortOption>(
                value: option,
                groupValue: _sortOption,
                title: Text(_labelForSort(option)),
                onChanged: (value) => setState(() => _sortOption = value ?? _sortOption),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      widget.onChanged(
                        priority: _priority,
                        status: _status,
                        overdueOnly: _overdueOnly,
                        sort: _sortOption,
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Apply'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _priority = null;
                        _status = null;
                        _overdueOnly = false;
                        _sortOption = SortOption.dueDate;
                      });
                      widget.onChanged(
                        priority: null,
                        status: null,
                        overdueOnly: false,
                        sort: SortOption.dueDate,
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _labelForSort(SortOption option) {
    switch (option) {
      case SortOption.dueDate:
        return 'Due date';
      case SortOption.priority:
        return 'Priority';
      case SortOption.status:
        return 'Status';
    }
  }
}
