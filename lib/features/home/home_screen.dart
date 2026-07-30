import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/theme/app_sizes.dart';
import 'package:studentos/core/widgets/app_card.dart';
import 'package:studentos/core/widgets/budget_donut.dart';
import 'package:studentos/core/widgets/common_widgets.dart';
import 'package:studentos/data/demo_data.dart';
import 'package:studentos/data/models.dart';
import 'package:studentos/features/auth/data/auth_controller.dart';
import 'package:studentos/state/budget_controller.dart';
import 'package:studentos/state/favorites_controller.dart';
import 'package:studentos/state/tasks_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final budget = ref.watch(budgetProvider);
    final completed = tasks.where((task) => task.completed).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
      child: CustomScrollView(
        key: const PageStorageKey<String>('home-scroll'),
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 18, 0, 32),
            sliver: SliverList.list(
              children: <Widget>[
                const _Greeting(),
                const SizedBox(height: 12),
                const _AiSearchBar(),
                const SizedBox(height: 18),
                _BudgetCard(budget: budget),
                const SizedBox(height: 18),
                _TasksCard(tasks: tasks, completed: completed),
                const SizedBox(height: 22),
                const SectionHeader(title: 'Explore StudentOS'),
                const SizedBox(height: 10),
                const _FeatureHighlights(),
                const SizedBox(height: 22),
                SectionHeader(
                  title: 'Job Opportunities',
                  onSeeAll: () => context.go('/career?section=internships'),
                ),
                const SizedBox(height: 10),
                ...internships.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CatalogListTile(
                      item: item,
                      onTap: () => _open(context, 'job', item),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SectionHeader(
                  title: 'Skill Development',
                  onSeeAll: () => context.go('/career?section=courses'),
                ),
                const SizedBox(height: 10),
                _HorizontalCatalog(items: courses, kind: 'course'),
                const SizedBox(height: 22),
                SectionHeader(
                  title: 'Buy & Sell',
                  onSeeAll: () => context.push('/buy-sell'),
                ),
                const SizedBox(height: 10),
                ...buySellListings
                    .take(3)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CatalogListTile(
                          item: item,
                          onTap: () => _open(context, 'buysell', item),
                        ),
                      ),
                    ),
                const SizedBox(height: 12),
                SectionHeader(
                  title: 'Marketplace Picks',
                  onSeeAll: () => context.push('/marketplace'),
                ),
                const SizedBox(height: 10),
                _HorizontalCatalog(
                  items: marketplaceProducts,
                  kind: 'marketplace',
                  showFavorite: true,
                ),
                const SizedBox(height: 22),
                SectionHeader(
                  title: 'Food Deals Near You',
                  onSeeAll: () => context.go('/food'),
                ),
                const SizedBox(height: 10),
                _HorizontalCatalog(items: restaurants, kind: 'restaurant'),
                const SizedBox(height: 22),
                SectionHeader(
                  title: 'Nearby Tuition Jobs',
                  onSeeAll: () => context.push('/tuition'),
                ),
                const SizedBox(height: 10),
                ...tuitionJobs
                    .take(3)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CatalogListTile(
                          item: item,
                          onTap: () => _open(context, 'tuition', item),
                          trailing: FilledButton.tonal(
                            onPressed: () => _open(context, 'tuition', item),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(64, 36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                              ),
                            ),
                            child: const Text('Apply'),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _open(BuildContext context, String kind, CatalogItem item) =>
      context.push('/details/$kind/${item.id}');
}

class _AiSearchBar extends StatefulWidget {
  const _AiSearchBar();

  @override
  State<_AiSearchBar> createState() => _AiSearchBarState();
}

class _AiSearchBarState extends State<_AiSearchBar> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % searchPlaceholders.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () => context.push('/search'),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 550),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withValues(alpha: .7), width: 1.3),
        boxShadow: <BoxShadow>[
          BoxShadow(color: _accent.withValues(alpha: .14), blurRadius: 14),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.search_rounded,
                size: 19,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 9),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Text(
                  searchPlaceholders[_index],
                  key: ValueKey<int>(_index),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: AppColors.purple,
              ),
        ],
      ),
    ),
  );

  Color get _accent => switch (_index % 3) {
    0 => AppColors.purple,
    1 => AppColors.teal,
    _ => AppColors.green,
  };
}

