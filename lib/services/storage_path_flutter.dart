import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'storage_path_shared.dart';

Future<File> resolveStorageFile() async {
  if (kIsWeb) {
    throw UnsupportedError(
      'The Flutter client uses local file storage and is not supported on web.',
    );
  }

  final envPath = Platform.environment[plannerStorageDirEnv];
  if (envPath != null && envPath.trim().isNotEmpty) {
    final directory = Directory(envPath);
    await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}$plannerStorageFileName');
  }

  Directory baseDirectory;
  if (Platform.isAndroid || Platform.isIOS) {
    baseDirectory = await getApplicationDocumentsDirectory();
  } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    // Align with the CLI default for desktop targets to ensure both clients use
    // the same local path when no environment override is provided.
    baseDirectory = Directory('data');
  } else {
    baseDirectory = Directory('data');
  }

  await baseDirectory.create(recursive: true);
  return File('${baseDirectory.path}${Platform.pathSeparator}$plannerStorageFileName');
}
