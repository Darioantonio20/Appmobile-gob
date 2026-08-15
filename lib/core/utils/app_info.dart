import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// App version string (e.g. `1.0.0+3`), read once per app run and attached
/// to submitted responses — lets support trace an issue back to exactly
/// which build a surveyor was running.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}+${info.buildNumber}';
});
