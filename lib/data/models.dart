import 'package:flutter/material.dart';

@immutable
class TaskItem {
  const TaskItem({required this.id, required this.title, required this.completed});

  final int id;
  final String title;
  final bool completed;

  TaskItem copyWith({String? title, bool? completed}) => TaskItem(
        id: id,
        title: title ?? this.title,
        completed: completed ?? this.completed,
      );
}

@immutable
class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.price,
    this.originalPrice,
    this.badge,
    this.rating,
    this.location,
    this.meta,
    this.category = 'All',
    this.description = '',
    this.background = const Color(0xFFEFF6FF),
  });

  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final String price;
  final String? originalPrice;
  final String? badge;
  final double? rating;
  final String? location;
  final String? meta;
  final String category;
  final String description;
  final Color background;
}

@immutable
class TransactionItem {
  const TransactionItem({
    required this.id,
    required this.emoji,
    required this.label,
    required this.category,
    required this.amount,
    required this.date,
  });

  final String id;
  final String emoji;
  final String label;
  final String category;
  final int amount;
  final String date;
}

@immutable
class ExpenseCategory {
  const ExpenseCategory({
    required this.label,
    required this.percentage,
    required this.color,
    required this.spent,
  });

  final String label;
  final int percentage;
  final Color color;
  final int spent;
}

@immutable
class NoteItem {
  const NoteItem({
    required this.id,
    required this.title,
    required this.body,
    required this.color,
    required this.date,
  });

  final int id;
  final String title;
  final String body;
  final Color color;
  final String date;
}

@immutable
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
    required this.unread,
  });

  final String id;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;
  final bool unread;
}

@immutable
class MoreMenuItem {
  const MoreMenuItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.color,
  });

  final String label;
  final String route;
  final IconData icon;
  final Color color;
}

@immutable
class MoreMenuSection {
  const MoreMenuSection({required this.title, required this.items});

  final String title;
  final List<MoreMenuItem> items;
}
