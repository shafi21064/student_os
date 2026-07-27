import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/widgets/app_card.dart';
import 'package:studentos/core/widgets/common_widgets.dart';
import 'package:studentos/data/demo_data.dart';
import 'package:studentos/data/models.dart';

class CareerScreen extends StatefulWidget {
  const CareerScreen({super.key, this.section});

  final String? section;

  @override
  State<CareerScreen> createState() => _CareerScreenState();
}

class _CareerScreenState extends State<CareerScreen> {
  String _category = 'All';
  final _coursesKey = GlobalKey();
  final _internshipsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToRequestedSection());
  }

  @override
  void didUpdateWidget(CareerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToRequestedSection());
    }
  }

  void _scrollToRequestedSection() {
    final target = widget.section == 'internships' ? _internshipsKey.currentContext : _coursesKey.currentContext;
    if (target != null && widget.section != null) {
      Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic, alignment: .05);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleCourses = courses.where((item) => _category == 'All' || item.category == _category).toList();
    final visibleJobs = internships.where((item) => _category == 'All' || item.category == _category).toList();
    return ListView(
      key: const PageStorageKey<String>('career-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: <Widget>[
        Text('Career Hub', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search courses & jobs...')),
        const SizedBox(height: 14),
        const _ProgressCard(),
        const SizedBox(height: 14),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: careerCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = careerCategories[index];
              return ChoiceChip(label: Text(category), selected: _category == category, onSelected: (_) => setState(() => _category = category));
            },
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader(key: _coursesKey, title: 'Discounted Courses'),
        const SizedBox(height: 10),
        if (visibleCourses.isEmpty)
          const EmptyState(emoji: '📚', title: 'No courses in this category', message: 'Choose another skill category.')
        else
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visibleCourses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _CourseCard(item: visibleCourses[index]),
            ),
          ),
        const SizedBox(height: 22),
        SectionHeader(key: _internshipsKey, title: 'Featured Internships'),
        const SizedBox(height: 10),
        if (visibleJobs.isEmpty)
          const EmptyState(emoji: '💼', title: 'No internships in this category', message: 'Try a broader category.')
        else
          ...visibleJobs.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: CatalogListTile(item: item, onTap: () => context.push('/details/job/${item.id}')),
              )),
        const SizedBox(height: 10),
        const _WorkshopCard(),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: <Color>[Color(0xFF7C3AED), Color(0xFF9333EA)]),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: <Widget>[
            const Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Your Progress', style: TextStyle(color: Color(0xFFE9D5FF), fontSize: 11, fontWeight: FontWeight.w700)),
                      SizedBox(height: 3),
                      Text('Full-Stack Roadmap', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                      Text('60% complete · 8 modules done', style: TextStyle(color: Color(0xFFE9D5FF), fontSize: 12)),
                    ],
                  ),
                ),
                CircleAvatar(backgroundColor: Color(0x33FFFFFF), child: Icon(Icons.trending_up_rounded, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 13),
            const LinearProgressIndicator(value: .6, minHeight: 8, backgroundColor: Color(0x33FFFFFF), color: Colors.white),
          ],
        ),
      );
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 172,
        child: AppCard(
          padding: const EdgeInsets.all(13),
          radius: 22,
          onTap: () => context.push('/details/course/${item.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              EmojiTile(emoji: item.emoji, background: item.background, size: 146, emojiSize: 46),
              const SizedBox(height: 9),
              if (item.badge != null) BadgeLabel(item.badge!, color: AppColors.danger),
              const SizedBox(height: 5),
              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(height: 3),
              Row(children: <Widget>[if (item.rating != null) RatingLabel(item.rating!), const Spacer(), Text(item.price, style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w900, fontSize: 12))]),
            ],
          ),
        ),
      );
}

class _WorkshopCard extends StatelessWidget {
  const _WorkshopCard();

  @override
  Widget build(BuildContext context) => AppCard(
        color: AppColors.blueSoft,
        child: Row(
          children: <Widget>[
            const EmojiTile(emoji: '🧠', background: Color(0xFFDDEAFE), size: 56, emojiSize: 29),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('AI Portfolio Workshop', style: TextStyle(fontWeight: FontWeight.w900)),
                  SizedBox(height: 3),
                  Text('Saturday · 4:00 PM · Online', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            FilledButton.tonal(onPressed: () {}, child: const Text('Join')),
          ],
        ),
      );
}
