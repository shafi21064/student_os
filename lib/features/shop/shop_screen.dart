import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studentos/core/constants/app_strings.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/theme/app_sizes.dart';
import 'package:studentos/core/widgets/app_card.dart';
import 'package:studentos/core/widgets/common_widgets.dart';
import 'package:studentos/data/demo_data.dart';
import 'package:studentos/data/models.dart';
import 'package:studentos/state/favorites_controller.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String _category = 'All';
  String _query = '';
  bool _priceAscending = true;

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final filtered = shopProducts.where((item) {
      final categoryMatches = _category == 'All' || item.category == _category;
      final queryMatches =
          _query.isEmpty ||
          item.title.toLowerCase().contains(_query.toLowerCase());
      return categoryMatches && queryMatches;
    }).toList();
    if (!_priceAscending) filtered.reversed;

    return CustomScrollView(
      key: const PageStorageKey<String>('shop-scroll'),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Shop',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: AppStrings.sortProducts,
                      onPressed: () =>
                          setState(() => _priceAscending = !_priceAscending),
                      icon: Icon(
                        _priceAscending
                            ? Icons.sort_rounded
                            : Icons.swap_vert_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: AppStrings.searchProducts,
                  ),
                ),
                const SizedBox(height: 14),
                const _ShopPromo(),
                const SizedBox(height: 14),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: shopCategories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = shopCategories[index];
                      return ChoiceChip(
                        label: Text(category),
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        if (filtered.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              emoji: '🛍️',
              title: 'No products found',
              message: 'Try another category or search term.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid.builder(
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .58,
              ),
              itemBuilder: (context, index) {
                final item = filtered[index];
                return _ProductCard(
                  item: item,
                  favorite: favorites.contains(item.id),
                  onFavorite: () =>
                      ref.read(favoritesProvider.notifier).toggle(item.id),
                  onTap: () => context.push('/details/product/${item.id}'),
                  onBuy: () {
                    ref.read(cartProvider.notifier).add(item.id);
                    context.push('/checkout');
                  },
                  onCart: () {
                    ref.read(cartProvider.notifier).add(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.title} added to cart')),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ShopPromo extends StatelessWidget {
  const _ShopPromo();

  @override
  Widget build(BuildContext context) => Container(
    height: 155,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: <Color>[AppColors.brand, AppColors.accent],
      ),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Student Exclusive',
              style: TextStyle(
                color: AppColors.blueSoft,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(
              'Up to 70% OFF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'On electronics & accessories',
              style: TextStyle(color: AppColors.blueSoft, fontSize: 12),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.blue,
                minimumSize: const Size(92, 32),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Text('Shop Now'),
            ),
          ],
        ),
        const Text('🛍️', style: TextStyle(fontSize: 66)),
      ],
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.item,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
    required this.onBuy,
    required this.onCart,
  });

  final CatalogItem item;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;
  final VoidCallback onBuy;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(11),
    radius: 21,
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: item.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(item.emoji, style: const TextStyle(fontSize: 49)),
              ),
              const Positioned(top: 8, left: 8, child: BadgeLabel('Student')),
              Positioned(
                top: 5,
                right: 5,
                child: IconButton.filled(
                  onPressed: onFavorite,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    minimumSize: const Size(34, 34),
                    padding: EdgeInsets.zero,
                  ),
                  icon: Icon(
                    favorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: favorite ? AppColors.danger : AppColors.muted,
                  ),
                ),
              ),
              if (item.rating != null)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: RatingLabel(item.rating!),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                item.price,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
            if (item.badge != null)
              BadgeLabel(item.badge!, color: AppColors.danger),
          ],
        ),
        if (item.originalPrice != null)
          Text(
            item.originalPrice!,
            style: TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        const SizedBox(height: AppSizes.gapXs),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton(
                onPressed: onBuy,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  minimumSize: const Size.fromHeight(42),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text('Buy'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: onCart,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.purple,
                  side: const BorderSide(color: AppColors.purple, width: 1.7),
                  minimumSize: const Size.fromHeight(42),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Icon(Icons.shopping_cart_outlined, size: 21),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
