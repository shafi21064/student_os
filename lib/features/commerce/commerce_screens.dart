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
import 'package:studentos/features/auth/data/auth_controller.dart';
import 'package:studentos/features/commerce/commerce_widgets.dart';
import 'package:studentos/state/favorites_controller.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  List<_CartLine> _lines = const <_CartLine>[];
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      Api.productDomainCart,
    );
    final body = response.data;
    if (!mounted) return;

    if (response.isSuccess &&
        body is Map<String, dynamic> &&
        body['data'] is Map<String, dynamic>) {
      final data = body['data'] as Map<String, dynamic>;
      setState(() => _lines = _cartLinesFrom(data['cart_items']));
    } else {
      setState(() {
        _error = body is Map<String, dynamic>
            ? body['message']?.toString() ?? 'Cart fetch failed.'
            : response.message ?? 'Cart fetch failed.';
      });
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final lines = _lines;
    final total = _total(lines);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.yourCart)),
      bottomNavigationBar: lines.isEmpty
          ? null
          : SafeArea(
              minimum: AppSizes.bottomActionInsets,
              child: FilledButton(
                onPressed: () => context.push('/checkout'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  minimumSize: const Size.fromHeight(
                    AppSizes.bottomActionHeight,
                  ),
                ),
                child: Text('Buy All · ৳${_money(total)}'),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? EmptyState(emoji: '🛒', title: 'Cart unavailable', message: _error!)
          : lines.isEmpty
          ? const EmptyState(
              emoji: '🛒',
              title: 'Your cart is empty',
              message: 'Add products, deals, or food before checkout.',
            )
          : ListView(
              padding: AppSizes.listPadding,
              children: <Widget>[
                const SecureCheckoutCard(
                  message:
                      'Secure cart. Student discount is applied at checkout.',
                ),
                const SizedBox(height: AppSizes.gapLg),
                ...lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.gapMd),
                    child: AppCard(
                      child: Row(
                        children: <Widget>[
                          _CartItemImage(item: line.item),
                          const SizedBox(width: AppSizes.gapMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  line.item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  line.item.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  '${line.item.price} × ${line.quantity}',
                                  style: const TextStyle(
                                    color: AppColors.blue,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '৳${_money(line.total)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _address = TextEditingController();
  final _note = TextEditingController();
  var _payment = 'StudentOS Pay';
  var _pickup = false;

  @override
  void dispose() {
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = _cartLines(ref.watch(cartProvider));
    final user = ref.watch(authProvider).user;
    final subtotal = _total(lines);
    final discount = (subtotal * .08).round().clamp(0, 500);
    final delivery = _pickup ? 0 : 45;
    final total = subtotal - discount + delivery;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.checkout)),
      bottomNavigationBar: lines.isEmpty
          ? null
          : SafeArea(
              minimum: AppSizes.bottomActionInsets,
              child: FilledButton(
                onPressed: () {
                  if (!_pickup && _address.text.trim().isEmpty) {
                    context.push('/purchase-result?status=failed');
                    return;
                  }
                  ref.read(cartProvider.notifier).clear();
                  context.go('/purchase-result?status=success');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  minimumSize: const Size.fromHeight(
                    AppSizes.bottomActionHeight,
                  ),
                ),
                child: Text('Place order · ৳${_money(total)}'),
              ),
            ),
      body: lines.isEmpty
          ? const EmptyState(
              emoji: '🛒',
              title: 'Nothing to checkout',
              message: 'Your cart is empty.',
            )
          : ListView(
              padding: AppSizes.listPadding,
              children: <Widget>[
                const SecureCheckoutCard(),
                const SizedBox(height: AppSizes.gapLg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AppStrings.contactDetails,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSizes.gapMd),
                      CommerceInfoRow(
                        label: AppStrings.name,
                        value: user?.name ?? AppStrings.student,
                      ),
                      CommerceInfoRow(
                        label: AppStrings.phone,
                        value: user?.mobile.isNotEmpty == true
                            ? user!.mobile
                            : AppStrings.notAdded,
                      ),
                      CommerceInfoRow(
                        label: AppStrings.campus,
                        value: user?.university.isNotEmpty == true
                            ? user!.university
                            : AppStrings.notAdded,
                      ),
                      const SizedBox(height: AppSizes.gapSm),
                      TextField(
                        controller: _address,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Delivery address',
                        ),
                      ),
                      const SizedBox(height: AppSizes.gapSm),
                      TextField(
                        controller: _note,
                        decoration: const InputDecoration(
                          labelText: 'Notes for delivery',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.gapLg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AppStrings.deliveryOptions,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _pickup,
                        onChanged: (value) => setState(() => _pickup = value),
                        title: const Text(AppStrings.campusPickup),
                        subtitle: const Text(AppStrings.noDeliveryFee),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.gapLg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AppStrings.paymentMethod,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSizes.gapSm),
                      ...<String>['StudentOS Pay', 'bKash', 'Card'].map(
                        (method) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () => setState(() => _payment = method),
                          title: Text(method),
                          trailing: _payment == method
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.purple,
                                )
                              : const Icon(Icons.circle_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.gapLg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AppStrings.orderSummary,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSizes.gapMd),
                      ...lines.map(
                        (line) => CommerceInfoRow(
                          label: '${line.item.title} × ${line.quantity}',
                          value:
                              '৳${_money(_price(line.item.price) * line.quantity)}',
                        ),
                      ),
                      const Divider(height: 24),
                      CommerceInfoRow(
                        label: AppStrings.subtotal,
                        value: '৳${_money(subtotal)}',
                      ),
                      CommerceInfoRow(
                        label: AppStrings.studentDiscount,
                        value: '-৳${_money(discount)}',
                      ),
                      CommerceInfoRow(
                        label: AppStrings.delivery,
                        value: '৳${_money(delivery)}',
                      ),
                      const SizedBox(height: AppSizes.gapXs),
                      CommerceInfoRow(
                        label: AppStrings.total,
                        value: '৳${_money(total)}',
                        strong: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class PurchaseResultScreen extends StatelessWidget {
  const PurchaseResultScreen({required this.success, super.key});

  final bool success;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: (success ? AppColors.green : AppColors.danger)
                    .withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check_circle_rounded : Icons.error_rounded,
                size: 58,
                color: success ? AppColors.greenDark : AppColors.danger,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              success ? 'Purchase successful' : 'Purchase failed',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              success
                  ? 'Your order is confirmed. We will send updates to your phone shortly.'
                  : 'We could not place this order. Add a delivery address or try another payment method.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => context.go(success ? '/home' : '/checkout'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(success ? 'Back to Home' : 'Try Again'),
            ),
          ],
        ),
      ),
    ),
  );
}

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final items = allSearchableItems()
        .where((item) => favorites.contains(item.id))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.wishlist)),
      body: items.isEmpty
          ? const EmptyState(
              emoji: '💜',
              title: 'No wishlist items yet',
              message: 'Tap the heart icon on product, food, and deal pages.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 11),
              itemBuilder: (context, index) {
                final item = items[index];
                final kind = _kindFor(item);
                return CatalogListTile(
                  item: item,
                  onTap: () => context.push('/details/$kind/${item.id}'),
                  trailing: IconButton(
                    onPressed: () =>
                        ref.read(favoritesProvider.notifier).toggle(item.id),
                    icon: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.danger,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _CartLine {
  const _CartLine(this.item, this.quantity, {int? total}) : total = total ?? 0;

  final CatalogItem item;
  final int quantity;
  final int total;
}

List<_CartLine> _cartLines(Map<String, int> cart) => cart.entries
    .map((entry) {
      final item = _itemById(entry.key);
      return item == null
          ? null
          : _CartLine(
              item,
              entry.value,
              total: _price(item.price) * entry.value,
            );
    })
    .nonNulls
    .toList(growable: false);

List<_CartLine> _cartLinesFrom(Object? source) {
  if (source is! List) return const <_CartLine>[];
  return source
      .whereType<Map<String, dynamic>>()
      .map((row) {
        final product = row['product_data'];
        if (product is! Map<String, dynamic>) return null;
        final quantity = _asInt(row['quantity']) ?? 1;
        final unitPrice =
            _asInt(row['unit_price']) ?? _asInt(product['price']) ?? 0;
        final total = _asInt(row['net_price']) ?? unitPrice * quantity;
        final title = product['title']?.toString() ?? '';
        return _CartLine(
          CatalogItem(
            id:
                product['id']?.toString() ??
                row['product_id']?.toString() ??
                '',
            slug: product['slug']?.toString(),
            title: title,
            subtitle: 'Product',
            emoji: '🛍️',
            imageUrl: product['banner']?.toString(),
            price: '৳${_money(unitPrice)}',
            background: AppColors.purpleSoft,
          ),
          quantity,
          total: total,
        );
      })
      .nonNulls
      .where((line) => line.item.id.isNotEmpty && line.item.title.isNotEmpty)
      .toList(growable: false);
}

CatalogItem? _itemById(String id) {
  for (final item in allSearchableItems()) {
    if (item.id == id) return item;
  }
  return null;
}

int _total(List<_CartLine> lines) => lines.fold(
  0,
  (sum, line) =>
      sum +
      (line.total == 0 ? _price(line.item.price) * line.quantity : line.total),
);

int _price(String value) =>
    int.tryParse(value.replaceAll(RegExp(r'\D'), '')) ?? 0;

String _money(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) buffer.write(',');
    buffer.write(raw[i]);
  }
  return buffer.toString();
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '');
}

class _CartItemImage extends StatelessWidget {
  const _CartItemImage({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      width: 58,
      height: 58,
      child: item.imageUrl == null || item.imageUrl!.isEmpty
          ? EmojiTile(
              emoji: item.emoji,
              background: item.background,
              size: 58,
              emojiSize: 30,
            )
          : Image.network(
              item.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => EmojiTile(
                emoji: item.emoji,
                background: item.background,
                size: 58,
                emojiSize: 30,
              ),
            ),
    ),
  );
}

String _kindFor(CatalogItem item) {
  if (shopProducts.any((value) => value.id == item.id)) return 'product';
  if (marketplaceProducts.any((value) => value.id == item.id)) {
    return 'marketplace';
  }
  if (foodDishes.any((value) => value.id == item.id)) return 'food';
  if (restaurants.any((value) => value.id == item.id)) return 'restaurant';
  if (courses.any((value) => value.id == item.id)) return 'course';
  if (internships.any((value) => value.id == item.id)) return 'job';
  if (tuitionJobs.any((value) => value.id == item.id)) return 'tuition';
  if (buySellListings.any((value) => value.id == item.id)) return 'buysell';
  if (events.any((value) => value.id == item.id)) return 'event';
  return 'product';
}
