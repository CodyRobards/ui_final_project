import '../models/planner_item.dart';

class InputValidators {
  static String? validateTitle(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Title is required.';
    }
    return null;
  }

  static DateTime? parseDueDate(String? input) {
    if (input == null || input.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(input.trim());
  }

  static Priority? parsePriority(String? input) {
    switch (input?.trim().toLowerCase()) {
      case '1':
      case 'low':
        return Priority.low;
      case '2':
      case 'medium':
        return Priority.medium;
      case '3':
      case 'high':
        return Priority.high;
      default:
        return null;
    }
  }

  static Status? parseStatus(String? input) {
    switch (input?.trim().toLowerCase()) {
      case '1':
      case 'pending':
        return Status.pending;
      case '2':
      case 'inprogress':
      case 'in progress':
        return Status.inProgress;
      case '3':
      case 'completed':
        return Status.completed;
      default:
        return null;
    }
  }
}
