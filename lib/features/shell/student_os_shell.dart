import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studentos/core/constants/app_strings.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/theme/app_sizes.dart';
import 'package:studentos/core/widgets/common_widgets.dart';
import 'package:studentos/features/auth/data/auth_controller.dart';
import 'package:studentos/features/auth/domain/auth_user.dart';
import 'package:studentos/state/favorites_controller.dart';

class StudentOsShell extends ConsumerStatefulWidget {
  const StudentOsShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<StudentOsShell> createState() => _StudentOsShellState();
}

class _StudentOsShellState extends ConsumerState<StudentOsShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _destinations = <_Destination>[
    _Destination(
      label: AppStrings.career,
      icon: Icons.work_outline_rounded,
      selectedIcon: Icons.work_rounded,
    ),
    _Destination(
      label: AppStrings.shop,
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag_rounded,
    ),
    _Destination(
      label: AppStrings.home,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      featured: true,
    ),
    _Destination(
      label: AppStrings.food,
      icon: Icons.restaurant_outlined,
      selectedIcon: Icons.restaurant_rounded,
    ),
    _Destination(
      label: AppStrings.more,
      icon: Icons.more_horiz_rounded,
      selectedIcon: Icons.more_horiz_rounded,
    ),
  ];

  void _goToBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final cartCount = ref
        .watch(cartProvider)
        .values
        .fold<int>(0, (sum, value) => sum + value);
    return Scaffold(
      key: _scaffoldKey,
      drawer: _StudentSidebarDrawer(user: user),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(AppSizes.topBarHeight),
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            bottom: false,
            child: Container(
              height: AppSizes.topBarHeight,
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                AppSizes.gapSm,
                AppSizes.pagePadding,
                AppSizes.gapSm,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
              ),
              child: Row(
                children: <Widget>[
                  AppRoundIconButton(
                    tooltip: AppStrings.menu,
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    icon: Icons.menu_rounded,
                  ),
                  const SizedBox(width: AppSizes.gapSm),
                  Expanded(
                    child: Image.asset(
                      'assets/branding/studentos_wordmark.png',
                      height: 32,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  Badge(
                    isLabelVisible: cartCount > 0,
                    label: Text('$cartCount'),
                    child: AppRoundIconButton(
                      tooltip: AppStrings.cart,
                      onPressed: () => context.push('/cart'),
                      icon: Icons.shopping_cart_outlined,
                      size: AppSizes.topBarIcon,
                      iconSize: 17,
                    ),
                  ),
                  const SizedBox(width: AppSizes.gapXs),
                  Badge(
                    label: const Text('3'),
                    child: AppRoundIconButton(
                      tooltip: AppStrings.notifications,
                      onPressed: () => context.push('/notifications'),
                      icon: Icons.notifications_none_rounded,
                      size: AppSizes.topBarIcon,
                      iconSize: 17,
                    ),
                  ),
                  const SizedBox(width: AppSizes.gapMd),
                  InkWell(
                    onTap: () => context.push('/profile'),
                    customBorder: const CircleBorder(),
                    child: Semantics(
                      button: true,
                      label:
                          'Open profile for ${user?.name ?? AppStrings.student.toLowerCase()}',
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: <Color>[AppColors.teal, AppColors.purple],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          user?.initials ?? 'S',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: widget.navigationShell,
      bottomNavigationBar: _StudentBottomNavigation(
        currentIndex: widget.navigationShell.currentIndex,
        destinations: _destinations,
        onSelected: _goToBranch,
      ),
    );
  }
}

class _StudentBottomNavigation extends StatelessWidget {
  const _StudentBottomNavigation({
    required this.currentIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int currentIndex;
  final List<_Destination> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(
        top: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
    ),
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      child: Row(
        children: List<Widget>.generate(destinations.length, (index) {
          final destination = destinations[index];
          final selected = currentIndex == index;
          return Expanded(
            child: Semantics(
              button: true,
              selected: selected,
              label: destination.label,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onSelected(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: destination.featured ? 42 : 38,
                        height: destination.featured ? 42 : 36,
                        decoration: BoxDecoration(
                          color: destination.featured && selected
                              ? AppColors.blue
                              : selected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          selected
                              ? destination.selectedIcon
                              : destination.icon,
                          size: destination.featured ? 23 : 21,
                          color: destination.featured && selected
                              ? Colors.white
                              : selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        destination.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );
}

class _StudentSidebarDrawer extends StatelessWidget {
  const _StudentSidebarDrawer({required this.user});

  static const _items = <_DrawerItem>[
    _DrawerItem(
      AppStrings.profile,
      Icons.person_outline_rounded,
      '/profile',
      AppColors.blue,
    ),
    _DrawerItem(
      AppStrings.studentId,
      Icons.workspace_premium_outlined,
      '/student-id',
      AppColors.orange,
    ),
    _DrawerItem(
      AppStrings.budgetManager,
      Icons.account_balance_wallet_outlined,
      '/budget',
      AppColors.greenDark,
    ),
    _DrawerItem(
      AppStrings.taskManager,
      Icons.calendar_today_outlined,
      '/tasks',
      AppColors.purple,
    ),
    _DrawerItem(
      AppStrings.marketplace,
      Icons.shopping_bag_outlined,
      '/marketplace',
      AppColors.coral,
    ),
    _DrawerItem(
      AppStrings.tuition,
      Icons.menu_book_outlined,
      '/tuition',
      AppColors.teal,
    ),
    _DrawerItem(
      AppStrings.savedItems,
      Icons.favorite_border_rounded,
      '/saved',
      AppColors.danger,
    ),
    _DrawerItem(
      'Dark Mode',
      Icons.dark_mode_outlined,
      '/settings?focus=appearance',
      AppColors.teal,
    ),
    _DrawerItem(
      AppStrings.helpCenter,
      Icons.help_outline_rounded,
      '/help',
      AppColors.blue,
    ),
    _DrawerItem(
      AppStrings.about,
      Icons.info_outline_rounded,
      '/about',
      AppColors.muted,
    ),
    _DrawerItem(
      AppStrings.settings,
      Icons.settings_outlined,
      '/settings',
      AppColors.muted,
    ),
    _DrawerItem(
      AppStrings.logout,
      Icons.logout_rounded,
      '/logout',
      AppColors.danger,
    ),
  ];

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'Student';
    final university = user?.university.trim();
    return Drawer(
      width: MediaQuery.sizeOf(context).width * .8,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      AppStrings.menu,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: AppStrings.closeMenu,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => _open(context, '/profile'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: Center(
                        child: Text(
                          user?.initials ?? 'S',
                          style: const TextStyle(
                            color: AppColors.gray700,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            university == null || university.isEmpty
                                ? 'StudentOS member'
                                : 'CSE · $university · Y3',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.gray400,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: <Widget>[
                  for (final item in _items)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _open(context, item.route),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(
                                item.icon,
                                color: item.color,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.label,
                                style: const TextStyle(
                                  color: AppColors.gray800,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _open(BuildContext context, String route) {
    Navigator.pop(context);
    if (route == '/shop' ||
        route == '/career' ||
        route == '/food' ||
        route == '/more') {
      context.go(route);
      return;
    }
    context.push(route);
  }
}

class _DrawerItem {
  const _DrawerItem(this.label, this.icon, this.route, this.color);

  final String label;
  final IconData icon;
  final String route;
  final Color color;
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.featured = false,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool featured;
}
