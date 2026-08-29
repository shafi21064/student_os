import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studentos/core/storage/preferences_provider.dart';
import 'package:studentos/features/auth/data/auth_controller.dart';
import 'package:studentos/state/budget_controller.dart';
import 'package:studentos/state/favorites_controller.dart';
import 'package:studentos/state/tasks_controller.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env', isOptional: true);
  });

  test('task controller starts empty and adds tasks immutably', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(tasksProvider), isEmpty);

    final before = container.read(tasksProvider).length;
    container.read(tasksProvider.notifier).add('Review lecture notes');
    expect(container.read(tasksProvider).length, before + 1);
  });

  test('budget controller updates the selected month budget', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(budgetProvider.notifier).updateBudget(9500);
    expect(container.read(budgetProvider).budget, 9500);
  });

  test('budget controller subtracts added expenses from balance', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = container.read(budgetProvider);
    container
        .read(budgetProvider.notifier)
        .addExpense(label: 'Lunch', category: 'Food', amount: 300);
    final after = container.read(budgetProvider);

    expect(after.spent, before.spent + 300);
    expect(after.remaining, before.remaining - 300);
  });

  test('favorites controller toggles ids', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(favoritesProvider.notifier).toggle('ipad-air-m2');
    expect(container.read(favoritesProvider), contains('ipad-air-m2'));
    container.read(favoritesProvider.notifier).toggle('ipad-air-m2');
    expect(container.read(favoritesProvider), isNot(contains('ipad-air-m2')));
  });

  test('auth controller does not create a local demo session', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    expect(container.read(authProvider).isAuthenticated, isFalse);
    await container
        .read(authProvider.notifier)
        .signIn(
          countryCode: '+880',
          mobile: '01700000000',
          password: 'studentos123',
        );
    expect(container.read(authProvider).isAuthenticated, isFalse);

    container.read(authProvider.notifier).logout();
    expect(container.read(authProvider).isAuthenticated, isFalse);

    await container
        .read(authProvider.notifier)
        .signIn(
          countryCode: '+880',
          mobile: '01700000000',
          password: 'studentos123',
        );
    expect(container.read(authProvider).isAuthenticated, isFalse);
  });
}
