import 'package:flutter/material.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/theme/app_sizes.dart';
import 'package:studentos/core/widgets/app_card.dart';

class SecureCheckoutCard extends StatelessWidget {
  const SecureCheckoutCard({
    super.key,
    this.message = 'Secure checkout with student discount protection.',
  });

  final String message;

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.purpleSoft,
    child: Row(
      children: <Widget>[
        const Icon(Icons.shield_outlined, color: AppColors.purple),
        const SizedBox(width: AppSizes.gapSm),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class CommerceInfoRow extends StatelessWidget {
  const CommerceInfoRow({
    required this.label,
    required this.value,
    super.key,
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

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
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
