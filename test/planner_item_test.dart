import 'package:planner_cli/models/planner_item.dart';
import 'package:test/test.dart';

void main() {
  group('PlannerItem', () {
    test('serializes and deserializes correctly', () {
      final item = PlannerItem(
        id: '1',
        title: 'Test',
        description: 'Desc',
        dueDate: DateTime.parse('2024-12-01T12:00:00Z'),
        priority: Priority.high,
        status: Status.inProgress,
      );

      final json = item.toJson();
      final restored = PlannerItem.fromJson(json);

      expect(restored, equals(item));
      expect(restored.toJsonString(), isNotEmpty);
    });

    test('throws for missing id', () {
      expect(
        () => PlannerItem.fromJson({}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
