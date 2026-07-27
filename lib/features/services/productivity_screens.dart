import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/widgets/app_card.dart';
import 'package:studentos/core/widgets/common_widgets.dart';
import 'package:studentos/data/demo_data.dart';
import 'package:studentos/data/models.dart';
import 'package:studentos/state/favorites_controller.dart';
import 'package:studentos/state/notes_controller.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  static const colors = <Color>[
    Color(0xFFDBEAFE), Color(0xFFDCFCE7), Color(0xFFFEF9C3),
    Color(0xFFFCE7F3), Color(0xFFEDE9FE), Color(0xFFFEE2E2),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _newNote(context, ref), icon: const Icon(Icons.add_rounded), label: const Text('New note')),
      body: notes.isEmpty
          ? const EmptyState(emoji: '📝', title: 'No notes yet', message: 'Create your first study note.')
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: notes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .88),
              itemBuilder: (context, index) {
                final note = notes[index];
                return AppCard(
                  color: note.color,
                  radius: 22,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Row(children: <Widget>[
                      Expanded(child: Text(note.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz_rounded, color: AppColors.ink),
                        onSelected: (value) { if (value == 'delete') ref.read(notesProvider.notifier).remove(note.id); },
                        itemBuilder: (_) => const <PopupMenuEntry<String>>[PopupMenuItem(value: 'delete', child: Text('Delete'))],
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Expanded(child: Text(note.body, maxLines: 6, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF334155), height: 1.4, fontSize: 12))),
                    Text(note.date, style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w700)),
                  ]),
                );
              },
            ),
    );
  }

  Future<void> _newNote(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final body = TextEditingController();
    var selected = colors.first;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Create note', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              TextField(controller: body, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Note')),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: colors.map((color) => InkWell(
                      onTap: () => setState(() => selected = color),
                      customBorder: const CircleBorder(),
                      child: Container(width: 34, height: 34, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: selected == color ? AppColors.blue : Colors.transparent, width: 3))),
                    )).toList(),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)), child: const Text('Save note')),
            ],
          ),
        ),
      ),
    );
    if (result == true) ref.read(notesProvider.notifier).add(title: title.text, body: body.text, color: selected);
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  double? _stored;
  String? _operation;
  bool _replace = false;

  void _tap(String key) {
    setState(() {
      if (key == 'C') {
        _display = '0'; _stored = null; _operation = null; _replace = false; return;
      }
      if (key == '⌫') {
        _display = _display.length <= 1 ? '0' : _display.substring(0, _display.length - 1); return;
      }
      if (<String>{'+', '−', '×', '÷'}.contains(key)) {
        _stored = double.tryParse(_display) ?? 0; _operation = key; _replace = true; return;
      }
      if (key == '=') {
        final left = _stored; final op = _operation; final right = double.tryParse(_display) ?? 0;
        if (left == null || op == null) return;
        final result = switch (op) { '+' => left + right, '−' => left - right, '×' => left * right, '÷' => right == 0 ? double.nan : left / right, _ => right };
        _display = result.isNaN ? 'Error' : result == result.roundToDouble() ? result.toInt().toString() : result.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
        _stored = null; _operation = null; _replace = true; return;
      }
      if (key == '.') {
        if (_replace || _display == 'Error') { _display = '0.'; _replace = false; } else if (!_display.contains('.')) { _display += '.'; }
        return;
      }
      if (_replace || _display == '0' || _display == 'Error') { _display = key; _replace = false; } else { _display += key; }
    });
  }

  @override
  Widget build(BuildContext context) {
    const keys = <String>['C', '⌫', '÷', '×', '7', '8', '9', '−', '4', '5', '6', '+', '1', '2', '3', '=', '0', '.', '00', '='];
    return Scaffold(
      appBar: AppBar(title: const Text('Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Expanded(
              child: AppCard(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.bottomRight, child: Text(_display, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w300))),
                ),
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: keys.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.18),
              itemBuilder: (context, index) {
                final key = keys[index];
                final primary = <String>{'+', '−', '×', '÷', '='}.contains(key);
                return FilledButton(
                  onPressed: () => _tap(key),
                  style: FilledButton.styleFrom(backgroundColor: primary ? AppColors.blue : Theme.of(context).colorScheme.surfaceContainerHighest, foregroundColor: primary ? Colors.white : Theme.of(context).colorScheme.onSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                  child: Text(key, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <CatalogItem>[courses[0], internships[1], events[0], tuitionJobs[1]];
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 11),
        itemBuilder: (context, index) {
          final item = items[index];
          final kind = index == 0 ? 'course' : index == 1 ? 'job' : index == 2 ? 'event' : 'tuition';
          return CatalogListTile(item: item, onTap: () => context.push('/details/$kind/${item.id}'), trailing: const Icon(Icons.bookmark_rounded, color: AppColors.purple));
        },
      ),
    );
  }
}

class SavedItemsScreen extends ConsumerWidget {
  const SavedItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final items = allSearchableItems().where((item) => favorites.contains(item.id)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Items')),
      body: items.isEmpty
          ? const EmptyState(emoji: '💜', title: 'Nothing saved yet', message: 'Tap the heart icon on products and marketplace offers.')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 11),
              itemBuilder: (context, index) {
                final item = items[index];
                final kind = shopProducts.any((value) => value.id == item.id) ? 'product' : 'marketplace';
                return CatalogListTile(
                  item: item,
                  onTap: () => context.push('/details/$kind/${item.id}'),
                  trailing: IconButton(onPressed: () => ref.read(favoritesProvider.notifier).toggle(item.id), icon: const Icon(Icons.favorite_rounded, color: AppColors.danger)),
                );
              },
            ),
    );
  }
}
