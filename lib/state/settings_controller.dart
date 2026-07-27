import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentos/core/storage/preferences_provider.dart';

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.light,
    this.pushNotifications = true,
    this.dealAlerts = true,
    this.locationServices = true,
    this.biometricLock = false,
  });

  final ThemeMode themeMode;
  final bool pushNotifications;
  final bool dealAlerts;
  final bool locationServices;
  final bool biometricLock;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? pushNotifications,
    bool? dealAlerts,
    bool? locationServices,
    bool? biometricLock,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        pushNotifications: pushNotifications ?? this.pushNotifications,
        dealAlerts: dealAlerts ?? this.dealAlerts,
        locationServices: locationServices ?? this.locationServices,
        biometricLock: biometricLock ?? this.biometricLock,
      );
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  static const _darkModeKey = 'studentos.settings.darkMode';
  static const _pushKey = 'studentos.settings.pushNotifications';
  static const _dealKey = 'studentos.settings.dealAlerts';
  static const _locationKey = 'studentos.settings.locationServices';
  static const _biometricKey = 'studentos.settings.biometricLock';

  @override
  AppSettings build() {
    final preferences = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      themeMode: (preferences.getBool(_darkModeKey) ?? false) ? ThemeMode.dark : ThemeMode.light,
      pushNotifications: preferences.getBool(_pushKey) ?? true,
      dealAlerts: preferences.getBool(_dealKey) ?? true,
      locationServices: preferences.getBool(_locationKey) ?? true,
      biometricLock: preferences.getBool(_biometricKey) ?? false,
    );
  }

  void setDarkMode(bool enabled) {
    state = state.copyWith(themeMode: enabled ? ThemeMode.dark : ThemeMode.light);
    unawaited(ref.read(sharedPreferencesProvider).setBool(_darkModeKey, enabled));
  }

  void setPushNotifications(bool value) {
    state = state.copyWith(pushNotifications: value);
    unawaited(ref.read(sharedPreferencesProvider).setBool(_pushKey, value));
  }

  void setDealAlerts(bool value) {
    state = state.copyWith(dealAlerts: value);
    unawaited(ref.read(sharedPreferencesProvider).setBool(_dealKey, value));
  }

  void setLocationServices(bool value) {
    state = state.copyWith(locationServices: value);
    unawaited(ref.read(sharedPreferencesProvider).setBool(_locationKey, value));
  }

  void setBiometricLock(bool value) {
    state = state.copyWith(biometricLock: value);
    unawaited(ref.read(sharedPreferencesProvider).setBool(_biometricKey, value));
  }
}
