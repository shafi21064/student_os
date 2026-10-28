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
  Future<ApiResponse<void>> sendSignInOtp({required String phone});
  Future<ApiResponse<AuthUser>> verifySignInOtp({
    required String phone,
    required String otp,
  });
  Future<ApiResponse<void>> sendSignUpOtp({required String phone});
  Future<ApiResponse<AuthUser>> verifySignUpOtp({
    required String phone,
    required String name,
    required String otp,
    required String password,
  });
  Future<ApiResponse<void>> changePassword({
    String? oldPassword,
    required String password,
    required String confirmPassword,
  });
  Future<ApiResponse<void>> sendPasswordResetOtp({required String phone});
  Future<ApiResponse<void>> verifyPasswordResetOtp({
    required String phone,
    required String otp,
  });
  Future<ApiResponse<void>> resetPassword({
    required String phone,
    required String password,
    required String confirmPassword,
  });
  Future<ApiResponse<AuthUser>> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? avatarPath,
    required AuthUser currentUser,
  });
  Future<ApiResponse<AuthUser>> socialLogin({
    required String name,
    required String email,
    required String provider,
    required String socialProvider,
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
  static const _isLoggedInKey = 'isLoggedIn';

  @override
  AuthSnapshot load() {
    final users = _decodeUsers(_preferences.getString(_usersKey));
    final user = _decodeUser(_preferences.getString(_sessionKey));
    final sessionUser = user?.authToken.isNotEmpty == true ? user : null;
    if (sessionUser != null) {
      ApiClient.instance.setAuthToken(sessionUser.authToken);
    }
    return AuthSnapshot(user: sessionUser, users: users);
  }

  @override
  void saveUser(AuthUser? user) {
    if (user == null) {
      unawaited(_preferences.remove(_sessionKey));
      unawaited(_preferences.setBool(_isLoggedInKey, false));
      return;
    }
    unawaited(_preferences.setBool(_isLoggedInKey, true));
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

    final token = _tokenFromAuthData(data);
    if (token != null && token.isNotEmpty) {
      ApiClient.instance.setAuthToken(token);
    }

    return ApiResponse<AuthUser>.success(
      statusCode: response.statusCode,
      data: _authUserFromAuthData(data, password, authToken: token ?? ''),
      message: body['message']?.toString(),
    );
  }

  @override
  Future<ApiResponse<void>> sendSignInOtp({required String phone}) =>
      _postResultOnly(Api.sendSignInOtp, {'phone': phone}, 'OTP send failed.');

  @override
  Future<ApiResponse<AuthUser>> verifySignInOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      Api.verifySignInOtp,
      data: FormData.fromMap({'phone': phone, 'otp': otp}),
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
            : 'OTP verification failed.',
      );
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return ApiResponse<AuthUser>.failure(
        statusCode: response.statusCode,
        message: body['message']?.toString() ?? 'OTP verification failed.',
      );
    }

    final token = _tokenFromAuthData(data);
    if (token != null && token.isNotEmpty) {
      ApiClient.instance.setAuthToken(token);
    }

    return ApiResponse<AuthUser>.success(
      statusCode: response.statusCode,
      data: _authUserFromAuthData(data, '', authToken: token ?? ''),
      message: body['message']?.toString(),
    );
  }

  @override
  Future<ApiResponse<void>> sendSignUpOtp({required String phone}) async {
    return _postResultOnly(Api.sendSignUpOtp, {
      'phone': phone,
    }, 'OTP send failed.');
  }

  @override
  Future<ApiResponse<AuthUser>> verifySignUpOtp({
    required String name,
    required String phone,
    required String otp,
    required String password,
  }) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      Api.verifySignUpOtp,
      data: FormData.fromMap({'name': name, 'phone': phone, 'otp': otp}),
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
            : 'OTP verification failed.',
      );
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return ApiResponse<AuthUser>.failure(
        statusCode: response.statusCode,
        message: body['message']?.toString() ?? 'OTP verification failed.',
      );
    }

    final token = _tokenFromAuthData(data);
    if (token != null && token.isNotEmpty) {
      ApiClient.instance.setAuthToken(token);
    }

    return ApiResponse<AuthUser>.success(
      statusCode: response.statusCode,
      data: _authUserFromAuthData(data, password, authToken: token ?? ''),
      message: body['message']?.toString(),
    );
  }

  @override
  Future<ApiResponse<void>> changePassword({
    String? oldPassword,
    required String password,
    required String confirmPassword,
  }) async {
    final fields = <String, Object?>{
      'password': password,
      'confirm_password': confirmPassword,
    };
    if (oldPassword != null && oldPassword.isNotEmpty) {
      fields['old_password'] = oldPassword;
    }

    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      Api.changePassword,
      data: FormData.fromMap(fields),
      options: Options(headers: {'accept': '*/*'}),
    );

    if (!response.isSuccess) {
      return ApiResponse<void>.failure(
        statusCode: response.statusCode,
        message: response.message,
        error: response.error,
      );
    }

    final body = response.data;
    if (body is Map<String, dynamic> && body['result'] == true) {
      return ApiResponse<void>.success(
        statusCode: response.statusCode,
        message: body['message']?.toString(),
      );
    }

    return ApiResponse<void>.failure(
      statusCode: response.statusCode,
      message: body is Map<String, dynamic>
          ? body['message']?.toString()
          : 'Password setup failed.',
    );
  }

  @override
  Future<ApiResponse<void>> sendPasswordResetOtp({required String phone}) =>
      _postResultOnly(Api.forgetPasswordPhone, {
        'phone': phone,
      }, 'Password reset OTP send failed.');

  @override
  Future<ApiResponse<void>> verifyPasswordResetOtp({
    required String phone,
    required String otp,
  }) => _postResultOnly(Api.verifyOTPWithEmail, {
    'phone': phone,
    'otp': otp,
  }, 'OTP verification failed.');

  @override
  Future<ApiResponse<void>> resetPassword({
    required String phone,
    required String password,
    required String confirmPassword,
  }) => _postResultOnly(Api.resetPasswordWithEmail, {
    'phone': phone,
    'password': password,
    'confirm_password': confirmPassword,
  }, 'Password reset failed.');

  @override
  Future<ApiResponse<AuthUser>> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? avatarPath,
    required AuthUser currentUser,
  }) async {
    final fields = <String, Object?>{'name': name, 'phone': phone};
    if (email.trim().isNotEmpty) fields['email'] = email.trim();
    if (avatarPath != null && avatarPath.isNotEmpty) {
      fields['avatar'] = await MultipartFile.fromFile(avatarPath);
    }

    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      Api.profileUpdate,
      data: FormData.fromMap(fields),
      options: Options(headers: {'accept': 'application/json'}),
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
            : 'Profile update failed.',
      );
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return ApiResponse<AuthUser>.failure(
        statusCode: response.statusCode,
        message: body['message']?.toString() ?? 'Profile update failed.',
      );
    }

    return ApiResponse<AuthUser>.success(
      statusCode: response.statusCode,
      data: _authUserFromAuthData(
        data,
        currentUser.password,
        authToken: currentUser.authToken,
        provider: currentUser.provider,
        fallbackName: currentUser.name,
        fallbackEmail: currentUser.email,
        fallbackId: currentUser.id,
      ).copyWith(university: currentUser.university),
      message: body['message']?.toString(),
    );
  }

  Future<ApiResponse<void>> _postResultOnly(
    String url,
    Map<String, Object?> fields,
    String fallbackMessage,
  ) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      url,
      data: FormData.fromMap(fields),
      options: Options(headers: {'accept': '*/*'}),
    );

    if (!response.isSuccess) {
      return ApiResponse<void>.failure(
        statusCode: response.statusCode,
        message: response.message,
        error: response.error,
      );
    }

    final body = response.data;
    if (body is Map<String, dynamic> && body['result'] == true) {
      return ApiResponse<void>.success(
        statusCode: response.statusCode,
        message: body['message']?.toString(),
      );
    }

    return ApiResponse<void>.failure(
      statusCode: response.statusCode,
      message: body is Map<String, dynamic>
          ? body['message']?.toString()
          : fallbackMessage,
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
    String authToken = '',
    AuthProviderType provider = AuthProviderType.email,
    String fallbackName = 'Student',
    String fallbackEmail = '',
    String fallbackId = '',
  }) {
    final userJson = data['user'];
    final user = userJson is Map<String, dynamic> ? userJson : data;
    final id =
        user['id']?.toString() ?? data['user_id']?.toString() ?? fallbackId;
    final name = _firstNonBlank(
      user['name'],
      user['full_name'],
      user['first_name'],
      fallbackName,
    );

    return AuthUser(
      id: id.isEmpty ? 'user-${user['email'] ?? data['user_id']}' : id,
      name: name,
      mobile: user['phone']?.toString() ?? '',
      password: password,
      university: institute,
      email: user['email']?.toString() ?? fallbackEmail,
      authToken: authToken,
      avatarUrl: _firstNonBlank(
        user['avatar'],
        user['avatar_url'],
        user['profile_photo_url'],
        '',
      ),
      verified: user['is_active'] == 1 || user['email_verified_at'] != null,
      provider: provider,
      hasPassword: _asBool(user['has_password']),
    );
  }

  bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == '1' || text == 'true' || text == 'yes';
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

  String? _tokenFromAuthData(Map<String, dynamic> data) {
    final token = _firstNonBlank(
      data['access_token'],
      data['token'],
      data['plain_text_token'],
      '',
    );
    return token.isEmpty ? null : token.replaceFirst(RegExp(r'^Bearer\s+'), '');
  }

  @override
  Future<ApiResponse<AuthUser>> socialLogin({
    required String name,
    required String email,
    required String provider,
    required String socialProvider,
    required String accessToken,
  }) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      Api.socialLogin,
      data: <String, String>{
        'provider': socialProvider,
        'id_token': accessToken,
      },
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
            : 'Social login failed.',
      );
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return ApiResponse<AuthUser>.failure(
        statusCode: response.statusCode,
        message: body['message']?.toString() ?? 'Social login failed.',
      );
    }

    final token = _tokenFromAuthData(data);
    if (token != null && token.isNotEmpty) {
      ApiClient.instance.setAuthToken(token);
    }

    final authProvider = AuthProviderType.values.firstWhere(
      (value) => value.name == socialProvider,
      orElse: () => AuthProviderType.email,
    );

    return ApiResponse<AuthUser>.success(
      statusCode: response.statusCode,
      data: _authUserFromAuthData(
        data,
        '',
        authToken: token ?? '',
        provider: authProvider,
        fallbackName: name.trim().isEmpty ? 'Student' : name,
        fallbackEmail: email,
        fallbackId: provider,
      ),
      message: body['message']?.toString(),
    );
  }
}
