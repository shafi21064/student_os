import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/widgets/app_card.dart';
import 'package:studentos/core/widgets/common_widgets.dart';
import 'package:studentos/data/demo_data.dart';
import 'package:studentos/data/models.dart';
import 'package:studentos/state/favorites_controller.dart';

class FoodScreen extends ConsumerStatefulWidget {
  const FoodScreen({super.key});

  @override
  ConsumerState<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends ConsumerState<FoodScreen> {
  String _cuisine = 'All';
  String _restaurant = 'All';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final restaurantOptions = <String>['All', ...{for (final item in foodDishes) item.subtitle}];
    final filtered = foodDishes.where((item) {
      final cuisineMatches = _cuisine == 'All' || item.category == _cuisine;
      final restaurantMatches = _restaurant == 'All' || item.subtitle == _restaurant;
      final queryMatches = _query.isEmpty || item.title.toLowerCase().contains(_query.toLowerCase());
      return cuisineMatches && restaurantMatches && queryMatches;
    }).toList();

    return CustomScrollView(
      key: const PageStorageKey<String>('food-scroll'),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Order Food 🍕', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        onChanged: (value) => setState(() => _query = value),
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search dishes...'),
                      ),
                    ),
                    const SizedBox(width: 9),
                    PopupMenuButton<String>(
                      initialValue: _restaurant,
                      onSelected: (value) => setState(() => _restaurant = value),
                      itemBuilder: (_) => restaurantOptions.map((item) => PopupMenuItem<String>(value: item, child: Text(item))).toList(),
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        decoration: BoxDecoration(
                          color: _restaurant == 'All' ? Theme.of(context).colorScheme.surface : AppColors.coral,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _restaurant == 'All' ? Theme.of(context).colorScheme.outlineVariant : AppColors.coral),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text('🍽️'),
                            const SizedBox(width: 6),
                            Text(_restaurant == 'All' ? 'Restaurant' : _restaurant.split(' ').first, style: TextStyle(color: _restaurant == 'All' ? null : Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                            Icon(Icons.expand_more_rounded, size: 17, color: _restaurant == 'All' ? null : Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: cuisines.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = cuisines[index];
                      return ChoiceChip(
                        label: Text(item),
                        selected: _cuisine == item,
                        selectedColor: AppColors.coral.withValues(alpha: .18),
                        labelStyle: TextStyle(color: _cuisine == item ? AppColors.coral : null),
                        onSelected: (_) => setState(() => _cuisine = item),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                const _FoodPromo(),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(child: Text('${filtered.length} dishes available', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700, fontSize: 12))),
                    if (_cuisine != 'All' || _restaurant != 'All' || _query.isNotEmpty)
                      TextButton(onPressed: () => setState(() { _cuisine = 'All'; _restaurant = 'All'; _query = ''; }), child: const Text('Clear')),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (filtered.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: EmptyState(emoji: '🍽️', title: 'No dishes found', message: 'Try a different filter.'))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid.builder(
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .66),
              itemBuilder: (context, index) => _DishCard(item: filtered[index]),
            ),
          ),
      ],
    );
  }
}

class _FoodPromo extends StatelessWidget {
  const _FoodPromo();

  @override
  Widget build(BuildContext context) => Container(
        height: 88,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: <Color>[AppColors.coral, Color(0xFFF43F5E)]), borderRadius: BorderRadius.circular(22)),
        child: const Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Today Only', style: TextStyle(color: Color(0xFFFFEDD5), fontSize: 10, fontWeight: FontWeight.w700)),
                  Text('Free Delivery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  Text('On orders above ৳200', style: TextStyle(color: Color(0xFFFFEDD5), fontSize: 11)),
                ],
              ),
            ),
            Text('🛵', style: TextStyle(fontSize: 50)),
          ],
        ),
      );
}

class _DishCard extends ConsumerWidget {
  const _DishCard({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppCard(
        padding: EdgeInsets.zero,
        radius: 21,
        onTap: () => context.push('/details/food/${item.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(color: item.background, borderRadius: const BorderRadius.vertical(top: Radius.circular(21))),
                    alignment: Alignment.center,
                    child: Text(item.emoji, style: const TextStyle(fontSize: 48)),
                  ),
                  if (item.badge != null) Positioned(top: 8, left: 8, child: BadgeLabel('🔥 ${item.badge}', color: AppColors.danger)),
                  if (item.rating != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withValues(alpha: .92), borderRadius: BorderRadius.circular(999)),
                        child: RatingLabel(item.rating!),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10)),
                  const SizedBox(height: 7),
                  Row(
                    children: <Widget>[
                      Expanded(child: Text(item.price, style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w900, fontSize: 13))),
                      if (item.meta != null) Text('◷ ${item.meta}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 7),
                  FilledButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).add(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.title} added to cart')));
                    },
                    style: FilledButton.styleFrom(backgroundColor: AppColors.coral, minimumSize: const Size.fromHeight(36), padding: const EdgeInsets.symmetric(horizontal: 8)),
                    child: const Text('Add to Cart'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
