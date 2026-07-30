import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studentos/core/api/api.dart';
import 'package:studentos/core/api/api_client.dart';
import 'package:studentos/core/storage/preferences_provider.dart';
import 'package:studentos/features/auth/domain/auth_user.dart';

class AuthSnapshot {
  const AuthSnapshot({required this.user, required this.users});

  final AuthUser? user;
  final List<AuthUser> users;
}

abstract interface class AuthRepository {
  AuthSnapshot load();
  void saveUser(AuthUser? user);
  void saveUsers(List<AuthUser> users);
  Future<ApiResponse<AuthUser>> getSocialLoginResponse({
    required String provider,
    required String accessToken,
  });
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SharedPreferencesAuthRepository(ref.watch(sharedPreferencesProvider));
});

class SharedPreferencesAuthRepository implements AuthRepository {
  SharedPreferencesAuthRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _sessionKey = 'studentos.auth.session';
  static const _usersKey = 'studentos.auth.users';

  static const demoAccount = AuthUser(
    id: 'demo-account',
    name: 'Demo Student',
    mobile: '8801700000000',
    password: 'studentos123',
    university: 'CUET',
    email: 'demo@studentos.app',
    verified: true,
    provider: AuthProviderType.email,
  );

  @override
  AuthSnapshot load() {
    final users = _decodeUsers(_preferences.getString(_usersKey));
    final resolvedUsers = users.isEmpty ? <AuthUser>[demoAccount] : users;
    final user = _decodeUser(_preferences.getString(_sessionKey));
    return AuthSnapshot(user: user, users: resolvedUsers);
  }

  @override
  void saveUser(AuthUser? user) {
    if (user == null) {
      unawaited(_preferences.remove(_sessionKey));
      return;
    }
    unawaited(_preferences.setString(_sessionKey, jsonEncode(user.toJson())));
  }

  @override
  void saveUsers(List<AuthUser> users) {
    unawaited(
      _preferences.setString(
        _usersKey,
        jsonEncode(users.map((item) => item.toJson()).toList()),
      ),
    );
  }

  List<AuthUser> _decodeUsers(String? source) {
    if (source == null || source.isEmpty) return const <AuthUser>[];
    try {
      final decoded = jsonDecode(source);
      if (decoded is! List<Object?>) return const <AuthUser>[];
      return decoded
          .whereType<Map<Object?, Object?>>()
          .map(
            (item) => AuthUser.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const <AuthUser>[];
    }
  }

  AuthUser? _decodeUser(String? source) {
    if (source == null || source.isEmpty) return null;
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<Object?, Object?>) return null;
      return AuthUser.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ApiResponse<AuthUser>> getSocialLoginResponse({
    String? provider,
    String accessToken = "",
  }) async {
    return ApiClient.instance.post<AuthUser>(
      Api.socialLogin,
      data: {"provider": provider, "access_token": accessToken},
    );
  }
}
