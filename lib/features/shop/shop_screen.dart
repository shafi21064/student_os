import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studentos/core/api/api.dart';
import 'package:studentos/core/api/api_client.dart';
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
  static const _allCategory = _ShopCategory(title: 'All');
  static const _sortOptions = <_SortOption>[
    _SortOption(value: 'newest', label: 'Newest'),
    _SortOption(value: 'expensive', label: 'Price high to low'),
    _SortOption(value: 'best_seller', label: 'Best seller'),
    _SortOption(value: 'inexpensive', label: 'Price low to high'),
    _SortOption(value: 'best_rates', label: 'Best rates'),
  ];

  final _scrollController = ScrollController();
  String _query = '';
  String _sortBy = 'newest';
  List<_ShopCategory> _categories = const <_ShopCategory>[_allCategory];
  _ShopCategory _category = _allCategory;
  List<CatalogItem> _products = const <CatalogItem>[];
  Timer? _searchDebounce;
  var _currentPage = 1;
  var _lastPage = 1;
  var _loading = false;
  var _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreIfNeeded);
    _loadCategories();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController
      ..removeListener(_loadMoreIfNeeded)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      Api.productCategories,
    );
    final body = response.data;
    if (!mounted || !response.isSuccess || body is! Map<String, dynamic>) {
      return;
    }

    final data = body['data'];
    if (data is! List) return;

    final categories = data
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => _ShopCategory(
            title: item['title']?.toString().trim() ?? '',
            slug: item['slug']?.toString().trim(),
          ),
        )
        .where((category) => category.title.isNotEmpty)
        .toList(growable: false);

    setState(() {
      _categories = <_ShopCategory>[
        _allCategory,
        ..._dedupeCategories(categories),
      ];
      if (!_categories.any((item) => item.title == _category.title)) {
        _category = _allCategory;
      }
    });
  }

  Future<void> _loadProducts({bool loadMore = false}) async {
    if (_loading || _loadingMore) return;
    final page = loadMore ? _currentPage + 1 : 1;
    if (loadMore && page > _lastPage) return;

    setState(() {
      if (loadMore) {
        _loadingMore = true;
      } else {
        _loading = true;
      }
    });

    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      Api.productDomainProducts,
      queryParameters: <String, dynamic>{
        'page': page,
        'sort_by': _sortBy,
        if (_query.trim().isNotEmpty) 'search': _query.trim(),
        if (_category.slug?.isNotEmpty ?? false)
          'product_category_slug': _category.slug,
      },
    );
    final body = response.data;

    if (!mounted) return;
    if (response.isSuccess && body is Map<String, dynamic>) {
      final products = _productsFrom(body['data']);
      final meta = body['meta'];
      setState(() {
        _currentPage =
            _asInt(
              meta is Map<String, dynamic> ? meta['current_page'] : null,
            ) ??
            page;
        _lastPage =
            _asInt(meta is Map<String, dynamic> ? meta['last_page'] : null) ??
            page;
        _products = loadMore
            ? <CatalogItem>[..._products, ...products]
            : List<CatalogItem>.unmodifiable(products);
      });
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadingMore = false;
    });
  }

  void _loadMoreIfNeeded() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      _loadProducts(loadMore: true);
    }
  }

  void _selectCategory(_ShopCategory category) {
    setState(() => _category = category);
    _loadProducts();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _loadProducts(),
    );
  }

  void _selectSort(String? value) {
    if (value == null || value == _sortBy) return;
    setState(() => _sortBy = value);
    _loadProducts();
  }

  List<_ShopCategory> _dedupeCategories(List<_ShopCategory> categories) {
    final seen = <String>{};
    return categories
        .where((category) {
          final key = category.slug?.isNotEmpty == true
              ? category.slug!
              : category.title.toLowerCase();
          return seen.add(key);
        })
        .toList(growable: false);
  }

  List<CatalogItem> _productsFrom(Object? source) {
    if (source is! List) return const <CatalogItem>[];
    return source
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final title = item['title']?.toString() ?? '';
          final price =
              _asInt(item['sale_price']) ?? _asInt(item['price']) ?? 0;
          final originalPrice = _asInt(item['price']);
          final discount = _asInt(item['discount']) ?? 0;
          final categories = item['categories_title_arr'];
          return CatalogItem(
            id: item['id']?.toString() ?? item['slug']?.toString() ?? title,
            slug: item['slug']?.toString(),
            title: title,
            subtitle: categories is List && categories.isNotEmpty
                ? categories.first.toString()
                : 'Product',
            emoji: '🛍️',
            imageUrl: item['small_image']?.toString(),
            price: _money(price),
            originalPrice: discount > 0 && originalPrice != null
                ? _money(originalPrice)
                : null,
            badge: discount > 0 ? '$discount% OFF' : null,
            rating: _asDouble(item['rating']),
            category: categories is List && categories.isNotEmpty
                ? categories.first.toString()
                : 'All',
            background: AppColors.purpleSoft,
          );
        })
        .where((item) => item.title.isNotEmpty)
        .toList(growable: false);
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  String _money(int value) {
    final raw = value.toString();
    final buffer = StringBuffer('৳');
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write(',');
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);

    return CustomScrollView(
      key: const PageStorageKey<String>('shop-scroll'),
      controller: _scrollController,
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
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          borderRadius: BorderRadius.circular(14),
                          onChanged: _selectSort,
                          items: _sortOptions
                              .map(
                                (option) => DropdownMenuItem<String>(
                                  value: option.value,
                                  child: Text(option.label),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: _onSearchChanged,
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
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return ChoiceChip(
                        label: Text(category.title),
                        selected: _category.title == category.title,
                        onSelected: (_) => _selectCategory(category),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        if (_loading && _products.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid.builder(
              itemCount: 6,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .58,
              ),
              itemBuilder: (_, _) => const _ProductSkeletonCard(),
            ),
          )
        else if (_products.isEmpty)
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
              itemCount: _products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .58,
              ),
              itemBuilder: (context, index) {
                final item = _products[index];
                return _ProductCard(
                  item: item,
                  favorite: favorites.contains(item.id),
                  onFavorite: () =>
                      ref.read(favoritesProvider.notifier).toggle(item.id),
                  onTap: () =>
                      context.push('/details/product/${item.slug ?? item.id}'),
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
        if (_loadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _ShopCategory {
  const _ShopCategory({required this.title, this.slug});

  final String title;
  final String? slug;
}

class _SortOption {
  const _SortOption({required this.value, required this.label});

  final String value;
  final String label;
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
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: item.imageUrl == null || item.imageUrl!.isEmpty
                    ? ColoredBox(
                        color: item.background,
                        child: Center(
                          child: Text(
                            item.emoji,
                            style: const TextStyle(fontSize: 49),
                          ),
                        ),
                      )
                    : Image.network(
                        item.imageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: item.background,
                          child: Center(
                            child: Text(
                              item.emoji,
                              style: const TextStyle(fontSize: 49),
                            ),
                          ),
                        ),
                      ),
              ),
              // const Positioned(top: 8, left: 8, child: BadgeLabel('Student')),
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

class _ProductSkeletonCard extends StatelessWidget {
  const _ProductSkeletonCard();

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(11),
    radius: 21,
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: _ShimmerBlock(radius: 16)),
        SizedBox(height: 9),
        _ShimmerBlock(height: 14, radius: 7),
        SizedBox(height: 8),
        _ShimmerBlock(width: 78, height: 14, radius: 7),
        SizedBox(height: AppSizes.gapXs),
        Row(
          children: <Widget>[
            Expanded(child: _ShimmerBlock(height: 42, radius: 18)),
            SizedBox(width: 8),
            Expanded(child: _ShimmerBlock(height: 42, radius: 18)),
          ],
        ),
      ],
    ),
  );
}

class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock({this.width, this.height, required this.radius});

  final double? width;
  final double? height;
  final double radius;

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final base = Theme.of(context).colorScheme.surfaceContainerHighest;
      final shine = Theme.of(context).colorScheme.surface;
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1 + _controller.value * 2, 0),
            end: Alignment(1 + _controller.value * 2, 0),
            colors: <Color>[base, shine, base],
          ),
        ),
      );
    },
  );
}
