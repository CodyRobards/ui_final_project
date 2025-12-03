import 'package:planner_cli/cli/app.dart';
import 'package:planner_cli/services/planner_repository.dart';
import 'package:planner_cli/services/storage_path.dart';

Future<void> main(List<String> arguments) async {
  final dataFile = await resolvePlannerStorageFile();
  final repository = PlannerRepository(storageFile: dataFile);
  final app = PlannerApp(repository: repository);
  await app.run();
}
