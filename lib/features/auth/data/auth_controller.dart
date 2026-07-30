import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:studentos/features/auth/data/auth_repository.dart';
import 'package:studentos/features/auth/domain/auth_user.dart';

const _unset = Object();

@immutable
class AuthState {
  const AuthState({
    required this.user,
    required this.registeredUsers,
    this.pendingSignUp,
    this.message = '',
    this.error = '',
  });

  final AuthUser? user;
  final List<AuthUser> registeredUsers;
  final PendingSignUp? pendingSignUp;
  final String message;
  final String error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    Object? user = _unset,
    List<AuthUser>? registeredUsers,
    Object? pendingSignUp = _unset,
    String? message,
    String? error,
  }) => AuthState(
    user: identical(user, _unset) ? this.user : user as AuthUser?,
    registeredUsers: registeredUsers ?? this.registeredUsers,
    pendingSignUp: identical(pendingSignUp, _unset)
        ? this.pendingSignUp
        : pendingSignUp as PendingSignUp?,
    message: message ?? this.message,
    error: error ?? this.error,
  );
}

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    final snapshot = _repository.load();
    return AuthState(user: snapshot.user, registeredUsers: snapshot.users);
  }

  void clearFeedback() {
    if (state.message.isEmpty && state.error.isEmpty) return;
    state = state.copyWith(message: '', error: '');
  }

  void signIn({
    required String countryCode,
    required String mobile,
    required String password,
  }) {
    final normalizedMobile = _normalizeMobile('$countryCode$mobile');
    if (normalizedMobile.isEmpty || password.isEmpty) {
      state = state.copyWith(
        error: 'Enter your mobile number and password.',
        message: '',
      );
      return;
    }

    final account = _findUser(
      (entry) => entry.mobile == normalizedMobile && entry.password == password,
    );

    // The supplied React prototype signs unknown credentials into a local demo
    // account. This preserves that behavior without claiming server auth.
    final activeAccount =
        account ??
        AuthUser(
          id: 'demo-$normalizedMobile',
          name: 'Demo User',
          mobile: normalizedMobile,
          password: password,
          university: '',
          verified: true,
          provider: AuthProviderType.email,
        );

    final users = account == null
        ? <AuthUser>[
            ...state.registeredUsers.where(
              (item) => item.mobile != normalizedMobile,
            ),
            activeAccount,
          ]
        : state.registeredUsers;

    state = state.copyWith(
      user: activeAccount,
      registeredUsers: users,
      pendingSignUp: null,
      message: 'Welcome back, ${activeAccount.firstName}!',
      error: '',
    );
    _repository.saveUsers(users);
    _repository.saveUser(activeAccount);
  }

  void startSignUp({
    required String name,
    required String countryCode,
    required String mobile,
    required String password,
    required String confirmPassword,
    required String university,
  }) {
    final normalizedName = name.trim();
    final normalizedMobile = _normalizeMobile('$countryCode$mobile');
    if (normalizedName.isEmpty ||
        normalizedMobile.isEmpty ||
        password.isEmpty) {
      state = state.copyWith(
        error: 'Name, mobile number, and password are required.',
        message: '',
      );
      return;
    }
    if (password != confirmPassword) {
      state = state.copyWith(error: 'Passwords do not match.', message: '');
      return;
    }
    if (password.length < 6) {
      state = state.copyWith(
        error: 'Use at least 6 characters for the password.',
        message: '',
      );
      return;
    }

    final code = (100000 + Random().nextInt(900000)).toString();
    state = state.copyWith(
      pendingSignUp: PendingSignUp(
        name: normalizedName,
        mobile: normalizedMobile,
        password: password,
        university: university.trim(),
        verificationCode: code,
      ),
      message:
          'Verification is ready for $normalizedMobile. Enter any 6-digit code in this demo.',
      error: '',
    );
  }

  void verify(String code) {
    final pending = state.pendingSignUp;
    if (pending == null) return;
    if (!RegExp(r'^\d{6}$').hasMatch(code.trim())) {
      state = state.copyWith(
        error: 'Enter a 6-digit verification code.',
        message: '',
      );
      return;
    }

    final user = AuthUser(
      id: 'user-${pending.mobile}',
      name: pending.name,
      mobile: pending.mobile,
      password: pending.password,
      university: pending.university,
      verified: true,
      provider: AuthProviderType.email,
    );
    final users = <AuthUser>[
      ...state.registeredUsers.where((item) => item.mobile != pending.mobile),
      user,
    ];
    state = state.copyWith(
      user: user,
      registeredUsers: users,
      pendingSignUp: null,
      message: 'Welcome aboard, ${user.firstName}!',
      error: '',
    );
    _repository.saveUsers(users);
    _repository.saveUser(user);
  }

  Future<void> onPressedGoogleLogin() async {
    try {
      state = state.copyWith(message: '', error: '');

      final googleAccount = await GoogleSignIn.instance.authenticate();
      final googleAuthentication = googleAccount.authentication;

      final idToken = googleAuthentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        state = state.copyWith(
          error: 'Google authentication token পাওয়া যায়নি।',
        );
        return;
      }

      // আপনার complete AuthRepository method
      final response = await _repository.getSocialLoginResponse(
        provider: 'google',
        accessToken: idToken,
      );

      if (response.isSuccess != true) {
        state = state.copyWith(
          error: response.message?.toString() ?? 'Google login failed.',
          message: '',
        );
        return;
      }

      final userJson = _socialUserJson(response.data);

      final user = AuthUser(
        id:
            userJson['id']?.toString() ??
            userJson['user_id']?.toString() ??
            googleAccount.id,
        name:
            userJson['name']?.toString() ??
            googleAccount.displayName ??
            'Student',
        mobile:
            userJson['mobile']?.toString() ??
            userJson['phone']?.toString() ??
            '',
        password: '',
        university: userJson['university']?.toString() ?? '',
        email: userJson['email']?.toString() ?? googleAccount.email,
        verified: userJson['verified'] == true,
        provider: AuthProviderType.google,
      );

      final users = <AuthUser>[
        ...state.registeredUsers.where(
          (existingUser) => existingUser.id != user.id,
        ),
        user,
      ];

      _repository.saveUsers(users);
      _repository.saveUser(user);

      state = state.copyWith(
        user: user,
        registeredUsers: users,
        pendingSignUp: null,
        message: response.message?.toString() ?? 'Welcome, ${user.firstName}!',
        error: '',
      );
    } on GoogleSignInException catch (error) {
      state = state.copyWith(
        message: '',
        error: error.code == GoogleSignInExceptionCode.canceled
            ? 'Google login cancelled.'
            : 'Google login failed.',
      );
    } catch (error, stackTrace) {
      debugPrint('Google login error: $error');
      debugPrintStack(stackTrace: stackTrace);

      state = state.copyWith(
        message: '',
        error: 'Google login failed. Please try again.',
      );
    }
  }

  void continueWithGoogle() {
    final existing = _findUser(
      (entry) => entry.provider == AuthProviderType.google,
    );
    const fallback = AuthUser(
      id: 'google-account',
      name: 'Google User',
      mobile: '8801711111111',
      password: 'google-demo',
      university: 'BRAC University',
      email: 'google.user@example.com',
      verified: true,
      provider: AuthProviderType.google,
    );
    final active = existing ?? fallback;
    final users = existing == null
        ? <AuthUser>[...state.registeredUsers, active]
        : state.registeredUsers;
    state = state.copyWith(
      user: active,
      registeredUsers: users,
      pendingSignUp: null,
      message: 'Welcome, ${active.name}!',
      error: '',
    );
    _repository.saveUsers(users);
    _repository.saveUser(active);
  }

  void updateProfile({
    required String name,
    required String mobile,
    required String email,
    required String university,
  }) {
    final current = state.user;
    if (current == null) return;
    final updated = current.copyWith(
      name: name.trim().isEmpty ? current.name : name.trim(),
      mobile: _normalizeMobile(mobile).isEmpty
          ? current.mobile
          : _normalizeMobile(mobile),
      email: email.trim(),
      university: university.trim(),
    );
    final users = state.registeredUsers
        .map((item) => item.id == current.id ? updated : item)
        .toList(growable: false);
    state = state.copyWith(
      user: updated,
      registeredUsers: users,
      message: 'Profile updated.',
      error: '',
    );
    _repository.saveUsers(users);
    _repository.saveUser(updated);
  }

  void setStudentVerified(bool verified) {
    final current = state.user;
    if (current == null || current.verified == verified) return;
    final updated = current.copyWith(verified: verified);
    final users = state.registeredUsers
        .map((item) => item.id == current.id ? updated : item)
        .toList(growable: false);
    state = state.copyWith(user: updated, registeredUsers: users);
    _repository.saveUsers(users);
    _repository.saveUser(updated);
  }

  void logout() {
    final current = state.user;
    if (Firebase.apps.isNotEmpty) {
      unawaited(FirebaseAuth.instance.signOut());
    }
    if (current?.provider == AuthProviderType.google) {
      unawaited(GoogleSignIn.instance.signOut());
    }
    _repository.saveUser(null);
    state = state.copyWith(
      user: null,
      pendingSignUp: null,
      message: '',
      error: '',
    );
  }

  AuthUser? _findUser(bool Function(AuthUser user) test) {
    for (final user in state.registeredUsers) {
      if (test(user)) return user;
    }
    return null;
  }

  String _normalizeMobile(String value) => value.replaceAll(RegExp(r'\D'), '');

  Map<String, Object?> _socialUserJson(Object? body) {
    if (body is! Map) return const <String, Object?>{};
    final root = body.map((key, value) => MapEntry(key.toString(), value));
    final data = root['data'];
    if (data is Map) {
      final mappedData = data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final user = mappedData['user'];
      if (user is Map) {
        return user.map((key, value) => MapEntry(key.toString(), value));
      }
      return mappedData;
    }
    final user = root['user'];
    if (user is Map) {
      return user.map((key, value) => MapEntry(key.toString(), value));
    }
    return root;
  }
}
