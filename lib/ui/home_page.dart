import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/planner_item.dart';
import '../services/planner_repository.dart';
import 'filter_sort_sheet.dart';
import 'item_form_page.dart';
import 'planner_controller.dart';
import 'app.dart';

enum PlannerView { list, board }

class PlannerHomePage extends StatefulWidget {
  const PlannerHomePage({super.key, required this.controller});

  final PlannerController controller;

  @override
  State<PlannerHomePage> createState() => _PlannerHomePageState();
}

class _PlannerHomePageState extends State<PlannerHomePage> {
  PlannerView _view = PlannerView.list;
  String? _selectedId;

  PlannerTokens get _tokens =>
      Theme.of(context).extension<PlannerTokens>() ??
      PlannerTokens.fromSeed(seedColor: PlannerTheme.defaultSeed);

  void _syncSelection(List<PlannerItem> items, bool enableDetail) {
    if (!enableDetail && _selectedId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedId = null);
      });
      return;
    }

    if (!enableDetail || items.isEmpty) {
      return;
    }

    final stillExists = items.any((item) => item.id == _selectedId);
    if (_selectedId == null || !stillExists) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedId = items.first.id);
      });
    }
  }

  PlannerItem? _selectedItem(List<PlannerItem> items) {
    if (_selectedId == null || items.isEmpty) return null;
    return items.firstWhere(
      (item) => item.id == _selectedId,
      orElse: () => items.first,
    );
  }

  Future<void> _moveItemToStatus(PlannerItem item, Status status) async {
    if (item.status == status) return;
    final updated = item.copyWith(status: status);
    await widget.controller.updateItem(item.id, updated);
    if (!mounted) return;
    setState(() => _selectedId = updated.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Moved "${item.title}" to ${status.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner'),
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
                  Text('Error: ${widget.controller.error}',
                      textAlign: TextAlign.center),
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

          return LayoutBuilder(
            builder: (context, constraints) {
              final items = widget.controller.items;
              final isWide = constraints.maxWidth >= 1024;
              final isTablet = constraints.maxWidth >= 720;
              final columns = isWide ? 3 : (isTablet ? 2 : 1);
              final padding = EdgeInsets.symmetric(
                horizontal: isWide
                    ? 36
                    : isTablet
                        ? 24
                        : 14,
                vertical: 12,
              );

              _syncSelection(items, isWide && _view == PlannerView.list);

              if (_view == PlannerView.board) {
                return RefreshIndicator(
                  onRefresh: widget.controller.refresh,
                  child: _PlannerBoard(
                    items: items,
                    padding: padding,
                    onMove: _moveItemToStatus,
                    onEdit: (item) => _openForm(context, existing: item),
                    onToggleView: (view) => setState(() => _view = view),
                    onOpenFilters: () => _openFilters(context),
                  ),
                );
              }

              final listArea = _PlannerListArea(
                items: items,
                padding: padding,
                columns: columns,
                selectedId: _selectedId,
                onTap: (item) => _handleTap(item, isWide),
                onEdit: (item) => _openForm(context, existing: item),
                onDelete: (item) => _confirmDelete(context, item),
                onToggleView: (view) => setState(() => _view = view),
                onRefresh: widget.controller.refresh,
                controller: widget.controller,
                onOpenFilters: () => _openFilters(context),
                view: _view,
              );

              if (!isWide) {
                return listArea;
              }

              final selected = _selectedItem(items);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: listArea),
                  SizedBox(width: _tokens.gutter),
                  Expanded(
                    flex: 2,
                    child: _PlannerDetailPanel(
                      item: selected,
                      tokens: _tokens,
                      onEdit: selected == null
                          ? null
                          : () => _openForm(context, existing: selected),
                      onDelete: selected == null
                          ? null
                          : () => _confirmDelete(context, selected),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _handleTap(PlannerItem item, bool allowSelection) {
    if (allowSelection) {
      setState(() => _selectedId = item.id);
    } else {
      _openForm(context, existing: item);
    }
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
        title: const Text('Delete item?'),
        content: Text('Delete "${item.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
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

class _PlannerListArea extends StatelessWidget {
  const _PlannerListArea({
    required this.items,
    required this.padding,
    required this.columns,
    required this.selectedId,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleView,
    required this.onRefresh,
    required this.controller,
    required this.onOpenFilters,
    required this.view,
  });

  final List<PlannerItem> items;
  final EdgeInsets padding;
  final int columns;
  final String? selectedId;
  final ValueChanged<PlannerItem> onTap;
  final ValueChanged<PlannerItem> onEdit;
  final ValueChanged<PlannerItem> onDelete;
  final ValueChanged<PlannerView> onToggleView;
  final Future<void> Function() onRefresh;
  final PlannerController controller;
  final VoidCallback onOpenFilters;
  final PlannerView view;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PlannerTokens>() ??
        PlannerTokens.fromSeed(seedColor: PlannerTheme.defaultSeed);
    final bool useGrid = columns > 1;
    final spacing = tokens.gutter;
    final gridMainAxisExtent = columns >= 3 ? 340.0 : 320.0;
    final sliverItems = useGrid
        ? SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];
                return _PlannerGridCard(
                  item: item,
                  tokens: tokens,
                  isSelected: item.id == selectedId,
                  onTap: () => onTap(item),
                  onEdit: () => onEdit(item),
                  onDelete: () => onDelete(item),
                );
              },
              childCount: items.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              mainAxisExtent: gridMainAxisExtent,
            ),
          )
        : SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: index == items.length - 1 ? 0 : spacing),
                  child: _PlannerListTile(
                    item: item,
                    tokens: tokens,
                    selected: item.id == selectedId,
                    onEdit: () => onEdit(item),
                    onDelete: () => onDelete(item),
                    onTap: () => onTap(item),
                  ),
                );
              },
              childCount: items.length,
            ),
          );

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                padding.left, padding.top, padding.right, 8),
            sliver: SliverToBoxAdapter(
              child: _PageHeader(
                view: view,
                onToggle: onToggleView,
                onOpenFilters: onOpenFilters,
              ),
            ),
          ),
          SliverPadding(
            padding:
                EdgeInsets.symmetric(horizontal: padding.left, vertical: 4),
            sliver: SliverToBoxAdapter(
              child: _FilterSummary(controller: controller),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                padding.left, 8, padding.right, padding.bottom + 72),
            sliver: items.isEmpty
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                            'No planner items yet. Add one to get started!'),
                      ),
                    ),
                  )
                : sliverItems,
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader(
      {required this.view,
      required this.onToggle,
      required this.onOpenFilters});

  final PlannerView view;
  final ValueChanged<PlannerView> onToggle;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PlannerTokens>() ??
        PlannerTokens.fromSeed(seedColor: PlannerTheme.defaultSeed);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your plan dashboard', style: tokens.hero),
              const SizedBox(height: 4),
              Text('Manage your tasks and stay organized!',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        IconButton(
          onPressed: onOpenFilters,
          tooltip: 'Filter & sort',
          icon: const Icon(Icons.filter_alt_outlined),
        ),
        const SizedBox(width: 8),
        SegmentedButton<PlannerView>(
          segments: const [
            ButtonSegment(value: PlannerView.list, label: Text('List')),
            ButtonSegment(value: PlannerView.board, label: Text('Board')),
          ],
          selected: {view},
          onSelectionChanged: (selection) => onToggle(selection.first),
        ),
      ],
    );
  }
}

