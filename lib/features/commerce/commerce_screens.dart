import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/widgets/app_card.dart';
import 'package:studentos/core/widgets/common_widgets.dart';
import 'package:studentos/data/demo_data.dart';
import 'package:studentos/data/models.dart';
import 'package:studentos/features/auth/data/auth_controller.dart';
import 'package:studentos/state/favorites_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = _cartLines(ref.watch(cartProvider));
    final total = _total(lines);
    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      bottomNavigationBar: lines.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: () => context.push('/checkout'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  minimumSize: const Size.fromHeight(54),
                ),
                child: Text('Buy All · ৳${_money(total)}'),
              ),
            ),
      body: lines.isEmpty
          ? const EmptyState(
              emoji: '🛒',
              title: 'Your cart is empty',
              message: 'Add products, deals, or food before checkout.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: <Widget>[
                const AppCard(
                  color: AppColors.purpleSoft,
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.lock_outline_rounded, color: AppColors.purple),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Secure cart. Student discount is applied at checkout.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ...lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: Row(
                        children: <Widget>[
                          EmojiTile(
                            emoji: line.item.emoji,
                            background: line.item.background,
                            size: 58,
                            emojiSize: 30,
                          ),
                          const SizedBox(width: 12),
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
                                  '৳${_money(_price(line.item.price))} × ${line.quantity}',
                                  style: const TextStyle(
                                    color: AppColors.blue,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: <Widget>[
                              _Stepper(
                                value: line.quantity,
                                onChanged: (value) => ref
                                    .read(cartProvider.notifier)
                                    .setQuantity(line.item.id, value),
                              ),
                              TextButton(
                                onPressed: () => ref
                                    .read(cartProvider.notifier)
                                    .setQuantity(line.item.id, 0),
                                child: const Text('Remove'),
                              ),
                            ],
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
      appBar: AppBar(title: const Text('Checkout')),
      bottomNavigationBar: lines.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                  minimumSize: const Size.fromHeight(54),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: <Widget>[
                const _SecureCheckoutCard(),
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Contact details',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(label: 'Name', value: user?.name ?? 'Student'),
                      _InfoRow(
                        label: 'Phone',
                        value: user?.mobile.isNotEmpty == true
                            ? user!.mobile
                            : 'Not added',
                      ),
                      _InfoRow(
                        label: 'Campus',
                        value: user?.university.isNotEmpty == true
                            ? user!.university
                            : 'Not added',
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _address,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Delivery address',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _note,
                        decoration: const InputDecoration(
                          labelText: 'Notes for delivery',
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
                        'Delivery options',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _pickup,
                        onChanged: (value) => setState(() => _pickup = value),
                        title: const Text('Campus pickup'),
                        subtitle: const Text('No delivery fee'),
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
                        'Payment method',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
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
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Order summary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ...lines.map(
                        (line) => _InfoRow(
                          label: '${line.item.title} × ${line.quantity}',
                          value:
                              '৳${_money(_price(line.item.price) * line.quantity)}',
                        ),
                      ),
                      const Divider(height: 24),
                      _InfoRow(
                        label: 'Subtotal',
                        value: '৳${_money(subtotal)}',
                      ),
                      _InfoRow(
                        label: 'Student discount',
                        value: '-৳${_money(discount)}',
                      ),
                      _InfoRow(
                        label: 'Delivery',
                        value: '৳${_money(delivery)}',
                      ),
                      const SizedBox(height: 6),
                      _InfoRow(
                        label: 'Total',
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
      appBar: AppBar(title: const Text('Wishlist')),
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

class _SecureCheckoutCard extends StatelessWidget {
  const _SecureCheckoutCard();

  @override
  Widget build(BuildContext context) => const AppCard(
    color: AppColors.purpleSoft,
    child: Row(
      children: <Widget>[
        Icon(Icons.shield_outlined, color: AppColors.purple),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Secure checkout with student discount protection.',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: strong
                  ? null
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          onPressed: () => onChanged(value - 1),
          icon: const Icon(Icons.remove_rounded),
          visualDensity: VisualDensity.compact,
        ),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w900)),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_rounded),
          visualDensity: VisualDensity.compact,
        ),
      ],
    ),
  );
}

class _CartLine {
  const _CartLine(this.item, this.quantity);

  final CatalogItem item;
  final int quantity;
}

List<_CartLine> _cartLines(Map<String, int> cart) => cart.entries
    .map((entry) {
      final item = _itemById(entry.key);
      return item == null ? null : _CartLine(item, entry.value);
    })
    .nonNulls
    .toList(growable: false);

CatalogItem? _itemById(String id) {
  for (final item in allSearchableItems()) {
    if (item.id == id) return item;
  }
  return null;
}

int _total(List<_CartLine> lines) =>
    lines.fold(0, (sum, line) => sum + _price(line.item.price) * line.quantity);

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
