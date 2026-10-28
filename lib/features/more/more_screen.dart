import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:studentos/core/constants/app_strings.dart';
import 'package:studentos/core/theme/app_colors.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const _services = <_ServiceItem>[
    _ServiceItem(AppStrings.budgetPlanner, '💰', '/budget'),
    _ServiceItem(AppStrings.taskPlanner, '📝', '/tasks'),
    _ServiceItem(AppStrings.studentDeals, '🎟️', '/shop', tab: true),
    _ServiceItem('Order History', '📦', '/orders'),
    _ServiceItem(AppStrings.careerHub, '💼', '/career', tab: true),
    _ServiceItem(AppStrings.foodDeals, '🍕', '/food', tab: true),
    _ServiceItem(AppStrings.marketplace, '🛍️', '/marketplace'),
    _ServiceItem(AppStrings.tuition, '📚', '/tuition'),
  ];

  @override
  Widget build(BuildContext context) => ListView(
    key: const PageStorageKey<String>('more-scroll'),
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
    children: <Widget>[
      const Text(
        'Our Services',
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'All of the services available in one place.',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 16),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: .75,
        ),
        itemBuilder: (context, index) {
          final service = _services[index];
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => service.tab
                ? context.go(service.route)
                : context.push(service.route),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(20),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .035),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(service.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 8),
                  Text(
                    service.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  );
}

class _ServiceItem {
  const _ServiceItem(this.label, this.emoji, this.route, {this.tab = false});

  final String label;
  final String emoji;
  final String route;
  final bool tab;
}
