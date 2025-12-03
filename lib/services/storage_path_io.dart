import 'dart:io';

import 'storage_path_shared.dart';

Future<File> resolveStorageFile() async {
  final baseDirectory = _resolveBaseDirectory();
  await baseDirectory.create(recursive: true);
  return File('${baseDirectory.path}${Platform.pathSeparator}$plannerStorageFileName');
}

Directory _resolveBaseDirectory() {
  final envPath = Platform.environment[plannerStorageDirEnv];
  if (envPath != null && envPath.trim().isNotEmpty) {
    return Directory(envPath);
  }

  // CLI environments primarily target desktop/server OSes; default to a local
  // data directory for a predictable shared path with the Flutter desktop
  // client.
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    return Directory('data');
  }

  // Fallback for any other platform (including Android/iOS when run as a Dart
  // app).
  return Directory('data');
}
