import 'dart:io';

import 'package:planner_cli/cli/app.dart';
import 'package:planner_cli/services/planner_repository.dart';

Future<void> main(List<String> arguments) async {
  final dataFile = File('data/planner_data.json');
  final repository = PlannerRepository(storageFile: dataFile);
  final app = PlannerApp(repository: repository);
  await app.run();
}
