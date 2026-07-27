import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/widgets/app_card.dart';
import 'package:studentos/data/demo_data.dart';
import 'package:studentos/features/auth/data/auth_controller.dart';
import 'package:studentos/state/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.focus});

  final String? focus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          if (focus == 'appearance')
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(16)),
              child: const Text('Appearance settings', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w800)),
            ),
          _SettingsGroup(title: 'Appearance', children: <Widget>[
            SwitchListTile(
              value: settings.themeMode == ThemeMode.dark,
              onChanged: controller.setDarkMode,
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark Mode'),
              subtitle: const Text('Use a dark color scheme'),
            ),
          ]),
          const SizedBox(height: 14),
          _SettingsGroup(title: 'Notifications', children: <Widget>[
            SwitchListTile(value: settings.pushNotifications, onChanged: controller.setPushNotifications, secondary: const Icon(Icons.notifications_outlined), title: const Text('Push notifications')),
            const Divider(height: 1, indent: 56),
            SwitchListTile(value: settings.dealAlerts, onChanged: controller.setDealAlerts, secondary: const Icon(Icons.local_offer_outlined), title: const Text('Student deal alerts')),
          ]),
          const SizedBox(height: 14),
          _SettingsGroup(title: 'Privacy & Security', children: <Widget>[
            SwitchListTile(value: settings.locationServices, onChanged: controller.setLocationServices, secondary: const Icon(Icons.location_on_outlined), title: const Text('Location services'), subtitle: const Text('Used for nearby tuition and food results')),
            const Divider(height: 1, indent: 56),
            SwitchListTile(value: settings.biometricLock, onChanged: controller.setBiometricLock, secondary: const Icon(Icons.fingerprint_rounded), title: const Text('Biometric lock')),
            const Divider(height: 1, indent: 56),
            ListTile(onTap: () => context.push('/privacy'), leading: const Icon(Icons.shield_outlined), title: const Text('Privacy policy'), trailing: const Icon(Icons.chevron_right_rounded)),
          ]),
          const SizedBox(height: 14),
          _SettingsGroup(title: 'Account', children: <Widget>[
            ListTile(onTap: () => context.push('/profile'), leading: const Icon(Icons.person_outline_rounded), title: const Text('Edit profile'), trailing: const Icon(Icons.chevron_right_rounded)),
            const Divider(height: 1, indent: 56),
            ListTile(onTap: () => context.push('/logout'), leading: const Icon(Icons.logout_rounded, color: AppColors.danger), title: const Text('Logout', style: TextStyle(color: AppColors.danger)), trailing: const Icon(Icons.chevron_right_rounded)),
          ]),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(padding: const EdgeInsets.only(left: 4, bottom: 7), child: Text(title.toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1))),
          AppCard(padding: EdgeInsets.zero, radius: 20, child: Column(children: children)),
        ],
      );
}

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final visible = faqItems.where((item) => item['q']!.toLowerCase().contains(_query.toLowerCase()) || item['a']!.toLowerCase().contains(_query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          TextField(onChanged: (value) => setState(() => _query = value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search help...')),
          const SizedBox(height: 16),
          AppCard(
            color: AppColors.blueSoft,
            child: Row(children: <Widget>[
              const Icon(Icons.support_agent_rounded, color: AppColors.blue, size: 34),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text('Need more help?', style: TextStyle(fontWeight: FontWeight.w900)), SizedBox(height: 3), Text('Contact StudentOS support for account and service questions.', style: TextStyle(color: AppColors.muted, fontSize: 12))])),
              FilledButton.tonal(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support request started'))), child: const Text('Contact')),
            ]),
          ),
          const SizedBox(height: 18),
          Text('Frequently asked questions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 9),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: visible.map((item) => ExpansionTile(title: Text(item['q']!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)), childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: <Widget>[Text(item['a']!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5))])).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Privacy')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const <Widget>[
            _PolicyCard(icon: Icons.lock_outline_rounded, title: 'Your data stays protected', body: 'StudentOS is designed to request only the information needed for the services you choose. Production integrations should use encrypted transport, secure local storage, and least-privilege access.'),
            SizedBox(height: 12),
            _PolicyCard(icon: Icons.location_on_outlined, title: 'Location controls', body: 'Nearby food and tuition features should use location only with clear permission. You can disable location services from Settings.'),
            SizedBox(height: 12),
            _PolicyCard(icon: Icons.payments_outlined, title: 'Payments', body: 'This converted prototype contains no live payment gateway and does not collect real card or banking credentials.'),
            SizedBox(height: 12),
            _PolicyCard(icon: Icons.delete_outline_rounded, title: 'Account deletion', body: 'A production release should provide a clear account deletion workflow and document retention periods for every data category.'),
          ],
        ),
      );
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.green.withValues(alpha: .1), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: AppColors.greenDark)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(body, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5, fontSize: 13))])),
        ]),
      );
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('About')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const SizedBox(height: 14),
            Center(child: Container(width: 92, height: 92, decoration: BoxDecoration(gradient: const LinearGradient(colors: <Color>[AppColors.blue, AppColors.purple]), borderRadius: BorderRadius.circular(28)), alignment: Alignment.center, child: const Text('S', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)))),
            const SizedBox(height: 16),
            Text('StudentOS', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 5),
            Text('The everything app for students', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            const AppCard(child: Text('StudentOS combines budgeting, productivity, shopping, food, career development, tuition services, marketplace tools, and student identity into one cohesive mobile experience.', textAlign: TextAlign.center, style: TextStyle(height: 1.55))),
            const SizedBox(height: 14),
            const AppCard(padding: EdgeInsets.zero, child: Column(children: <Widget>[
              ListTile(title: Text('Version'), trailing: Text('1.1.0')),
              Divider(height: 1, indent: 16),
              ListTile(title: Text('Build'), trailing: Text('Flutter conversion')),
              Divider(height: 1, indent: 16),
              ListTile(title: Text('Prototype status'), trailing: Text('Demo data')),
            ])),
          ],
        ),
      );
}

class LogoutScreen extends ConsumerWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Logout')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppCard(
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Container(width: 68, height: 68, decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: .1), shape: BoxShape.circle), child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 32)),
                const SizedBox(height: 16),
                Text('Log out of StudentOS?', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 7),
                Text('Your local demo session will be cleared. Saved app content remains on this device.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/auth');
                  },
                  style: FilledButton.styleFrom(backgroundColor: AppColors.danger, minimumSize: const Size.fromHeight(48)),
                  child: const Text('Logout'),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
              ]),
            ),
          ),
        ),
      );
}
