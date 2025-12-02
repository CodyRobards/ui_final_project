import 'package:planner_cli/cli/input_validators.dart';
import 'package:planner_cli/models/planner_item.dart';
import 'package:test/test.dart';

void main() {
  group('InputValidators', () {
    test('validates title', () {
      expect(InputValidators.validateTitle(''), isNotNull);
      expect(InputValidators.validateTitle('  '), isNotNull);
      expect(InputValidators.validateTitle('Title'), isNull);
    });

    test('parses dates safely', () {
      expect(InputValidators.parseDueDate('2024-01-01'), isA<DateTime>());
      expect(InputValidators.parseDueDate('invalid'), isNull);
    });

    test('parses priority and status values', () {
      expect(InputValidators.parsePriority('1'), Priority.low);
      expect(InputValidators.parsePriority('High'), Priority.high);
      expect(InputValidators.parsePriority('unknown'), isNull);

      expect(InputValidators.parseStatus('2'), Status.inProgress);
      expect(InputValidators.parseStatus('completed'), Status.completed);
      expect(InputValidators.parseStatus('bad'), isNull);
    });
  });
}
