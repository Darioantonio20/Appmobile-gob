import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/user.dart';

/// Wraps encrypted on-device storage for the session (token + user).
///
/// Deliberately has zero dependency on Dio/networking: `core/providers.dart`
/// wires this into DioClient's token callback, and if this datasource
/// pulled in Dio too we'd have a provider cycle (Dio needs a token
/// provider; the token provider would need Dio).
class AuthLocalDataSource {
  AuthLocalDataSource(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> saveSession({required String token, required User user}) async {
    await _storage.write(key: AppConstants.secureKeyAuthToken, value: token);
    await _storage.write(key: AppConstants.secureKeyUserJson, value: jsonEncode(user.toJson()));
  }

  Future<String?> readToken() => _storage.read(key: AppConstants.secureKeyAuthToken);

  Future<User?> readUser() async {
    final raw = await _storage.read(key: AppConstants.secureKeyUserJson);
    if (raw == null) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: AppConstants.secureKeyAuthToken);
    await _storage.delete(key: AppConstants.secureKeyUserJson);
  }
}

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource(const FlutterSecureStorage());
});
