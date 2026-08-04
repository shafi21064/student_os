import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
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
  Future<ApiResponse<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  });
  Future<ApiResponse<AuthUser>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String institute,
  });
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

  @override
  Future<ApiResponse<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      Api.loginWithEmail,
      data: FormData.fromMap({'email': email, 'password': password}),
      options: Options(headers: {'accept': '*/*'}),
    );

    if (!response.isSuccess) {
      return ApiResponse<AuthUser>.failure(
        statusCode: response.statusCode,
        message: response.message,
        error: response.error,
      );
    }

    final body = response.data;
    if (body is! Map<String, dynamic> || body['result'] != true) {
      return ApiResponse<AuthUser>.failure(
        statusCode: response.statusCode,
        message: body is Map<String, dynamic>
            ? body['message']?.toString()
            : 'Login failed.',
      );
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return ApiResponse<AuthUser>.failure(
        statusCode: response.statusCode,
        message: body['message']?.toString() ?? 'Login failed.',
      );
    }

    final token = data['access_token']?.toString();
    if (token != null && token.isNotEmpty) {
      ApiClient.instance.setAuthToken(token);
    }

    return ApiResponse<AuthUser>.success(
      statusCode: response.statusCode,
      data: _authUserFromAuthData(data, password),
      message: body['message']?.toString(),
    );
  }

  @override
  Future<ApiResponse<AuthUser>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String institute,
  }) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      Api.signupWithEmail,
      data: FormData.fromMap({
        'name': name,
        'email': email,
        'password': password,
        'institute': institute,
      }),
      options: Options(headers: {'accept': '*/*'}),
    );

    if (!response.isSuccess) {
      return ApiResponse<AuthUser>.failure(
        statusCode: response.statusCode,
        message: response.message,
        error: response.error,
      );
    }

    final body = response.data;
    if (body is! Map<String, dynamic> || body['result'] != true) {
      return ApiResponse<AuthUser>.failure(
        statusCode: response.statusCode,
        message: body is Map<String, dynamic>
            ? body['message']?.toString()
            : 'Registration failed.',
      );
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return ApiResponse<AuthUser>.failure(
        statusCode: response.statusCode,
        message: body['message']?.toString() ?? 'Registration failed.',
      );
    }

    final token = data['access_token']?.toString();
    if (token != null && token.isNotEmpty) {
      ApiClient.instance.setAuthToken(token);
    }

    return ApiResponse<AuthUser>.success(
      statusCode: response.statusCode,
      data: _authUserFromAuthData(data, password, institute: institute),
      message: body['message']?.toString(),
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

  AuthUser _authUserFromAuthData(
    Map<String, dynamic> data,
    String password, {
    String institute = '',
  }) {
    final userJson = data['user'];
    final user = userJson is Map<String, dynamic>
        ? userJson
        : const <String, dynamic>{};
    final id = user['id']?.toString() ?? data['user_id']?.toString() ?? '';
    final name = _firstNonBlank(
      user['name'],
      user['full_name'],
      user['first_name'],
      'Student',
    );

    return AuthUser(
      id: id.isEmpty ? 'user-${user['email'] ?? data['user_id']}' : id,
      name: name,
      mobile: user['phone']?.toString() ?? '',
      password: password,
      university: institute,
      email: user['email']?.toString() ?? '',
      verified: user['is_active'] == 1 || user['email_verified_at'] != null,
      provider: AuthProviderType.email,
    );
  }

  String _firstNonBlank(
    Object? first,
    Object? second,
    Object? third,
    String fallback,
  ) {
    for (final value in <Object?>[first, second, third]) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
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