class _PlannerBoard extends StatelessWidget {
  const _PlannerBoard({
    required this.items,
    required this.padding,
    required this.onMove,
    required this.onEdit,
    required this.onToggleView,
    required this.onOpenFilters,
  });

  final List<PlannerItem> items;
  final EdgeInsets padding;
  final Future<void> Function(PlannerItem, Status) onMove;
  final void Function(PlannerItem) onEdit;
  final ValueChanged<PlannerView> onToggleView;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PlannerTokens>() ??
        PlannerTokens.fromSeed(seedColor: PlannerTheme.defaultSeed);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding:
              EdgeInsets.fromLTRB(padding.left, padding.top, padding.right, 8),
          sliver: SliverToBoxAdapter(
            child: _PageHeader(
              view: PlannerView.board,
              onToggle: onToggleView,
              onOpenFilters: onOpenFilters,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: padding.left, vertical: 4),
          sliver: SliverToBoxAdapter(child: _BoardLegend(tokens: tokens)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                padding.left, 8, padding.right, padding.bottom + 48),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final targetColumns = (width / 280).floor().clamp(1, 3);
                final columnWidth =
                    (width - (tokens.gutter * (targetColumns - 1))) /
                        targetColumns;
                return Wrap(
                  spacing: tokens.gutter,
                  runSpacing: tokens.gutter,
                  children: Status.values.map((status) {
                    final bucket =
                        items.where((item) => item.status == status).toList();
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: columnWidth,
                        maxWidth: columnWidth,
                      ),
                      child: _StatusColumn(
                        status: status,
                        tokens: tokens,
                        items: bucket,
                        onMove: onMove,
                        onEdit: onEdit,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _BoardLegend extends StatelessWidget {
  const _BoardLegend({required this.tokens});

  final PlannerTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: tokens.gutter,
      runSpacing: tokens.gutter,
      children: [
        Chip(
          avatar: const Icon(Icons.drag_handle),
          label: const Text('Long-press to drag'),
          backgroundColor: tokens.surface,
        ),
        Chip(
          avatar: const Icon(Icons.auto_awesome),
          label: const Text('Drop to change status'),
          backgroundColor: tokens.surface,
        ),
        Chip(
          avatar: const Icon(Icons.swipe_left_alt),
          label: const Text('Tap to edit details'),
          backgroundColor: tokens.surface,
        ),
      ],
    );
  }
}

class _StatusColumn extends StatelessWidget {
  const _StatusColumn({
    required this.status,
    required this.tokens,
    required this.items,
    required this.onMove,
    required this.onEdit,
  });

  final Status status;
  final PlannerTokens tokens;
  final List<PlannerItem> items;
  final Future<void> Function(PlannerItem, Status) onMove;
  final void Function(PlannerItem) onEdit;

  @override
  Widget build(BuildContext context) {
    return DragTarget<PlannerItem>(
      onWillAccept: (data) => data?.status != status,
      onAccept: (data) => onMove(data, status),
      builder: (context, candidates, rejects) {
        final isHighlighted = candidates.isNotEmpty;
        return Card(
          color: isHighlighted ? tokens.surfaceMuted : tokens.surface,
          child: Padding(
            padding: EdgeInsets.all(tokens.gutter - 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: _statusColor(status, Theme.of(context)),
                      child: Icon(_statusIcon(status),
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(status.name, style: tokens.emphasis),
                    const Spacer(),
                    if (isHighlighted) const Icon(Icons.inbox, size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  Text('Drop tasks here',
                      style: Theme.of(context).textTheme.bodySmall)
                else
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: LongPressDraggable<PlannerItem>(
                        data: item,
                        feedback: Material(
                          color: Colors.transparent,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: _PlannerGridCard(
                              item: item,
                              tokens: tokens,
                              isSelected: false,
                              onTap: () {},
                              onEdit: () {},
                              onDelete: () {},
                              showActions: false,
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.35,
                          child: _PlannerGridCard(
                            item: item,
                            tokens: tokens,
                            isSelected: false,
                            onTap: () {},
                            onEdit: () {},
                            onDelete: () {},
                            showActions: false,
                          ),
                        ),
                        child: _PlannerGridCard(
                          item: item,
                          tokens: tokens,
                          isSelected: false,
                          onTap: () => onEdit(item),
                          onEdit: () => onEdit(item),
                          onDelete: () {},
                          showActions: false,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _statusIcon(Status status) {
    switch (status) {
      case Status.pending:
        return Icons.pause_circle_outline;
      case Status.inProgress:
        return Icons.play_circle_outline;
      case Status.completed:
        return Icons.check_circle_outline;
    }
  }

  Color _statusColor(Status status, ThemeData theme) {
    switch (status) {
      case Status.pending:
        return theme.colorScheme.secondary;
      case Status.inProgress:
        return theme.colorScheme.tertiary;
      case Status.completed:
        return Colors.green;
    }
  }
}

class _PlannerDetailPanel extends StatelessWidget {
  const _PlannerDetailPanel({
    required this.item,
    required this.tokens,
    this.onEdit,
    this.onDelete,
  });

  final PlannerItem? item;
  final PlannerTokens tokens;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(tokens.gutter + 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.dashboard_customize,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text('Select an item to see details',
                  style: tokens.emphasis, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final formatter = DateFormat.yMMMd().add_jm();
    final overdue = item!.isOverdue;
    final priorityColor = _priorityColor(item!.priority, context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(tokens.gutter + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item!.title, style: tokens.hero)),
                FilledButton.tonal(
                    onPressed: onEdit, child: const Text('Edit')),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item!.description.isEmpty
                ? 'No description provided.'
                : item!.description),
            const SizedBox(height: 12),
            Wrap(
              spacing: tokens.gutter,
              runSpacing: tokens.gutter / 2,
              children: [
                Chip(
                  avatar: const Icon(Icons.schedule),
                  label: Text('Due ${formatter.format(item!.dueDate)}'),
                ),
                Chip(
                  avatar: const Icon(Icons.flag_outlined),
                  label: Text('Priority: ${item!.priority.name}'),
                  backgroundColor: priorityColor.withOpacity(0.15),
                  labelStyle: TextStyle(color: priorityColor),
                ),
                Chip(
                  avatar: const Icon(Icons.checklist_rtl),
                  label: Text('Status: ${item!.status.name}'),
                ),
                if (overdue)
                  const Chip(
                    avatar:
                        Icon(Icons.warning_amber_rounded, color: Colors.white),
                    label:
                        Text('Overdue', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.redAccent,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannerGridCard extends StatelessWidget {
  const _PlannerGridCard({
    required this.item,
    required this.tokens,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.showActions = true,
  });

  final PlannerItem item;
  final PlannerTokens tokens;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat.MMMd().add_jm();
    final priorityColor = _priorityColor(item.priority, context);
    final overdue = item.isOverdue;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: tokens.surfaceRadius,
      onTap: onTap,
      child: Card(
        color: isSelected ? scheme.secondaryContainer : tokens.surface,
        child: Padding(
          padding: EdgeInsets.all(tokens.gutter - 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                        overdue
                            ? Icons.warning_amber_rounded
                            : Icons.push_pin_outlined,
                        color: priorityColor),
                  ),
                  if (showActions)
                    PopupMenuButton<String>(
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
                        PopupMenuItem<String>(
                            value: 'edit', child: Text('Edit')),
                        PopupMenuItem<String>(
                            value: 'delete', child: Text('Delete')),
                      ],
                    )
                  else
                    const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 8),
              Text(item.title, style: tokens.emphasis),
              const SizedBox(height: 4),
              Text(
                  item.description.isEmpty
                      ? 'No description yet'
                      : item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Wrap(
                spacing: tokens.gutter / 2,
                runSpacing: tokens.gutter / 3,
                children: [
                  Chip(
                    label: Text('Due ${formatter.format(item.dueDate)}'),
                    avatar: const Icon(Icons.calendar_month_outlined),
                  ),
                  Chip(
                    label: Text('Priority: ${item.priority.name}'),
                    backgroundColor: priorityColor.withOpacity(0.15),
                    labelStyle: TextStyle(color: priorityColor),
                  ),
                  Chip(
                    label: Text(item.status.name),
                    backgroundColor: scheme.secondaryContainer,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlannerListTile extends StatelessWidget {
  const _PlannerListTile({
    required this.item,
    required this.tokens,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final PlannerItem item;
  final PlannerTokens tokens;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat.yMMMd().add_jm();
    final priorityColor = _priorityColor(item.priority, context);
    final overdue = item.isOverdue;

    return Card(
      color: selected
          ? Theme.of(context).colorScheme.secondaryContainer
          : tokens.surface,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: priorityColor.withOpacity(0.15),
          child: Icon(
            overdue ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: overdue ? Colors.redAccent : priorityColor,
          ),
        ),
        title: Text(item.title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: overdue ? Colors.red : null)),
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
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.35),
                ),
                if (overdue)
                  const Chip(
                    label:
                        Text('Overdue', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.redAccent,
                  ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        onTap: onTap,
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
}

class _FilterSummary extends StatelessWidget {
  const _FilterSummary({required this.controller});

  final PlannerController controller;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (controller.priorityFilter != null) {
      chips.add(
          _buildChip(context, 'Priority: ${controller.priorityFilter!.name}'));
    }
    if (controller.statusFilter != null) {
      chips
          .add(_buildChip(context, 'Status: ${controller.statusFilter!.name}'));
    }
    if (controller.overdueOnly) {
      chips.add(_buildChip(context, 'Overdue only'));
    }
    chips.add(_buildChip(
        context, 'Sorted by ${_labelForSort(controller.sortOption)}'));

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

  Widget _buildChip(BuildContext context, String label) {
    final tokens = Theme.of(context).extension<PlannerTokens>() ??
        PlannerTokens.fromSeed(seedColor: PlannerTheme.defaultSeed);
    return Chip(
      avatar: const Icon(Icons.tune, size: 18),
      label: Text(label),
      backgroundColor: tokens.surface,
    );
  }
}

Color _priorityColor(Priority priority, BuildContext context) {
  switch (priority) {
    case Priority.high:
      return Colors.redAccent;
    case Priority.medium:
      return Theme.of(context).colorScheme.primary;
    case Priority.low:
      return Colors.green;
  }
}
