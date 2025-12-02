import 'dart:convert';

/// Priority levels for a planner item.
enum Priority { low, medium, high }

/// Status values for a planner item.
enum Status { pending, inProgress, completed }

/// A task or event within the planner.
class PlannerItem {
  PlannerItem({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.priority = Priority.medium,
    this.status = Status.pending,
  }) {
    if (title.trim().isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }
  }

  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final Priority priority;
  final Status status;

  PlannerItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    Priority? priority,
    Status? status,
  }) {
    return PlannerItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'priority': priority.name,
        'status': status.name,
      };

  String toJsonString({bool pretty = false}) =>
      pretty ? const JsonEncoder.withIndent('  ').convert(toJson()) : jsonEncode(toJson());

  static PlannerItem fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('id') || json['id'] == null) {
      throw const FormatException('Planner item missing id');
    }

    return PlannerItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dueDate: DateTime.parse(json['dueDate'] as String),
      priority: Priority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => Priority.medium,
      ),
      status: Status.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => Status.pending,
      ),
    );
  }

  bool get isOverdue => status != Status.completed && dueDate.isBefore(DateTime.now());

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlannerItem &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.dueDate == dueDate &&
        other.priority == priority &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(id, title, description, dueDate, priority, status);

  @override
  String toString() {
    return 'PlannerItem(id: $id, title: $title, dueDate: $dueDate, priority: ${priority.name}, status: ${status.name})';
  }
}
