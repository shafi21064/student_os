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
    final response = await ApiClient.instance.post<dynamic>(
      Api.cart,
      data: const <String, dynamic>{'source': 'app'},
    );
    final body = response.data;
    if (!mounted) return;

    if (response.isSuccess) {
      setState(() => _lines = _cartLinesFrom(body));
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
  var _payment = 'cash_on_delivery';
  var _loading = true;
  var _submitting = false;
  String? _error;
  List<_CartLine> _lines = const <_CartLine>[];
  List<ShippingAddressData> _addresses = const <ShippingAddressData>[];
  ShippingAddressData? _selectedAddress;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _loadCheckout();
  }

  @override
  void dispose() {
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadCheckout() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final cart = await ApiClient.instance.post<dynamic>(
      Api.cart,
      data: const <String, dynamic>{'source': 'app'},
    );
    final addresses = await ApiClient.instance.get<dynamic>(
      Api.shippingAddress,
      queryParameters: const <String, dynamic>{'source': 'app'},
    );
    if (!mounted) return;

    if (!cart.isSuccess) {
      setState(() {
        _error = cart.message ?? 'Cart fetch failed.';
        _loading = false;
      });
      return;
    }

    final lines = _cartLinesFrom(cart.data);
    final parsedAddresses = _addressesFrom(addresses.data);
    final selected = parsedAddresses.firstOrNull;
    if (selected != null && _address.text.trim().isEmpty) {
      _address.text = selected.address;
    }
    setState(() {
      _lines = lines;
      _addresses = parsedAddresses;
      _selectedAddress = selected;
      _loading = false;
    });
    await _loadSummary();
  }

  Future<void> _loadSummary() async {
    if (_lines.isEmpty) return;
    final response = await ApiClient.instance.post<dynamic>(
      Api.checkoutSummary,
      data: <String, dynamic>{
        'product_ids_arr': _lines
            .map((line) => int.tryParse(line.item.id) ?? 0)
            .toList(),
        'product_quantities_arr': _lines.map((line) => line.quantity).toList(),
        'city_id': _selectedAddress?.cityId,
        'phone_number': _selectedAddress?.phone,
        'remove_coupon': false,
      },
    );
    final data = response.data;
    if (!mounted || !response.isSuccess || data is! Map<String, dynamic>) {
      return;
    }
    setState(
      () => _summary = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : null,
    );
  }

  Future<void> _placeOrder() async {
    final user = ref.read(authProvider).user;
    final address = _address.text.trim();
    final selectedAddress = _selectedAddress;
    if (address.length < 10 ||
        selectedAddress == null ||
        selectedAddress.cityId == null ||
        selectedAddress.zoneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add or select a shipping address first.'),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final response = await ApiClient.instance.post<dynamic>(
      Api.productOrder,
      data: <String, dynamic>{
        'product_ids_arr': _lines
            .map((line) => int.tryParse(line.item.id) ?? 0)
            .toList(),
        'product_quantities_arr': _lines.map((line) => line.quantity).toList(),
        'shipping_address': address,
        'shipping_name': selectedAddress.name.isNotEmpty
            ? selectedAddress.name
            : user?.name ?? AppStrings.student,
        'shipping_phone': selectedAddress.phone.isNotEmpty
            ? selectedAddress.phone
            : user?.mobile ?? '',
        'shipping_city_id': selectedAddress.cityId,
        'shipping_zone_id': selectedAddress.zoneId,
        'shipping_area_id': selectedAddress.areaId,
        'is_preorder': 0,
        'payment_type': _payment,
        'note': _note.text.trim(),
        'type': 'app',
        'coupon_code': null,
        'redeem_point': 0,
        'source': 'app',
      },
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    final body = response.data;
    if (response.isSuccess &&
        body is Map<String, dynamic> &&
        body['result'] == true) {
      ref.read(cartProvider.notifier).clear();
      context.go('/purchase-result?status=success');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _messageFrom(body) ?? response.message ?? 'Order failed.',
        ),
      ),
    );
    context.push('/purchase-result?status=failed');
  }

  @override
  Widget build(BuildContext context) {
    final lines = _lines;
    final user = ref.watch(authProvider).user;
    final subtotal = _summaryMoney('sub_total') ?? _total(lines);
    final discount = _summaryMoney('discount') ?? 0;
    final delivery = _summaryMoney('shipping_cost') ?? 0;
    final total =
        _summaryMoney('grand_total') ?? subtotal - discount + delivery;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.checkout)),
      bottomNavigationBar: lines.isEmpty
          ? null
          : SafeArea(
              minimum: AppSizes.bottomActionInsets,
              child: FilledButton(
                onPressed: _submitting ? null : _placeOrder,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  minimumSize: const Size.fromHeight(
                    AppSizes.bottomActionHeight,
                  ),
                ),
                child: Text(
                  _submitting
                      ? 'Placing order...'
                      : 'Place order · ৳${_money(total)}',
                ),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? EmptyState(
              emoji: '🛒',
              title: 'Checkout unavailable',
              message: _error!,
            )
          : lines.isEmpty
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
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              AppStrings.contactDetails,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/shipping-address'),
                            child: Text(
                              _addresses.isEmpty ? 'Add address' : 'Manage',
                            ),
                          ),
                        ],
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
                      const SizedBox(height: AppSizes.gapSm),
                      if (_addresses.isNotEmpty) ...<Widget>[
                        DropdownButtonFormField<ShippingAddressData>(
                          initialValue: _selectedAddress,
                          decoration: const InputDecoration(
                            labelText: 'Saved address',
                          ),
                          items: _addresses
                              .map(
                                (address) =>
                                    DropdownMenuItem<ShippingAddressData>(
                                      value: address,
                                      child: Text(
                                        address.address,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedAddress = value;
                              _address.text = value.address;
                            });
                            _loadSummary();
                          },
                        ),
                        const SizedBox(height: AppSizes.gapSm),
                      ],
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
                        AppStrings.paymentMethod,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSizes.gapSm),
                      ...const <(String, String)>[
                        ('cash_on_delivery', 'Cash on Delivery'),
                        ('bkash', 'bKash'),
                        ('ssl', 'Card'),
                      ].map(
                        (method) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () => setState(() => _payment = method.$1),
                          title: Text(method.$2),
                          trailing: _payment == method.$1
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

  int? _summaryMoney(String key) {
    final value = _summary?[key];
    if (value is num) return value.round();
    return int.tryParse(value?.toString().replaceAll(RegExp(r'\D'), '') ?? '');
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

class ShippingAddressScreen extends ConsumerStatefulWidget {
  const ShippingAddressScreen({super.key});

  @override
  ConsumerState<ShippingAddressScreen> createState() =>
      ShippingAddressDataScreenState();
}

class ShippingAddressDataScreenState
    extends ConsumerState<ShippingAddressScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _zone = TextEditingController();
  final _area = TextEditingController();
  var _loading = true;
  var _saving = false;
  List<ShippingAddressData> _addresses = const <ShippingAddressData>[];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _name.text = user?.name ?? '';
    _phone.text = user?.mobile ?? '';
    _email.text = user?.email ?? '';
    _loadAddresses();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _city.dispose();
    _zone.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    final response = await ApiClient.instance.get<dynamic>(
      Api.shippingAddress,
      queryParameters: const <String, dynamic>{'source': 'app'},
    );
    if (!mounted) return;
    final addresses = _addressesFrom(response.data);
    setState(() {
      _addresses = addresses;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_address.text.trim().length < 10 ||
        _city.text.trim().isEmpty ||
        _zone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address, city id, and zone id are required.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final response = await ApiClient.instance.post<dynamic>(
      Api.shippingAddressCreateOrUpdate,
      queryParameters: const <String, dynamic>{'source': 'app'},
      data: <String, dynamic>{
        'address': _address.text.trim(),
        'area_id': _area.text.trim(),
        'zone_id': _zone.text.trim(),
        'city_id': _city.text.trim(),
        'phone': _phone.text.trim(),
        'name': _name.text.trim(),
        'email': _email.text.trim(),
      },
    );
    if (!mounted) return;
    setState(() => _saving = false);
    final ok = response.isSuccess && response.data is Map<String, dynamic>;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Address saved' : response.message ?? 'Address save failed.',
        ),
      ),
    );
    if (ok) _loadAddresses();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Shipping Address')),
    bottomNavigationBar: SafeArea(
      minimum: AppSizes.bottomActionInsets,
      child: FilledButton(
        onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.bottomActionHeight),
        ),
        child: Text(_saving ? 'Saving...' : 'Save address'),
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: AppSizes.listPadding,
            children: <Widget>[
              if (_addresses.isNotEmpty) ...<Widget>[
                ..._addresses.map(
                  (address) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.gapMd),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            address.name.isEmpty
                                ? 'Saved address'
                                : address.name,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(address.address),
                          if (address.phone.isNotEmpty)
                            Text(
                              address.phone,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.gapSm),
              ],
              AppCard(
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: AppSizes.gapSm),
                    TextField(
                      controller: _phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: AppSizes.gapSm),
                    TextField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: AppSizes.gapSm),
                    TextField(
                      controller: _address,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: AppSizes.gapSm),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _city,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'City ID',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.gapSm),
                        Expanded(
                          child: TextField(
                            controller: _zone,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Zone ID',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.gapSm),
                        Expanded(
                          child: TextField(
                            controller: _area,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Area ID',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
  );
}

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  var _loading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = const <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final response = await ApiClient.instance.get<dynamic>(
      Api.purchaseHistory,
      queryParameters: const <String, dynamic>{'source': 'app'},
    );
    if (!mounted) return;
    final body = response.data;
    if (response.isSuccess &&
        body is Map<String, dynamic> &&
        body['data'] is List) {
      setState(() {
        _orders = (body['data'] as List)
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
        _loading = false;
      });
      return;
    }
    setState(() {
      _error =
          _messageFrom(body) ?? response.message ?? 'Order history failed.';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Order History')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? EmptyState(emoji: '📦', title: 'Orders unavailable', message: _error!)
        : _orders.isEmpty
        ? const EmptyState(
            emoji: '📦',
            title: 'No orders yet',
            message: 'Your Kirei orders will appear here.',
          )
        : ListView.separated(
            padding: AppSizes.listPadding,
            itemCount: _orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSizes.gapMd),
            itemBuilder: (context, index) {
              final order = _orders[index];
              final id = order['id']?.toString() ?? '';
              final shipping = order['shipping_address'];
              final address = shipping is Map<String, dynamic>
                  ? ShippingAddressData.fromJson(shipping)
                  : null;
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Order #$id',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        Text(
                          order['grand_total']?.toString() ?? '',
                          style: const TextStyle(
                            color: AppColors.purple,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order['date']?.toString() ?? '',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (address != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(address.address),
                    ],
                    const SizedBox(height: AppSizes.gapSm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: id.isEmpty
                            ? null
                            : () => context.push(
                                '/orders/$id/address',
                                extra: address,
                              ),
                        icon: const Icon(Icons.edit_location_alt_outlined),
                        label: const Text('Update shipping'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
  );
}

class OrderAddressUpdateScreen extends StatefulWidget {
  const OrderAddressUpdateScreen({
    required this.orderId,
    this.address,
    super.key,
  });

  final int orderId;
  final ShippingAddressData? address;

  @override
  State<OrderAddressUpdateScreen> createState() =>
      _OrderAddressUpdateScreenState();
}

class _OrderAddressUpdateScreenState extends State<OrderAddressUpdateScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _zone;
  late final TextEditingController _area;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _name = TextEditingController(text: address?.name ?? '');
    _phone = TextEditingController(text: address?.phone ?? '');
    _address = TextEditingController(text: address?.address ?? '');
    _city = TextEditingController(text: address?.cityId?.toString() ?? '');
    _zone = TextEditingController(text: address?.zoneId?.toString() ?? '');
    _area = TextEditingController(text: address?.areaId?.toString() ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _zone.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final response = await ApiClient.instance.post<dynamic>(
      '${Api.changeOrderAddresses}${widget.orderId}',
      data: <String, dynamic>{
        'source': 'app',
        'shipping_name': _name.text.trim(),
        'shipping_address': _address.text.trim(),
        'shipping_area_id': int.tryParse(_area.text.trim()) ?? 0,
        'shipping_city_id': int.tryParse(_city.text.trim()) ?? 0,
        'shipping_zone_id': int.tryParse(_zone.text.trim()) ?? 0,
        'shipping_phone': _phone.text.trim(),
      },
    );
    if (!mounted) return;
    setState(() => _saving = false);
    final ok = response.isSuccess && response.data is Map<String, dynamic>;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Shipping address updated'
              : response.message ?? 'Update failed.',
        ),
      ),
    );
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Order #${widget.orderId} Shipping')),
    bottomNavigationBar: SafeArea(
      minimum: AppSizes.bottomActionInsets,
      child: FilledButton(
        onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.bottomActionHeight),
        ),
        child: Text(_saving ? 'Updating...' : 'Update shipping'),
      ),
    ),
    body: ListView(
      padding: AppSizes.listPadding,
      children: <Widget>[
        AppCard(
          child: Column(
            children: <Widget>[
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: AppSizes.gapSm),
              TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: AppSizes.gapSm),
              TextField(
                controller: _address,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: AppSizes.gapSm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _city,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'City ID'),
                    ),
                  ),
                  const SizedBox(width: AppSizes.gapSm),
                  Expanded(
                    child: TextField(
                      controller: _zone,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Zone ID'),
                    ),
                  ),
                  const SizedBox(width: AppSizes.gapSm),
                  Expanded(
                    child: TextField(
                      controller: _area,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Area ID'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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

List<_CartLine> _cartLinesFrom(Object? source) {
  final rows = <Map<String, dynamic>>[];
  void collect(Object? value) {
    if (value is Map<String, dynamic>) {
      final data = value['data'];
      final items = value['cart_items'];
      if (data != null) collect(data);
      if (items != null) collect(items);
      if (value.containsKey('product_data') ||
          value.containsKey('product_name') ||
          value.containsKey('product_id')) {
        rows.add(value);
      }
    } else if (value is List) {
      for (final item in value) {
        collect(item);
      }
    }
  }

  collect(source);
  return rows
      .map((row) {
        final product = row['product_data'];
        final productMap = product is Map<String, dynamic>
            ? product
            : const <String, dynamic>{};
        final quantity = _asInt(row['quantity']) ?? 1;
        final unitPrice =
            _asInt(row['price']) ??
            _asInt(row['unit_price']) ??
            _asInt(productMap['sale_price']) ??
            _asInt(productMap['price']) ??
            0;
        final total = _asInt(row['net_price']) ?? unitPrice * quantity;
        final title =
            row['product_name']?.toString() ??
            productMap['name']?.toString() ??
            productMap['title']?.toString() ??
            '';
        return _CartLine(
          CatalogItem(
            id:
                row['product_id']?.toString() ??
                productMap['id']?.toString() ??
                '',
            slug: row['slug']?.toString() ?? productMap['slug']?.toString(),
            title: title,
            subtitle: 'Product',
            emoji: '🛍️',
            imageUrl:
                row['product_thumbnail_image']?.toString() ??
                productMap['banner']?.toString(),
            price: '৳${_money(unitPrice)}',
            background: AppColors.purpleSoft,
          ),
          quantity,
          total: total,
        );
      })
      .where((line) => line.item.id.isNotEmpty && line.item.title.isNotEmpty)
      .toList(growable: false);
}

List<ShippingAddressData> _addressesFrom(Object? source) {
  if (source is! Map<String, dynamic> || source['data'] is! List) {
    return const <ShippingAddressData>[];
  }
  return (source['data'] as List)
      .whereType<Map<String, dynamic>>()
      .map(ShippingAddressData.fromJson)
      .where((address) => address.address.isNotEmpty)
      .toList(growable: false);
}

String? _messageFrom(Object? body) => body is Map<String, dynamic>
    ? body['message']?.toString() ?? body['error']?.toString()
    : null;

class ShippingAddressData {
  const ShippingAddressData({
    required this.address,
    required this.name,
    required this.phone,
    this.id,
    this.cityId,
    this.zoneId,
    this.areaId,
    this.cityName,
    this.zoneName,
    this.areaName,
  });

  factory ShippingAddressData.fromJson(Map<String, dynamic> json) =>
      ShippingAddressData(
        id: _asInt(json['id']),
        address: json['address']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        cityId: _asInt(json['city_id']),
        zoneId: _asInt(json['zone_id']),
        areaId: _asInt(json['area_id']),
        cityName: json['city_name']?.toString() ?? json['city']?.toString(),
        zoneName: json['zone_name']?.toString() ?? json['zone']?.toString(),
        areaName: json['area_name']?.toString() ?? json['area']?.toString(),
      );

  final int? id;
  final String address;
  final String name;
  final String phone;
  final int? cityId;
  final int? zoneId;
  final int? areaId;
  final String? cityName;
  final String? zoneName;
  final String? areaName;
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
