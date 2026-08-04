import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studentos/core/constants/app_strings.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/widgets/app_card.dart';
import 'package:studentos/core/widgets/common_widgets.dart';
import 'package:studentos/data/demo_data.dart';
import 'package:studentos/state/favorites_controller.dart';
import 'package:studentos/state/registrations_controller.dart';

class TuitionScreen extends StatefulWidget {
  const TuitionScreen({super.key});

  @override
  State<TuitionScreen> createState() => _TuitionScreenState();
}

class _TuitionScreenState extends State<TuitionScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final visible = tuitionJobs
        .where(
          (item) =>
              item.title.toLowerCase().contains(_query.toLowerCase()) ||
              item.location!.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tuition)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: AppStrings.searchSubjectLocation,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[AppColors.teal, AppColors.blue],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Earn while you study',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Verified tuition opportunities near campus.',
                        style: TextStyle(
                          color: AppColors.tealSoft,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text('📚', style: TextStyle(fontSize: 48)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(title: '${visible.length} opportunities'),
          const SizedBox(height: 9),
          if (visible.isEmpty)
            const EmptyState(
              emoji: '🔎',
              title: 'No tuition jobs found',
              message: 'Try a different subject or location.',
            )
          else
            ...visible.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: CatalogListTile(
                  item: item,
                  onTap: () => context.push('/details/tuition/${item.id}'),
                  trailing: FilledButton.tonal(
                    onPressed: () =>
                        context.push('/details/tuition/${item.id}'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(66, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BuySellScreen extends StatefulWidget {
  const BuySellScreen({super.key});

  @override
  State<BuySellScreen> createState() => _BuySellScreenState();
}

class _BuySellScreenState extends State<BuySellScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  final _title = TextEditingController();
  final _price = TextEditingController();
  String _condition = 'Like New';
  bool _posted = false;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _title.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(AppStrings.buySell),
      bottom: TabBar(
        controller: _controller,
        tabs: const <Tab>[
          Tab(text: 'Browse Listings'),
          Tab(text: 'Post an Item'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _controller,
      children: <Widget>[
        ListView(
          padding: const EdgeInsets.all(16),
          children: buySellListings
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: CatalogListTile(
                    item: item,
                    onTap: () => context.push('/details/buysell/${item.id}'),
                  ),
                ),
              )
              .toList(),
        ),
        ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            AppCard(
              child: _posted
                  ? Column(
                      children: <Widget>[
                        const Text('🎉', style: TextStyle(fontSize: 58)),
                        const SizedBox(height: 8),
                        Text(
                          'Item Posted!',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Your listing is now visible to other students.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: () => setState(() {
                            _posted = false;
                            _title.clear();
                            _price.clear();
                          }),
                          child: const Text('Post another'),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Post Your Item',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _title,
                          decoration: const InputDecoration(
                            labelText: 'Item title',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _price,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            prefixText: '৳ ',
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _condition,
                          decoration: const InputDecoration(
                            labelText: 'Condition',
                          ),
                          items: const <String>['Like New', 'Good', 'Used']
                              .map(
                                (value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _condition = value ?? _condition),
                        ),
                        const SizedBox(height: 12),
                        const TextField(
                          decoration: InputDecoration(
                            labelText: 'Location',
                            hintText: AppStrings.campusExample,
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: () {
                            if (_title.text.trim().isNotEmpty &&
                                _price.text.trim().isNotEmpty) {
                              setState(() => _posted = true);
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.pink,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('Post Item'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ],
    ),
  );
}

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.marketplace)),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                children: <Widget>[
                  const TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: AppStrings.searchProducts,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[AppColors.coral, AppColors.orange],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Flash Sale',
                          style: TextStyle(
                            color: AppColors.orangeSoft,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Up to 30% Student OFF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid.builder(
              itemCount: marketplaceProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .76,
              ),
              itemBuilder: (context, index) {
                final item = marketplaceProducts[index];
                final favorite = favorites.contains(item.id);
                return AppCard(
                  padding: const EdgeInsets.all(11),
                  radius: 21,
                  onTap: () => context.push('/details/marketplace/${item.id}'),
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
                              child: Text(
                                item.emoji,
                                style: const TextStyle(fontSize: 48),
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: IconButton.filled(
                                onPressed: () => ref
                                    .read(favoritesProvider.notifier)
                                    .toggle(item.id),
                                style: IconButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  minimumSize: const Size(33, 33),
                                  padding: EdgeInsets.zero,
                                ),
                                icon: Icon(
                                  favorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: favorite ? AppColors.danger : null,
                                  size: 17,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              item.price,
                              style: const TextStyle(
                                color: AppColors.coral,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (item.badge != null)
                            BadgeLabel(item.badge!, color: AppColors.danger),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registered = ref.watch(registrationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.events)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: events.map((event) {
          final isRegistered = registered.contains(event.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: AppCard(
              padding: EdgeInsets.zero,
              onTap: () => context.push('/details/event/${event.id}'),
              child: Column(
                children: <Widget>[
                  Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: event.background,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      event.emoji,
                      style: const TextStyle(fontSize: 50),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (event.badge != null) BadgeLabel(event.badge!),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.subtitle,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          '📅 ${event.meta}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '📍 ${event.location}  ·  ${event.price}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 13),
                        FilledButton(
                          onPressed: isRegistered
                              ? null
                              : () => ref
                                    .read(registrationsProvider.notifier)
                                    .register(event.id),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            backgroundColor: isRegistered
                                ? AppColors.green
                                : AppColors.blue,
                          ),
                          child: Text(
                            isRegistered ? '✓ Registered' : 'Register Now',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
