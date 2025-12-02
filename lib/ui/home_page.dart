import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/planner_item.dart';
import '../services/planner_repository.dart';
import 'filter_sort_sheet.dart';
import 'item_form_page.dart';
import 'planner_controller.dart';

class PlannerHomePage extends StatefulWidget {
  const PlannerHomePage({super.key, required this.controller});

  final PlannerController controller;

  @override
  State<PlannerHomePage> createState() => _PlannerHomePageState();
}

class _PlannerHomePageState extends State<PlannerHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner'),
        actions: [
          IconButton(
            onPressed: () => _openFilters(context),
            icon: const Icon(Icons.filter_alt_outlined),
            tooltip: 'Filter & sort',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New item'),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading && widget.controller.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.controller.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: ${widget.controller.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: widget.controller.refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: widget.controller.refresh,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _FilterSummary(controller: widget.controller),
                if (widget.controller.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text('No planner items yet. Add one to get started!'),
                    ),
                  )
                else
                  ...widget.controller.items.map(
                    (item) => _PlannerListTile(
                      item: item,
                      onEdit: () => _openForm(context, existing: item),
                      onDelete: () => _confirmDelete(context, item),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openFilters(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => FilterSortSheet(
        priority: widget.controller.priorityFilter,
        status: widget.controller.statusFilter,
        overdueOnly: widget.controller.overdueOnly,
        sortOption: widget.controller.sortOption,
        onChanged: ({priority, status, overdueOnly, sort}) {
          widget.controller.updateFilters(
            priority: priority,
            status: status,
            overdue: overdueOnly,
            sort: sort,
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {PlannerItem? existing}) async {
    final result = await Navigator.pushNamed(
      context,
      PlannerFormPage.routeName,
      arguments: PlannerFormArguments(existing: existing),
    );
    if (result == true) {
      await widget.controller.refresh();
    }
  }

  Future<void> _confirmDelete(BuildContext context, PlannerItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.controller.deleteItem(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${item.title}"')),
        );
      }
    }
  }
}

class _FilterSummary extends StatelessWidget {
  const _FilterSummary({required this.controller});

  final PlannerController controller;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (controller.priorityFilter != null) {
      chips.add(_buildChip('Priority: ${controller.priorityFilter!.name}'));
    }
    if (controller.statusFilter != null) {
      chips.add(_buildChip('Status: ${controller.statusFilter!.name}'));
    }
    if (controller.overdueOnly) {
      chips.add(_buildChip('Overdue only'));
    }
    chips.add(_buildChip('Sorted by ${_labelForSort(controller.sortOption)}'));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  String _labelForSort(SortOption option) {
    switch (option) {
      case SortOption.dueDate:
        return 'due date';
      case SortOption.priority:
        return 'priority';
      case SortOption.status:
        return 'status';
    }
  }

  Widget _buildChip(String label) {
    return Chip(
      avatar: const Icon(Icons.tune, size: 18),
      label: Text(label),
    );
  }
}

class _PlannerListTile extends StatelessWidget {
  const _PlannerListTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final PlannerItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat.yMMMd().add_jm();
    final priorityColor = _priorityColor(item.priority, context);
    final overdue = item.isOverdue;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: priorityColor.withOpacity(0.15),
          child: Icon(
            overdue ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: overdue ? Colors.redAccent : priorityColor,
          ),
        ),
        title: Text(item.title, style: TextStyle(fontWeight: FontWeight.w600, color: overdue ? Colors.red : null)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(item.description),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Due ${formatter.format(item.dueDate)}'),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text('Priority: ${item.priority.name}'),
                  backgroundColor: priorityColor.withOpacity(0.15),
                  labelStyle: TextStyle(color: priorityColor),
                ),
                Chip(
                  label: Text('Status: ${item.status.name}'),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.35),
                ),
                if (overdue)
                  const Chip(
                    label: Text('Overdue', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.redAccent,
                  ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        onTap: onEdit,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
            PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  static Color _priorityColor(Priority priority, BuildContext context) {
    switch (priority) {
      case Priority.high:
        return Colors.redAccent;
      case Priority.medium:
        return Theme.of(context).colorScheme.primary;
      case Priority.low:
        return Colors.green;
    }
  }
}
