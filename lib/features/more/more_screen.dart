import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/widgets/app_card.dart';
import 'package:studentos/core/widgets/common_widgets.dart';
import 'package:studentos/data/models.dart';
import 'package:studentos/features/auth/data/auth_controller.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  static const sections = <MoreMenuSection>[
    MoreMenuSection(title: 'Your Account', items: <MoreMenuItem>[
      MoreMenuItem(label: 'Profile', route: '/profile', icon: Icons.person_outline_rounded, color: AppColors.blue),
      MoreMenuItem(label: 'Budget Manager', route: '/budget', icon: Icons.account_balance_wallet_outlined, color: AppColors.greenDark),
      MoreMenuItem(label: 'Task Manager', route: '/tasks', icon: Icons.event_available_outlined, color: AppColors.purple),
      MoreMenuItem(label: 'Student ID', route: '/student-id', icon: Icons.badge_outlined, color: AppColors.orange),
    ]),
    MoreMenuSection(title: 'Services', items: <MoreMenuItem>[
      MoreMenuItem(label: 'Tuition', route: '/tuition', icon: Icons.school_outlined, color: AppColors.blue),
      MoreMenuItem(label: 'Buy & Sell', route: '/buy-sell', icon: Icons.swap_horiz_rounded, color: Color(0xFFEC4899)),
      MoreMenuItem(label: 'Marketplace', route: '/marketplace', icon: Icons.storefront_outlined, color: AppColors.coral),
      MoreMenuItem(label: 'Events', route: '/events', icon: Icons.celebration_outlined, color: Color(0xFF0D9488)),
    ]),
    MoreMenuSection(title: 'Productivity', items: <MoreMenuItem>[
      MoreMenuItem(label: 'Notes', route: '/notes', icon: Icons.note_alt_outlined, color: AppColors.orange),
      MoreMenuItem(label: 'Calculator', route: '/calculator', icon: Icons.calculate_outlined, color: AppColors.blue),
      MoreMenuItem(label: 'Bookmarks', route: '/bookmarks', icon: Icons.bookmark_border_rounded, color: AppColors.purple),
      MoreMenuItem(label: 'Saved Items', route: '/saved', icon: Icons.favorite_border_rounded, color: AppColors.danger),
    ]),
    MoreMenuSection(title: 'Settings & Help', items: <MoreMenuItem>[
      MoreMenuItem(label: 'Settings', route: '/settings', icon: Icons.settings_outlined, color: AppColors.muted),
      MoreMenuItem(label: 'Help Center', route: '/help', icon: Icons.help_outline_rounded, color: AppColors.blue),
      MoreMenuItem(label: 'Privacy', route: '/privacy', icon: Icons.shield_outlined, color: AppColors.greenDark),
      MoreMenuItem(label: 'Dark Mode', route: '/settings?focus=appearance', icon: Icons.dark_mode_outlined, color: AppColors.purple),
    ]),
    MoreMenuSection(title: '', items: <MoreMenuItem>[
      MoreMenuItem(label: 'About', route: '/about', icon: Icons.info_outline_rounded, color: AppColors.muted),
      MoreMenuItem(label: 'Logout', route: '/logout', icon: Icons.logout_rounded, color: AppColors.danger),
    ]),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final university = user?.university.trim();
    return ListView(
        key: const PageStorageKey<String>('more-scroll'),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: <Widget>[
          AppCard(
            onTap: () => context.push('/profile'),
            child: Row(
              children: <Widget>[
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: <Color>[AppColors.teal, AppColors.purple])),
                  alignment: Alignment.center,
                  child: Text(user?.initials ?? 'S', style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(user?.name ?? 'Student', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 3),
                      Text(university == null || university.isEmpty ? 'StudentOS member' : '$university · Student', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                      const SizedBox(height: 7),
                      Wrap(spacing: 6, runSpacing: 6, children: <Widget>[
                        BadgeLabel(user?.verified == true ? '✓ Student Verified' : 'Verification pending'),
                        const BadgeLabel('Premium', color: AppColors.greenDark),
                      ]),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...sections.map((section) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (section.title.isNotEmpty) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(section.title.toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                      ),
                    ],
                    AppCard(
                      padding: EdgeInsets.zero,
                      radius: 20,
                      child: Column(
                        children: List<Widget>.generate(section.items.length, (index) {
                          final item = section.items[index];
                          return Column(
                            children: <Widget>[
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                                onTap: () => context.push(item.route),
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(color: item.color.withValues(alpha: .1), borderRadius: BorderRadius.circular(13)),
                                  child: Icon(item.icon, color: item.color, size: 20),
                                ),
                                title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                              ),
                              if (index < section.items.length - 1) const Divider(height: 1, indent: 66),
                            ],
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      );
  }
}
