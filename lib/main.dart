import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'services/planner_repository.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await _createRepository();
  runApp(PlannerFlutterApp(repository: repository));
}

Future<PlannerRepository> _createRepository() async {
  if (kIsWeb) {
    throw UnsupportedError('The Flutter client uses local file storage and is not supported on web.');
  }

  Directory baseDirectory;
  if (Platform.isAndroid || Platform.isIOS) {
    baseDirectory = await getApplicationDocumentsDirectory();
  } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    baseDirectory = await getApplicationSupportDirectory();
  } else {
    baseDirectory = Directory('data');
  }

  await baseDirectory.create(recursive: true);
  final storageFile = File('${baseDirectory.path}${Platform.pathSeparator}planner_data.json');
  return PlannerRepository(storageFile: storageFile);
}
