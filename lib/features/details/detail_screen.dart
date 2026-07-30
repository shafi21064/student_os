import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/widgets/app_card.dart';
import 'package:studentos/core/widgets/common_widgets.dart';
import 'package:studentos/data/demo_data.dart';
import 'package:studentos/data/models.dart';
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

  @override
  Widget build(BuildContext context) {
    final item = findCatalogItem(widget.kind, widget.id);
    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not found')),
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
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _performAction(context, item),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accentFor(widget.kind),
                        minimumSize: const Size.fromHeight(54),
                      ),
                      child: Text(
                        actionComplete ? 'Added to Cart' : 'Add to Cart',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).add(item.id, _quantity);
                        context.push('/checkout');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        minimumSize: const Size.fromHeight(54),
                      ),
                      child: Text('Buy Now · ${item.price}'),
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton.icon(
                onPressed: actionComplete
                    ? null
                    : () => _performAction(context, item),
                style: FilledButton.styleFrom(
                  backgroundColor: _accentFor(widget.kind),
                  minimumSize: const Size.fromHeight(54),
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
            decoration: BoxDecoration(
              color: item.background,
              borderRadius: BorderRadius.circular(30),
            ),
            alignment: Alignment.center,
            child: Text(item.emoji, style: const TextStyle(fontSize: 96)),
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
                  IconButton.filledTonal(
                    onPressed: _quantity == 1
                        ? null
                        : () => setState(() => _quantity--),
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
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
                ..._facts(widget.kind, item).map(
                  (fact) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(fact.$1, size: 19, color: _accentFor(widget.kind)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            fact.$2,
                            style: const TextStyle(height: 1.35),
                          ),
                        ),
                      ],
                    ),
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

  void _performAction(BuildContext context, CatalogItem item) {
    if (widget.kind == 'event') {
      ref.read(registrationsProvider.notifier).register(item.id);
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
  'event' => const Color(0xFF0D9488),
  'buysell' => const Color(0xFFEC4899),
  'tuition' => const Color(0xFF0891B2),
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
