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
import 'package:studentos/features/commerce/commerce_widgets.dart';
import 'package:studentos/state/favorites_controller.dart';
import 'package:studentos/state/registrations_controller.dart';

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({required this.kind, required this.id, super.key});

  final String kind;
  final String id;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  var _actionCompleted = false;
  var _quantity = 1;
  CatalogItem? _product;
  List<String> _productFeatures = const <String>[];
  var _loadingProduct = false;

  @override
  void initState() {
    super.initState();
    if (widget.kind == 'product') _loadProduct();
  }

  @override
  void didUpdateWidget(covariant DetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.kind == 'product' && widget.id != oldWidget.id) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    setState(() => _loadingProduct = true);
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      '${Api.productDomainProducts}/${widget.id}',
    );
    final body = response.data;
    if (!mounted) return;

    if (response.isSuccess &&
        body is Map<String, dynamic> &&
        body['data'] is Map<String, dynamic>) {
      final data = body['data'] as Map<String, dynamic>;
      setState(() {
        _product = _productFrom(data);
        _productFeatures = _stringsFrom(data['features_arr']);
      });
    }

    if (mounted) setState(() => _loadingProduct = false);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.kind == 'product'
        ? _product
        : findCatalogItem(widget.kind, widget.id);
    if (_loadingProduct && item == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_titleFor(widget.kind))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.notFound)),
        body: const EmptyState(
          emoji: '🔎',
          title: 'Item not found',
          message: 'The requested StudentOS item is unavailable.',
        ),
      );
    }
    final favorites = ref.watch(favoritesProvider);
    final favorite = favorites.contains(item.id);
    final eventRegistered = ref.watch(registrationsProvider).contains(item.id);
    final actionComplete = widget.kind == 'event'
        ? eventRegistered
        : _actionCompleted;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(widget.kind)),
        actions: <Widget>[
          if (<String>{
            'product',
            'marketplace',
            'course',
            'restaurant',
            'food',
          }.contains(widget.kind))
            IconButton(
              tooltip: favorite ? 'Remove from wishlist' : 'Add to wishlist',
              onPressed: () =>
                  ref.read(favoritesProvider.notifier).toggle(item.id),
              icon: Icon(
                favorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: favorite ? AppColors.danger : null,
              ),
            ),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share sheet would open here')),
            ),
            icon: const Icon(Icons.share_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      bottomNavigationBar: _isCartItem(widget.kind)
          ? SafeArea(
              minimum: AppSizes.bottomActionInsets,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _performAction(context, item),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accentFor(widget.kind),
                        minimumSize: const Size.fromHeight(
                          AppSizes.bottomActionHeight,
                        ),
                      ),
                      child: Text(
                        actionComplete ? 'Added to Cart' : 'Add to Cart',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.gapSm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        _addProductToCart(item, checkout: true);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        minimumSize: const Size.fromHeight(
                          AppSizes.bottomActionHeight,
                        ),
                      ),
                      child: Text('Buy Now · ${item.price}'),
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              minimum: AppSizes.bottomActionInsets,
              child: FilledButton.icon(
                onPressed: actionComplete
                    ? null
                    : () => _performAction(context, item),
                style: FilledButton.styleFrom(
                  backgroundColor: _accentFor(widget.kind),
                  minimumSize: const Size.fromHeight(
                    AppSizes.bottomActionHeight,
                  ),
                ),
                icon: Icon(
                  actionComplete
                      ? Icons.check_circle_outline_rounded
                      : _actionIcon(widget.kind),
                ),
                label: Text(
                  actionComplete
                      ? _completedLabel(widget.kind)
                      : _actionLabel(widget.kind, item),
                ),
              ),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          Container(
            height: 224,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: item.background,
              borderRadius: BorderRadius.circular(30),
            ),
            alignment: Alignment.center,
            child: item.imageUrl == null || item.imageUrl!.isEmpty
                ? Text(item.emoji, style: const TextStyle(fontSize: 96))
                : Image.network(
                    item.imageUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Text(item.emoji, style: const TextStyle(fontSize: 96)),
                  ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (item.badge != null)
                BadgeLabel(item.badge!, color: _accentFor(widget.kind)),
              if (item.rating != null) RatingLabel(item.rating!),
              if (item.location != null)
                BadgeLabel(item.location!, color: AppColors.greenDark),
            ],
          ),
          const SizedBox(height: 12),
          Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                item.price,
                style: TextStyle(
                  color: _accentFor(widget.kind),
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (item.originalPrice != null) ...<Widget>[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    item.originalPrice!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (item.meta != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              item.meta!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (_isCartItem(widget.kind)) ...<Widget>[
            AppCard(
              child: Row(
                children: <Widget>[
                  const Text(
                    'Quantity',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  QuantityStepper(
                    value: _quantity,
                    onChanged: (value) =>
                        setState(() => _quantity = value.clamp(1, 99)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.gapLg),
          ],
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _descriptionTitle(widget.kind),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _informationTitle(widget.kind),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...<Widget>[
                  ..._facts(widget.kind, item).map(
                    (fact) => _FactRow(
                      icon: fact.$1,
                      text: fact.$2,
                      color: _accentFor(widget.kind),
                    ),
                  ),
                  if (widget.kind == 'product')
                    ..._productFeatures.map(
                      (feature) => _FactRow(
                        icon: Icons.check_circle_outline_rounded,
                        text: feature,
                        color: _accentFor(widget.kind),
                      ),
                    ),
                ].map(
                  (fact) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: fact,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const AppCard(
            color: AppColors.blueSoft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.verified_user_outlined, color: AppColors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Prototype interaction: eligibility, inventory, payment, employer, tutor, seller, and registration data must be verified by production services before launch.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.45,
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

  CatalogItem _productFrom(Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? '';
    final price = _asInt(data['sale_price']) ?? _asInt(data['price']) ?? 0;
    final originalPrice = _asInt(data['price']);
    final discount = _asInt(data['discount']) ?? 0;
    final categories = _stringsFrom(data['categories_title_arr']);
    final images = _stringsFrom(data['large_images_arr']);
    return CatalogItem(
      id: data['id']?.toString() ?? data['slug']?.toString() ?? title,
      slug: data['slug']?.toString(),
      title: title,
      subtitle: categories.isEmpty ? 'Product' : categories.first.toString(),
      emoji: '🛍️',
      imageUrl: images.firstOrNull ?? data['small_image']?.toString(),
      price: _money(price),
      originalPrice: discount > 0 && originalPrice != null
          ? _money(originalPrice)
          : null,
      badge: discount > 0 ? '$discount% OFF' : null,
      rating: _asDouble(data['rating']),
      category: categories.isEmpty ? 'All' : categories.first.toString(),
      description: _stripHtml(data['description']?.toString() ?? ''),
      background: AppColors.purpleSoft,
    );
  }

  List<String> _stringsFrom(Object? source) {
    if (source is! List) return const <String>[];
    return source
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String _stripHtml(String value) => value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .trim();

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

  Future<void> _addProductToCart(
    CatalogItem item, {
    bool checkout = false,
  }) async {
    final error = await ref
        .read(cartProvider.notifier)
        .addProduct(item.id, _quantity);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _actionCompleted = true);
    if (checkout) {
      context.push('/checkout');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_snackMessage(widget.kind, item))));
    }
  }

  void _performAction(BuildContext context, CatalogItem item) {
    if (widget.kind == 'event') {
      ref.read(registrationsProvider.notifier).register(item.id);
    } else if (widget.kind == 'product') {
      _addProductToCart(item);
      return;
    } else if (_isCartItem(widget.kind)) {
      ref.read(cartProvider.notifier).add(item.id, _quantity);
      setState(() => _actionCompleted = true);
    } else {
      setState(() => _actionCompleted = true);
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_snackMessage(widget.kind, item))));
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Icon(icon, size: 19, color: color),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
    ],
  );
}

String _titleFor(String kind) => switch (kind) {
  'job' => 'Internship Details',
  'course' => 'Course Details',
  'food' => 'Dish Details',
  'restaurant' => 'Restaurant Deal',
  'product' => 'Product Details',
  'marketplace' => 'Marketplace Deal',
  'buysell' => 'Listing Details',
  'tuition' => 'Tuition Details',
  'event' => 'Event Details',
  _ => 'Details',
};

Color _accentFor(String kind) => switch (kind) {
  'food' || 'restaurant' => AppColors.coral,
  'course' || 'job' => AppColors.purple,
  'event' => AppColors.teal,
  'buysell' => AppColors.pink,
  'tuition' => AppColors.teal,
  'marketplace' => AppColors.orange,
  _ => AppColors.blue,
};

bool _isCartItem(String kind) =>
    <String>{'food', 'product', 'marketplace'}.contains(kind);

IconData _actionIcon(String kind) => switch (kind) {
  'job' || 'tuition' => Icons.send_outlined,
  'course' => Icons.school_outlined,
  'food' || 'restaurant' => Icons.shopping_bag_outlined,
  'product' || 'marketplace' => Icons.add_shopping_cart_rounded,
  'buysell' => Icons.chat_bubble_outline_rounded,
  'event' => Icons.event_available_outlined,
  _ => Icons.check_rounded,
};

String _actionLabel(String kind, CatalogItem item) => switch (kind) {
  'job' || 'tuition' => 'Apply Now',
  'course' => 'Enroll · ${item.price}',
  'food' => 'Add to Cart · ${item.price}',
  'restaurant' => 'Claim Student Deal',
  'product' || 'marketplace' => 'Add to Cart · ${item.price}',
  'buysell' => 'Contact Seller',
  'event' => 'Register Now',
  _ => 'Continue',
};

String _completedLabel(String kind) => switch (kind) {
  'job' || 'tuition' => 'Application Started',
  'course' => 'Enrolled',
  'food' || 'product' || 'marketplace' => 'Added to Cart',
  'restaurant' => 'Deal Saved',
  'buysell' => 'Seller Contacted',
  'event' => 'Registered',
  _ => 'Completed',
};

String _descriptionTitle(String kind) => switch (kind) {
  'job' => 'About the role',
  'course' => 'About this course',
  'food' || 'restaurant' => 'About this offer',
  'tuition' => 'About this tuition',
  'event' => 'About this event',
  'buysell' => 'Seller description',
  _ => 'Product description',
};

String _informationTitle(String kind) => switch (kind) {
  'job' => 'Role information',
  'course' => 'What you will get',
  'food' || 'restaurant' => 'Order information',
  'tuition' => 'Tuition information',
  'event' => 'Event information',
  'buysell' => 'Listing information',
  _ => 'Purchase information',
};

List<(IconData, String)> _facts(
  String kind,
  CatalogItem item,
) => switch (kind) {
  'job' => <(IconData, String)>[
    (Icons.location_on_outlined, item.location ?? 'Location to be confirmed'),
    (Icons.schedule_outlined, item.badge ?? 'Schedule to be confirmed'),
    (Icons.payments_outlined, item.price),
    (
      Icons.verified_outlined,
      'Employer verification required before production applications are submitted.',
    ),
  ],
  'course' => <(IconData, String)>[
    (
      Icons.play_circle_outline_rounded,
      'Self-paced lessons and project exercises',
    ),
    (
      Icons.workspace_premium_outlined,
      'Certificate information shown by the provider',
    ),
    (Icons.devices_outlined, 'Mobile and desktop access'),
    (
      Icons.mail_outline_rounded,
      'Access instructions delivered after verified enrollment',
    ),
  ],
  'food' || 'restaurant' => <(IconData, String)>[
    (Icons.schedule_outlined, item.meta ?? 'Delivery time shown at checkout'),
    (Icons.local_offer_outlined, item.badge ?? 'Student offer'),
    (
      Icons.location_on_outlined,
      'Delivery availability depends on the selected address',
    ),
    (
      Icons.receipt_long_outlined,
      'Final price and fees must be confirmed before checkout',
    ),
  ],
  'tuition' => <(IconData, String)>[
    (Icons.location_on_outlined, item.location ?? 'Location unavailable'),
    (Icons.school_outlined, item.subtitle),
    (Icons.schedule_outlined, item.badge ?? 'Schedule to be arranged'),
    (Icons.payments_outlined, item.price),
  ],
  'event' => <(IconData, String)>[
    (Icons.calendar_today_outlined, item.meta ?? 'Date to be confirmed'),
    (Icons.location_on_outlined, item.location ?? 'Venue to be confirmed'),
    (Icons.confirmation_number_outlined, item.price),
    (Icons.groups_outlined, item.subtitle),
  ],
  'buysell' => <(IconData, String)>[
    (Icons.person_outline_rounded, item.subtitle),
    (
      Icons.location_on_outlined,
      item.location ?? 'Meet-up location to be arranged',
    ),
    (Icons.inventory_2_outlined, item.badge ?? 'Condition not specified'),
    (
      Icons.security_outlined,
      'Inspect the item and use safe public meet-up practices.',
    ),
  ],
  _ => <(IconData, String)>[
    (Icons.local_offer_outlined, item.badge ?? 'Student pricing'),
    (Icons.storefront_outlined, item.subtitle),
    (
      Icons.inventory_2_outlined,
      'Inventory and delivery are confirmed at checkout',
    ),
    (
      Icons.verified_outlined,
      'Seller and offer verification required for production',
    ),
  ],
};

String _snackMessage(String kind, CatalogItem item) => switch (kind) {
  'job' || 'tuition' => 'Application flow started for ${item.title}',
  'course' => 'Enrollment flow started for ${item.title}',
  'food' || 'product' || 'marketplace' => '${item.title} added to cart',
  'restaurant' => '${item.title} deal saved',
  'buysell' => 'Contact flow started for ${item.title}',
  'event' => 'Registered for ${item.title}',
  _ => 'Action completed',
};
