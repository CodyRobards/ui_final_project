import 'dart:io';

import 'storage_path_io.dart'
    if (dart.library.ui) 'storage_path_flutter.dart';
import 'storage_path_shared.dart';

export 'storage_path_shared.dart';

/// Returns the file used to persist planner data. This helper keeps the CLI and
/// Flutter clients aligned on storage location while allowing an environment
/// override for flexibility.
Future<File> resolvePlannerStorageFile() => resolveStorageFile();
