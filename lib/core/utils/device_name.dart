import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Human-readable device/session label sent as `device_name` on login
/// (Laravel Sanctum uses it to name/list issued tokens) — not a unique
/// device id, just something recognizable, e.g. "Encuestas Chiapas -
/// Android". Built from [defaultTargetPlatform]/[kIsWeb] rather than
/// `dart:io`'s `Platform`, which isn't available on web.
final deviceNameProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  final platformLabel = kIsWeb
      ? 'Web'
      : switch (defaultTargetPlatform) {
          TargetPlatform.android => 'Android',
          TargetPlatform.iOS => 'iOS',
          TargetPlatform.windows => 'Windows',
          TargetPlatform.macOS => 'macOS',
          TargetPlatform.linux => 'Linux',
          TargetPlatform.fuchsia => 'Fuchsia',
        };
  return '${info.appName} - $platformLabel';
});