class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final university = user?.university.trim();
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Good morning 👋',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user?.name ?? 'Student',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        BadgeLabel(
          university == null || university.isEmpty
              ? 'StudentOS Member'
              : '$university • Student',
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget});

  final BudgetState budget;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: () => context.push('/budget'),
    padding: const EdgeInsets.all(20),
    child: Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('My Budget', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            BadgeLabel(budget.selectedMonth),
            const Spacer(),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                size: 19,
                color: AppColors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            BudgetDonut(budget: budget.budget, spent: budget.spent),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'BALANCE',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '৳${_digits(budget.remaining.clamp(0, 999999999).toInt())}',
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      _BudgetMetric(
                        label: 'BUDGET',
                        value: '৳${_digits(budget.budget)}',
                        color: AppColors.purple,
                      ),
                      const SizedBox(width: 20),
                      _BudgetMetric(
                        label: 'SPENT',
                        value: '৳${_digits(budget.spent)}',
                        color: AppColors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Text(
              'Monthly progress',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Text(
              '${((1 - budget.progress) * 100).round()}% left',
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: budget.progress,
            minHeight: 8,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    ),
  );
}

class _BudgetMetric extends StatelessWidget {
  const _BudgetMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: .8,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _TasksCard extends ConsumerWidget {
  const _TasksCard({required this.tasks, required this.completed});

  final List<TaskItem> tasks;
  final int completed;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppCard(
    child: Column(
      children: <Widget>[
        SectionHeader(
          title: "Today's Tasks",
          onSeeAll: () => context.push('/tasks'),
        ),
        const SizedBox(height: 8),
        ...tasks
            .take(4)
            .map(
              (task) => InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => ref.read(tasksProvider.notifier).toggle(task.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: <Widget>[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: task.completed
                              ? AppColors.blue
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: task.completed
                                ? AppColors.blue
                                : Theme.of(context).colorScheme.outline,
                            width: 2,
                          ),
                        ),
                        child: task.completed
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 15,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            color: task.completed
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                      .withValues(alpha: .55)
                                : null,
                            decoration: task.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            const Icon(Icons.task_alt_rounded, color: AppColors.blue, size: 17),
            const SizedBox(width: 7),
            Text(
              '$completed of ${tasks.length} completed today',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _FeatureHighlights extends StatelessWidget {
  const _FeatureHighlights();

  static const _items = <_FeatureItem>[
    _FeatureItem('Student Discounts', '🎟️', <Color>[
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
    ], '/shop'),
    _FeatureItem('Budget Planner', '💰', <Color>[
      Color(0xFF34D399),
      Color(0xFF0D9488),
    ], '/budget'),
    _FeatureItem('Career Hub', '💼', <Color>[
      Color(0xFF8B5CF6),
      Color(0xFF7C3AED),
    ], '/career'),
    _FeatureItem('Food Deals', '🍕', <Color>[
      Color(0xFFFB923C),
      Color(0xFFF43F5E),
    ], '/food'),
    _FeatureItem('Marketplace', '🛍️', <Color>[
      Color(0xFFF472B6),
      Color(0xFFD946EF),
    ], '/marketplace'),
    _FeatureItem('Tuition', '📚', <Color>[
      Color(0xFF22D3EE),
      Color(0xFF2563EB),
    ], '/tuition'),
    _FeatureItem('Buy & Sell', '🔄', <Color>[
      Color(0xFFFBBF24),
      Color(0xFFF97316),
    ], '/buy-sell'),
    _FeatureItem('Events', '🎉', <Color>[
      Color(0xFFFB7185),
      Color(0xFFEC4899),
    ], '/events'),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 124,
    child: ListView.separated(
      key: const PageStorageKey<String>('home-feature-highlights-scroll'),
      clipBehavior: Clip.hardEdge,
      primary: false,
      scrollDirection: Axis.horizontal,
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 11),
      itemBuilder: (context, index) {
        final item = _items[index];
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _open(context, item.route),
            child: Ink(
              width: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: item.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(item.emoji, style: const TextStyle(fontSize: 31)),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  static void _open(BuildContext context, String route) {
    switch (route) {
      case '/career':
      case '/food':
      case '/shop':
        context.go(route);
      default:
        context.push(route);
    }
  }
}

class _HorizontalCatalog extends ConsumerWidget {
  const _HorizontalCatalog({
    required this.items,
    required this.kind,
    this.showFavorite = false,
  });

  final List<CatalogItem> items;
  final String kind;
  final bool showFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    return SizedBox(
      height: 228,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: 166,
            child: AppCard(
              padding: const EdgeInsets.all(12),
              radius: 22,
              onTap: () => context.push('/details/$kind/${item.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                      EmojiTile(
                        emoji: item.emoji,
                        background: item.background,
                        size: 142,
                        emojiSize: 45,
                      ),
                      if (item.badge != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: BadgeLabel(
                            item.badge!,
                            color: kind == 'restaurant'
                                ? AppColors.coral
                                : AppColors.blue,
                          ),
                        ),
                      if (showFavorite)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surface,
                              minimumSize: const Size(32, 32),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => ref
                                .read(favoritesProvider.notifier)
                                .toggle(item.id),
                            icon: Icon(
                              favorites.contains(item.id)
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: favorites.contains(item.id)
                                  ? AppColors.danger
                                  : AppColors.muted,
                              size: 17,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          item.price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: kind == 'restaurant'
                                ? AppColors.coral
                                : AppColors.blue,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (item.rating != null) RatingLabel(item.rating!),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeatureItem {
  const _FeatureItem(this.label, this.emoji, this.colors, this.route);

  final String label;
  final String emoji;
  final List<Color> colors;
  final String route;
}

String _digits(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) buffer.write(',');
    buffer.write(raw[i]);
  }
  return buffer.toString();
}
