import 'package:flutter/material.dart';
import 'package:studentos/core/constants/app_strings.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/theme/app_sizes.dart';
import 'package:studentos/data/models.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.onSeeAll,
    this.actionLabel = AppStrings.seeAll,
  });

  final String title;
  final VoidCallback? onSeeAll;
  final String actionLabel;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      if (onSeeAll != null)
        TextButton.icon(
          onPressed: onSeeAll,
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.chevron_right_rounded, size: AppSizes.iconSm),
          label: Text(actionLabel),
        ),
    ],
  );
}

class EmojiTile extends StatelessWidget {
  const EmojiTile({
    required this.emoji,
    required this.background,
    super.key,
    this.size = 64,
    this.emojiSize = 32,
    this.borderRadius = AppSizes.radiusMd,
  });

  final String emoji;
  final Color background;
  final double size;
  final double emojiSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    alignment: Alignment.center,
    child: Text(emoji, style: TextStyle(fontSize: emojiSize)),
  );
}

class RatingLabel extends StatelessWidget {
  const RatingLabel(this.rating, {super.key});

  final double rating;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const Icon(Icons.star_rounded, color: AppColors.orange, size: 16),
      const SizedBox(width: 2),
      Text(
        rating.toStringAsFixed(1),
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class BadgeLabel extends StatelessWidget {
  const BadgeLabel(this.label, {super.key, this.color = AppColors.blue});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );
}

class CatalogListTile extends StatelessWidget {
  const CatalogListTile({
    required this.item,
    required this.onTap,
    super.key,
    this.trailing,
  });

  final CatalogItem item;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            EmojiTile(
              emoji: item.emoji,
              background: item.background,
              size: 50,
              emojiSize: 25,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    <String>[
                      item.subtitle,
                      if (item.location != null) item.location!,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        item.price,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      if (item.badge != null) BadgeLabel(item.badge!),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ?? const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.emoji,
    required this.title,
    required this.message,
    super.key,
  });

  final String emoji;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
    child: Column(
      children: <Widget>[
        Text(emoji, style: const TextStyle(fontSize: 52)),
        const SizedBox(height: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class AppRoundIconButton extends StatelessWidget {
  const AppRoundIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    super.key,
    this.size = AppSizes.topBarIcon,
    this.iconSize = 17,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: .30),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}
