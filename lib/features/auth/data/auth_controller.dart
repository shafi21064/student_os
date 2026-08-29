import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:studentos/core/api/api_client.dart';
import 'package:studentos/core/config/env_config.dart';
import 'package:studentos/features/auth/data/auth_repository.dart';
import 'package:studentos/features/auth/domain/auth_user.dart';

const _unset = Object();
const _googleChannel = MethodChannel('studentos/google');

@immutable
class AuthState {
  const AuthState({
    required this.user,
    required this.registeredUsers,
    this.pendingSignUp,
    this.pendingSignIn,
    this.pendingPasswordReset,
    this.passwordResetVerified = false,
    this.message = '',
    this.error = '',
    this.isLoading = false,
  });

  final AuthUser? user;
  final List<AuthUser> registeredUsers;
  final PendingSignUp? pendingSignUp;
  final PendingOtp? pendingSignIn;
  final PendingOtp? pendingPasswordReset;
  final bool passwordResetVerified;
  final String message;
  final String error;
  final bool isLoading;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    Object? user = _unset,
    List<AuthUser>? registeredUsers,
    Object? pendingSignUp = _unset,
    Object? pendingSignIn = _unset,
    Object? pendingPasswordReset = _unset,
    bool? passwordResetVerified,
    String? message,
    String? error,
    bool? isLoading,
  }) => AuthState(
    user: identical(user, _unset) ? this.user : user as AuthUser?,
    registeredUsers: registeredUsers ?? this.registeredUsers,
    pendingSignUp: identical(pendingSignUp, _unset)
        ? this.pendingSignUp
        : pendingSignUp as PendingSignUp?,
    pendingSignIn: identical(pendingSignIn, _unset)
        ? this.pendingSignIn
        : pendingSignIn as PendingOtp?,
    pendingPasswordReset: identical(pendingPasswordReset, _unset)
        ? this.pendingPasswordReset
        : pendingPasswordReset as PendingOtp?,
    passwordResetVerified: passwordResetVerified ?? this.passwordResetVerified,
    message: message ?? this.message,
    error: error ?? this.error,
    isLoading: isLoading ?? this.isLoading,
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

  Future<void> signIn({
    required String countryCode,
    required String mobile,
    required String password,
  }) async {
    final loginEmail = _loginEmailFromMobile(mobile);
    final normalizedMobile = _normalizeMobileWithCountry(countryCode, mobile);
    if (loginEmail.isEmpty || password.isEmpty) {
      state = state.copyWith(
        error: 'Enter your phone and password.',
        message: '',
      );
      return;
    }

    final account = _findUser(
      (entry) => entry.mobile == normalizedMobile && entry.password == password,
    );

    if (account?.authToken.isNotEmpty == true) {
      ApiClient.instance.setAuthToken(account!.authToken);
      state = state.copyWith(
        user: account,
        pendingSignUp: null,
        message: 'Welcome back, ${account.firstName}!',
        error: '',
      );
      _repository.saveUser(account);
      return;
    }

    final response = await _repository.signInWithEmail(
      email: loginEmail,
      password: password,
    );

    if (!response.isSuccess || response.data == null) {
      state = state.copyWith(
        message: '',
        error: response.message ?? 'Login failed. Please sign in again.',
      );
      return;
    }

    final activeAccount = response.data! as AuthUser;
    final users = <AuthUser>[
      ...state.registeredUsers.where((item) => item.id != activeAccount.id),
      activeAccount,
    ];

    _repository.saveUsers(users);
    _repository.saveUser(activeAccount);
    state = state.copyWith(
      user: activeAccount,
      registeredUsers: users,
      pendingSignUp: null,
      message: response.message ?? 'Welcome back, ${activeAccount.firstName}!',
      error: '',
    );
  }

  Future<void> sendSignInOtp({
    required String countryCode,
    required String mobile,
  }) async {
    final phone = _loginEmailFromMobile(mobile);
    final normalizedMobile = _normalizeMobileWithCountry(countryCode, mobile);
    if (phone.isEmpty) {
      state = state.copyWith(error: 'Phone number is required.', message: '');
      return;
    }

    state = state.copyWith(message: '', error: '', isLoading: true);
    final response = await _repository.sendSignInOtp(phone: phone);
    if (!response.isSuccess) {
      state = state.copyWith(
        message: '',
        error: response.message ?? 'OTP send failed.',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(
      pendingSignIn: PendingOtp(phone: phone, mobile: normalizedMobile),
      pendingSignUp: null,
      pendingPasswordReset: null,
      passwordResetVerified: false,
      message: response.message ?? 'OTP sent.',
      error: '',
      isLoading: false,
    );
  }

  Future<void> verifySignInOtp(String code) async {
    final pending = state.pendingSignIn;
    if (pending == null) return;
    if (!_validOtp(code)) {
      state = state.copyWith(error: 'Enter a valid OTP code.', message: '');
      return;
    }

    state = state.copyWith(message: '', error: '', isLoading: true);
    final response = await _repository.verifySignInOtp(
      phone: pending.phone,
      otp: code.trim(),
    );
    if (!response.isSuccess || response.data == null) {
      state = state.copyWith(
        message: '',
        error: response.message ?? 'OTP verification failed.',
        isLoading: false,
      );
      return;
    }

    final user = (response.data! as AuthUser).copyWith(
      mobile: pending.mobile,
      verified: true,
    );
    final users = <AuthUser>[
      ...state.registeredUsers.where((item) => item.id != user.id),
      user,
    ];
    _repository.saveUsers(users);
    _repository.saveUser(user);
    state = state.copyWith(
      user: user,
      registeredUsers: users,
      pendingSignIn: null,
      pendingSignUp: null,
      pendingPasswordReset: null,
      passwordResetVerified: false,
      message: response.message ?? 'Welcome back, ${user.firstName}!',
      error: '',
      isLoading: false,
    );
  }

  Future<void> startSignUp({
    required String name,
    required String countryCode,
    required String mobile,
  }) async {
    final normalizedName = name.trim();
    final signupPhone = _loginEmailFromMobile(mobile);
    final normalizedMobile = _normalizeMobileWithCountry(countryCode, mobile);
    if (normalizedName.isEmpty || signupPhone.isEmpty) {
      state = state.copyWith(
        error: 'Name and mobile number are required.',
        message: '',
      );
      return;
    }

    final response = await _repository.sendSignUpOtp(phone: signupPhone);

    if (!response.isSuccess) {
      state = state.copyWith(
        message: '',
        error: response.message ?? 'OTP send failed.',
      );
      return;
    }

    state = state.copyWith(
      pendingSignUp: PendingSignUp(
        name: normalizedName,
        mobile: normalizedMobile,
        phone: signupPhone,
      ),
      pendingSignIn: null,
      pendingPasswordReset: null,
      passwordResetVerified: false,
      message: response.message ?? 'Verification code sent.',
      error: '',
    );
  }

  Future<void> verify(String code) async {
    final pending = state.pendingSignUp;
    if (pending == null) return;
    if (!RegExp(r'^\d{4}$').hasMatch(code.trim())) {
      state = state.copyWith(
        error: 'Enter a 4-digit verification code.',
        message: '',
      );
      return;
    }

    final response = await _repository.verifySignUpOtp(
      phone: pending.phone,
      name: pending.name,
      otp: code.trim(),
      password: '',
    );
    if (!response.isSuccess || response.data == null) {
      state = state.copyWith(
        message: '',
        error: response.message ?? 'OTP verification failed.',
      );
      return;
    }

    final user = (response.data! as AuthUser).copyWith(
      mobile: pending.mobile,
      password: '',
      verified: true,
    );
    final users = <AuthUser>[
      ...state.registeredUsers.where((item) => item.id != user.id),
      user,
    ];
    _repository.saveUsers(users);
    _repository.saveUser(user);
    state = state.copyWith(
      user: user,
      registeredUsers: users,
      pendingSignUp: null,
      pendingSignIn: null,
      pendingPasswordReset: null,
      passwordResetVerified: false,
      message: response.message ?? 'Welcome aboard, ${user.firstName}!',
      error: '',
    );
  }

  Future<void> sendPasswordResetOtp({
    required String countryCode,
    required String mobile,
  }) async {
    final phone = _loginEmailFromMobile(mobile);
    final normalizedMobile = _normalizeMobileWithCountry(countryCode, mobile);
    if (phone.isEmpty) {
      state = state.copyWith(error: 'Phone number is required.', message: '');
      return;
    }

    state = state.copyWith(message: '', error: '', isLoading: true);
    final response = await _repository.sendPasswordResetOtp(phone: phone);
    if (!response.isSuccess) {
      state = state.copyWith(
        message: '',
        error: response.message ?? 'Password reset OTP send failed.',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(
      pendingPasswordReset: PendingOtp(phone: phone, mobile: normalizedMobile),
      pendingSignIn: null,
      pendingSignUp: null,
      passwordResetVerified: false,
      message: response.message ?? 'OTP sent.',
      error: '',
      isLoading: false,
    );
  }

  Future<void> verifyPasswordResetOtp(String code) async {
    final pending = state.pendingPasswordReset;
    if (pending == null) return;
    if (!_validOtp(code)) {
      state = state.copyWith(error: 'Enter a valid OTP code.', message: '');
      return;
    }

    state = state.copyWith(message: '', error: '', isLoading: true);
    final response = await _repository.verifyPasswordResetOtp(
      phone: pending.phone,
      otp: code.trim(),
    );
    state = state.copyWith(
      message: response.isSuccess ? response.message ?? 'OTP verified.' : '',
      error: response.isSuccess
          ? ''
          : response.message ?? 'OTP verification failed.',
      passwordResetVerified: response.isSuccess,
      isLoading: false,
    );
  }

  Future<void> resetPassword({
    required String password,
    required String confirmPassword,
  }) async {
    final pending = state.pendingPasswordReset;
    if (pending == null || !state.passwordResetVerified) return;
    if (password.isEmpty || confirmPassword.isEmpty) {
      state = state.copyWith(error: 'Password is required.', message: '');
      return;
    }
    if (password.length < 6) {
      state = state.copyWith(
        error: 'Password must be at least 6 characters long.',
        message: '',
      );
      return;
    }
    if (password != confirmPassword) {
      state = state.copyWith(error: 'Passwords do not match.', message: '');
      return;
    }

    state = state.copyWith(message: '', error: '', isLoading: true);
    final response = await _repository.resetPassword(
      phone: pending.phone,
      password: password,
      confirmPassword: confirmPassword,
    );
    state = state.copyWith(
      pendingPasswordReset: response.isSuccess ? null : pending,
      passwordResetVerified: response.isSuccess
          ? false
          : state.passwordResetVerified,
      message: response.isSuccess
          ? response.message ?? 'Password reset successfully.'
          : '',
      error: response.isSuccess
          ? ''
          : response.message ?? 'Password reset failed.',
      isLoading: false,
    );
  }

  Future<void> onPressedGoogleLogin() async {
    if (state.isLoading) return;
    try {
      state = state.copyWith(message: '', error: '', isLoading: true);

      final signIn = GoogleSignIn.instance;
      final serverClientId = await _googleServerClientId();
      debugPrint('[GoogleLogin] authenticate started');
      debugPrint(
        '[GoogleLogin] serverClientId=${_redact(serverClientId ?? '')}',
      );
      await signIn.initialize(serverClientId: serverClientId);
      final googleAccount = await signIn.authenticate(
        scopeHint: const <String>['email', 'profile'],
      );
      debugPrint(
        '[GoogleLogin] authenticate completed user=${googleAccount.email}',
      );

      final googleAuthentication = googleAccount.authentication;
      final googleIdToken = googleAuthentication.idToken;

      if (googleIdToken == null || googleIdToken.isEmpty) {
        debugPrint('[GoogleLogin] missing Google id token');
        state = state.copyWith(
          error: 'Google authentication token পাওয়া যায়নি।',
          message: '',
          isLoading: false,
        );
        return;
      }

      final credential = GoogleAuthProvider.credential(idToken: googleIdToken);
      final firebaseUserCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final firebaseIdToken = await firebaseUserCredential.user?.getIdToken(
        true,
      );

      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        debugPrint('[GoogleLogin] missing Firebase id token');
        state = state.copyWith(
          error: 'Firebase authentication token পাওয়া যায়নি।',
          message: '',
          isLoading: false,
        );
        return;
      }

      debugPrint('[GoogleLogin] calling backend social login');
      await _completeSocialLogin(
        logTag: 'GoogleLogin',
        providerName: googleAccount.displayName ?? 'Student',
        email: googleAccount.email,
        provider: 'google',
        socialProvider: AuthProviderType.google,
        accessToken: firebaseIdToken,
      );
    } on GoogleSignInException catch (error) {
      debugPrint(
        '[GoogleLogin] GoogleSignInException code=${error.code} '
        'description=${error.description}',
      );
      state = state.copyWith(
        message: '',
        error: error.code == GoogleSignInExceptionCode.canceled
            ? 'Google login cancelled.'
            : 'Google login failed.',
        isLoading: false,
      );
    } catch (error, stackTrace) {
      debugPrint('Google login error: $error');
      debugPrintStack(stackTrace: stackTrace);

      state = state.copyWith(
        message: '',
        error: 'Google login failed. Please try again.',
        isLoading: false,
      );
    }
  }

  Future<void> onPressedAppleLogin() async {
    if (state.isLoading) return;
    try {
      state = state.copyWith(message: '', error: '', isLoading: true);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final authorizationCode = credential.authorizationCode.trim();
      final accessToken = credential.identityToken?.trim().isNotEmpty == true
          ? credential.identityToken!.trim()
          : authorizationCode;

      if (authorizationCode.isEmpty || accessToken.isEmpty) {
        debugPrint('[AppleLogin] missing Apple authorization data');
        state = state.copyWith(
          error: 'Apple authentication token was not available.',
          message: '',
          isLoading: false,
        );
        return;
      }

      await _completeSocialLogin(
        logTag: 'AppleLogin',
        providerName: _appleDisplayName(credential),
        email: credential.email ?? '',
        provider: authorizationCode,
        socialProvider: AuthProviderType.apple,
        accessToken: accessToken,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      debugPrint(
        '[AppleLogin] authorization error code=${error.code} '
        'message=${error.message}',
      );
      state = state.copyWith(
        message: '',
        error: error.code == AuthorizationErrorCode.canceled
            ? 'Apple login cancelled.'
            : error.message,
        isLoading: false,
      );
    } catch (error, stackTrace) {
      debugPrint('Apple login error: $error');
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(
        message: '',
        error: 'Apple login failed. Please try again.',
        isLoading: false,
      );
    }
  }

  Future<void> _completeSocialLogin({
    required String logTag,
    required String providerName,
    required String email,
    required String provider,
    required AuthProviderType socialProvider,
    required String accessToken,
  }) async {
    debugPrint('[$logTag] calling backend social login');
    final response = await _repository.socialLogin(
      name: providerName.trim().isEmpty ? 'Student' : providerName.trim(),
      email: email,
      provider: provider,
      socialProvider: socialProvider.name,
      accessToken: accessToken,
    );
    debugPrint(
      '[$logTag] backend status=${response.statusCode} '
      'success=${response.isSuccess}',
    );

    if (!response.isSuccess || response.data == null) {
      state = state.copyWith(
        message: '',
        error:
            response.message ??
            '${_providerLabel(socialProvider)} login failed.',
        isLoading: false,
      );
      return;
    }

    final user = response.data! as AuthUser;
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
      message: response.message ?? 'Welcome, ${user.firstName}!',
      error: '',
      isLoading: false,
    );
  }

  Future<String?> updateProfile({
    required String name,
    required String email,
    required String university,
    String? avatarPath,
  }) async {
    final current = state.user;
    if (current == null) return 'Please login again.';

    state = state.copyWith(message: '', error: '', isLoading: true);
    final response = await _repository.updateProfile(
      name: name,
      email: email,
      phone: _loginEmailFromMobile(current.mobile),
      avatarPath: avatarPath,
      currentUser: current,
    );

    if (!response.isSuccess || response.data == null) {
      final message = response.message ?? 'Profile update failed.';
      state = state.copyWith(message: '', error: message, isLoading: false);
      return message;
    }

    final updated = (response.data! as AuthUser).copyWith(
      university: university.trim(),
    );
    final users = state.registeredUsers.any((item) => item.id == current.id)
        ? state.registeredUsers
              .map((item) => item.id == current.id ? updated : item)
              .toList(growable: false)
        : <AuthUser>[...state.registeredUsers, updated];
    state = state.copyWith(
      user: updated,
      registeredUsers: users,
      message: response.message ?? 'Profile updated.',
      error: '',
      isLoading: false,
    );
    _repository.saveUsers(users);
    _repository.saveUser(updated);
    return null;
  }

  Future<String?> updatePassword({
    required String oldPassword,
    required String password,
    required String confirmPassword,
  }) async {
    final current = state.user;
    if (current == null) return 'Please login again.';
    if (current.hasPassword && oldPassword.trim().isEmpty) {
      return 'Current password is required.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters long.';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }

    state = state.copyWith(message: '', error: '', isLoading: true);
    final response = await _repository.changePassword(
      oldPassword: current.hasPassword ? oldPassword : null,
      password: password,
      confirmPassword: confirmPassword,
    );

    if (!response.isSuccess) {
      final message = response.message ?? 'Password update failed.';
      state = state.copyWith(message: '', error: message, isLoading: false);
      return message;
    }

    final updated = current.copyWith(password: password, hasPassword: true);
    final users = state.registeredUsers.any((item) => item.id == current.id)
        ? state.registeredUsers
              .map((item) => item.id == current.id ? updated : item)
              .toList(growable: false)
        : <AuthUser>[...state.registeredUsers, updated];
    _repository.saveUsers(users);
    _repository.saveUser(updated);
    state = state.copyWith(
      user: updated,
      registeredUsers: users,
      message: response.message ?? 'Password updated.',
      error: '',
      isLoading: false,
    );
    return null;
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
    if (current?.provider == AuthProviderType.google) {
      unawaited(GoogleSignIn.instance.signOut());
      unawaited(FirebaseAuth.instance.signOut());
    }
    ApiClient.instance.clearAuthToken();
    _repository.saveUser(null);
    state = state.copyWith(
      user: null,
      pendingSignUp: null,
      pendingSignIn: null,
      pendingPasswordReset: null,
      passwordResetVerified: false,
      message: '',
      error: '',
    );
  }

  void deleteAccount() {
    final current = state.user;
    final users = current == null
        ? state.registeredUsers
        : state.registeredUsers
              .where((item) => item.id != current.id)
              .toList(growable: false);
    _repository.saveUsers(users);
    _repository.saveUser(null);
    ApiClient.instance.clearAuthToken();
    state = state.copyWith(
      user: null,
      registeredUsers: users,
      pendingSignUp: null,
      pendingSignIn: null,
      pendingPasswordReset: null,
      passwordResetVerified: false,
      message: '',
      error: '',
    );
  }

  void cancelPendingAuth() {
    state = state.copyWith(
      pendingSignUp: null,
      pendingSignIn: null,
      pendingPasswordReset: null,
      passwordResetVerified: false,
      message: '',
      error: '',
      isLoading: false,
    );
  }

  AuthUser? _findUser(bool Function(AuthUser user) test) {
    for (final user in state.registeredUsers) {
      if (test(user)) return user;
    }
    return null;
  }

  String _normalizeMobile(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _normalizeMobileWithCountry(String countryCode, String mobile) {
    final country = _normalizeMobile(countryCode);
    var local = _normalizeMobile(mobile);
    if (country == '880' && local.startsWith('0')) {
      local = local.substring(1);
    }
    return '$country$local';
  }

  String _loginEmailFromMobile(String value) {
    final trimmed = value.trim();
    if (trimmed.contains('@')) return trimmed;
    final digits = _normalizeMobile(trimmed);
    if (digits.isEmpty || digits.startsWith('0')) return digits;
    if (digits.startsWith('880')) return '0${digits.substring(3)}';
    return '0$digits';
  }

  bool _validOtp(String code) => RegExp(r'^\d{4,6}$').hasMatch(code.trim());

  String _appleDisplayName(AuthorizationCredentialAppleID credential) {
    final parts = <String>[
      credential.givenName?.trim() ?? '',
      credential.familyName?.trim() ?? '',
    ].where((part) => part.isNotEmpty).toList(growable: false);
    return parts.isEmpty ? 'Student' : parts.join(' ');
  }

  String _providerLabel(AuthProviderType provider) {
    final name = provider.name;
    return '${name.substring(0, 1).toUpperCase()}${name.substring(1)}';
  }

  Future<String?> _googleServerClientId() async {
    final envValue = EnvConfig.googleClientId.trim();
    if (envValue.isNotEmpty) return envValue;
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    final value = await _googleChannel.invokeMethod<String>(
      'defaultWebClientId',
    );
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  String _redact(String value) {
    if (value.isEmpty) return 'missing';
    final parts = value.split('-');
    return parts.isEmpty ? 'present' : '${parts.first}-...';
  }
}
