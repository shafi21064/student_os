import 'package:flutter/foundation.dart';

enum AuthProviderType { email, google, apple, facebook }

@immutable
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.mobile,
    required this.password,
    required this.university,
    required this.verified,
    required this.provider,
    this.email = '',
    this.authToken = '',
    this.avatarUrl = '',
  });

  factory AuthUser.fromJson(Map<String, Object?> json) => AuthUser(
    id: json['id'] as String? ?? 'local-user',
    name: json['name'] as String? ?? 'Student',
    mobile: json['mobile'] as String? ?? '',
    password: json['password'] as String? ?? '',
    university: json['university'] as String? ?? '',
    email: json['email'] as String? ?? '',
    authToken: json['authToken'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String? ?? '',
    verified: json['verified'] as bool? ?? false,
    provider: AuthProviderType.values.firstWhere(
      (value) => value.name == json['provider'],
      orElse: () => AuthProviderType.email,
    ),
  );

  final String id;
  final String name;
  final String mobile;

  /// Local-demo credential only. Replace this entire local repository with a
  /// server-backed authentication implementation before production release.
  final String password;
  final String university;
  final String email;
  final String authToken;
  final String avatarUrl;
  final bool verified;
  final AuthProviderType provider;

  String get firstName {
    final value = name.trim();
    if (value.isEmpty) return 'Student';
    return value.split(RegExp(r'\s+')).first;
  }

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  AuthUser copyWith({
    String? name,
    String? mobile,
    String? password,
    String? university,
    String? email,
    String? authToken,
    String? avatarUrl,
    bool? verified,
  }) => AuthUser(
    id: id,
    name: name ?? this.name,
    mobile: mobile ?? this.mobile,
    password: password ?? this.password,
    university: university ?? this.university,
    email: email ?? this.email,
    authToken: authToken ?? this.authToken,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    verified: verified ?? this.verified,
    provider: provider,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'mobile': mobile,
    'password': password,
    'university': university,
    'email': email,
    'authToken': authToken,
    'avatarUrl': avatarUrl,
    'verified': verified,
    'provider': provider.name,
  };
}

@immutable
class PendingSignUp {
  const PendingSignUp({
    required this.name,
    required this.mobile,
    required this.phone,
  });

  final String name;
  final String mobile;
  final String phone;
}

@immutable
class PendingOtp {
  const PendingOtp({required this.phone, required this.mobile});

  final String phone;
  final String mobile;
}
