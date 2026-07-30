import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/theme/app_sizes.dart';
import 'package:studentos/core/widgets/common_widgets.dart';
import 'package:studentos/features/auth/data/auth_controller.dart';
import 'package:studentos/state/favorites_controller.dart';

class StudentOsShell extends ConsumerStatefulWidget {
  const StudentOsShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<StudentOsShell> createState() => _StudentOsShellState();
}

class _StudentOsShellState extends ConsumerState<StudentOsShell> {
  static const _destinations = <_Destination>[
    _Destination(
      label: 'Career',
      icon: Icons.work_outline_rounded,
      selectedIcon: Icons.work_rounded,
    ),
    _Destination(
      label: 'Shop',
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag_rounded,
    ),
    _Destination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      featured: true,
    ),
    _Destination(
      label: 'Food',
      icon: Icons.restaurant_outlined,
      selectedIcon: Icons.restaurant_rounded,
    ),
    _Destination(
      label: 'More',
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
                    tooltip: 'Menu',
                    onPressed: () => context.go('/more'),
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
                      tooltip: 'Cart',
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
                      tooltip: 'Notifications',
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
                      label: 'Open profile for ${user?.name ?? 'student'}',
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
