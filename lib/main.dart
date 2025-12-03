import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'services/planner_repository.dart';
import 'services/storage_path.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await _createRepository();
  runApp(PlannerFlutterApp(repository: repository));
}

Future<PlannerRepository> _createRepository() async {
  if (kIsWeb) {
    throw UnsupportedError(
      'The Flutter client uses local file storage and is not supported on web.',
    );
  }

  final storageFile = await resolvePlannerStorageFile();
  return PlannerRepository(storageFile: storageFile);
}
