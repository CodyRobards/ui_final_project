import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../cli/input_validators.dart';
import '../models/planner_item.dart';
import 'planner_controller.dart';

class PlannerFormArguments {
  const PlannerFormArguments({this.existing});

  final PlannerItem? existing;
}

class PlannerFormPage extends StatefulWidget {
  const PlannerFormPage({super.key, required this.controller, this.existingItem});

  static const routeName = '/item-form';

  final PlannerController controller;
  final PlannerItem? existingItem;

  @override
  State<PlannerFormPage> createState() => _PlannerFormPageState();
}

class _PlannerFormPageState extends State<PlannerFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dueDateController;

  late Priority _priority;
  late Status _status;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingItem?.title ?? '');
    _descriptionController = TextEditingController(text: widget.existingItem?.description ?? '');
    final dueDate = widget.existingItem?.dueDate ?? DateTime.now();
    _dueDateController = TextEditingController(text: _formatDateInput(dueDate));
    _priority = widget.existingItem?.priority ?? Priority.medium;
    _status = widget.existingItem?.status ?? Status.pending;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit item' : 'New item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: InputValidators.validateTitle,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dueDateController,
                      decoration: const InputDecoration(
                        labelText: 'Due date *',
                        helperText: 'YYYY-MM-DD or ISO 8601',
                      ),
                      keyboardType: TextInputType.datetime,
                      validator: (value) {
                        final parsed = InputValidators.parseDueDate(value);
                        if (parsed == null) {
                          return 'Please enter a valid date.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Pick date',
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Priority>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: Priority.low, child: Text('Low')),
                  DropdownMenuItem(value: Priority.medium, child: Text('Medium')),
                  DropdownMenuItem(value: Priority.high, child: Text('High')),
                ],
                onChanged: (value) => setState(() => _priority = value ?? _priority),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Status>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: Status.pending, child: Text('Pending')),
                  DropdownMenuItem(value: Status.inProgress, child: Text('In progress')),
                  DropdownMenuItem(value: Status.completed, child: Text('Completed')),
                ],
                onChanged: (value) => setState(() => _status = value ?? _status),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Save changes' : 'Create item'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final initialDate = InputValidators.parseDueDate(_dueDateController.text) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? initialDate.hour,
      time?.minute ?? initialDate.minute,
    );
    setState(() {
      _dueDateController.text = _formatDateInput(combined);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final dueDate = InputValidators.parseDueDate(_dueDateController.text.trim())!;
    final description = _descriptionController.text.trim();
    final item = widget.existingItem?.copyWith(
          title: _titleController.text.trim(),
          description: description,
          dueDate: dueDate,
          priority: _priority,
          status: _status,
        ) ??
        PlannerItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          description: description,
          dueDate: dueDate,
          priority: _priority,
          status: _status,
        );

    if (widget.existingItem == null) {
      await widget.controller.addItem(item);
    } else {
      await widget.controller.updateItem(widget.existingItem!.id, item);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  String _formatDateInput(DateTime date) {
    final formatter = DateFormat('yyyy-MM-ddTHH:mm');
    return formatter.format(date);
  }
}
