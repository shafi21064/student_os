import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:studentos/core/widgets/common_widgets.dart';
import 'package:studentos/data/demo_data.dart';
import 'package:studentos/data/models.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _query.trim().isEmpty
        ? <CatalogItem>[]
        : allSearchableItems().where((item) {
            final query = _query.toLowerCase();
            return item.title.toLowerCase().contains(query) ||
                item.subtitle.toLowerCase().contains(query) ||
                item.category.toLowerCase().contains(query) ||
                (item.location?.toLowerCase().contains(query) ?? false);
          }).take(30).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: 'Ask StudentOS AI or search...',
            prefixIcon: const Icon(Icons.auto_awesome_rounded),
            suffixIcon: _query.isEmpty ? null : IconButton(onPressed: () { _controller.clear(); setState(() => _query = ''); }, icon: const Icon(Icons.close_rounded)),
          ),
        ),
        actions: const <Widget>[SizedBox(width: 12)],
      ),
      body: _query.trim().isEmpty
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Text('Try searching for', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: searchPlaceholders.take(5).map((suggestion) => ActionChip(label: Text(suggestion.replaceAll('...', '')), onPressed: () { final value = suggestion.replaceAll('...', ''); _controller.text = value; setState(() => _query = value); })).toList(),
                ),
                const SizedBox(height: 32),
                const EmptyState(emoji: '✨', title: 'One search across StudentOS', message: 'Find courses, internships, student deals, food, tuition, events, and marketplace listings.'),
              ],
            )
          : results.isEmpty
              ? const EmptyState(emoji: '🔎', title: 'No results found', message: 'Try a broader search term.')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = results[index];
                    final kind = _kindFor(item);
                    return CatalogListTile(item: item, onTap: () => context.push('/details/$kind/${item.id}'));
                  },
                ),
    );
  }
}

String _kindFor(CatalogItem item) {
  if (courses.contains(item)) return 'course';
  if (internships.contains(item)) return 'job';
  if (shopProducts.contains(item)) return 'product';
  if (marketplaceProducts.contains(item)) return 'marketplace';
  if (foodDishes.contains(item)) return 'food';
  if (restaurants.contains(item)) return 'restaurant';
  if (tuitionJobs.contains(item)) return 'tuition';
  if (buySellListings.contains(item)) return 'buysell';
  if (events.contains(item)) return 'event';
  return 'product';
}
