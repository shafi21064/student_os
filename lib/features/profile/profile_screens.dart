import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studentos/core/constants/app_strings.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/widgets/app_card.dart';
import 'package:studentos/data/demo_data.dart';
import 'package:studentos/features/auth/data/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  var _editing = false;
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _university;
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _name = TextEditingController(text: user?.name ?? AppStrings.student);
    _email = TextEditingController(text: user?.email ?? '');
    _phone = TextEditingController(text: user?.mobile ?? '');
    _university = TextEditingController(text: user?.university ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _university.dispose();
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _toggleEdit() async {
    if (_editing) {
      final error = await ref
          .read(authProvider.notifier)
          .updateProfile(
            name: _name.text,
            email: _email.text,
            university: _university.text,
            avatarPath: _avatarPath,
          );
      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
        return;
      }
      final user = ref.read(authProvider).user;
      _name.text = user?.name ?? _name.text;
      _email.text = user?.email ?? _email.text;
      _phone.text = user?.mobile ?? _phone.text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved')));
    }
    setState(() {
      _editing = !_editing;
      if (!_editing) _avatarPath = null;
    });
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (!mounted) return;
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read selected image.')),
      );
      return;
    }
    setState(() => _avatarPath = path);
  }

  Future<void> _savePassword() async {
    final error = await ref
        .read(authProvider.notifier)
        .updatePassword(
          oldPassword: _oldPassword.text,
          password: _newPassword.text,
          confirmPassword: _confirmPassword.text,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? 'Password saved')));
    if (error == null) {
      _oldPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final auth = ref.watch(authProvider);
    final university = user?.university.trim();
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        actions: <Widget>[
          TextButton.icon(
            onPressed: auth.isLoading ? null : () => unawaited(_toggleEdit()),
            icon: Icon(
              _editing ? Icons.check_rounded : Icons.edit_outlined,
              size: 18,
            ),
            label: Text(_editing ? 'Save' : 'Edit'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          Center(
            child: Stack(
              children: <Widget>[
                Container(
                  width: 112,
                  height: 112,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: <Color>[AppColors.teal, AppColors.purple],
                    ),
                  ),
                  alignment: Alignment.center,
                  clipBehavior: Clip.antiAlias,
                  child: user?.avatarUrl.isEmpty == false
                      ? Image.network(
                          user!.avatarUrl,
                          width: 112,
                          height: 112,
                          fit: BoxFit.cover,
                        )
                      : Text(
                          user?.initials ?? 'S',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
                if (_editing)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton.filled(
                      onPressed: auth.isLoading
                          ? null
                          : () => unawaited(_pickAvatar()),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user?.name ?? _name.text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                user?.verified == true
                    ? Icons.verified_rounded
                    : Icons.pending_outlined,
                size: 17,
                color: user?.verified == true
                    ? AppColors.teal
                    : AppColors.orange,
              ),
              const SizedBox(width: 5),
              Text(
                user?.verified == true
                    ? 'Verified ${university == null || university.isEmpty ? 'student' : '$university student'}'
                    : 'Student verification pending',
                style: TextStyle(
                  color: user?.verified == true
                      ? AppColors.teal
                      : AppColors.orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              children: <Widget>[
                _ProfileField(
                  icon: Icons.person_outline_rounded,
                  label: 'Full name',
                  controller: _name,
                  editable: _editing,
                ),
                const Divider(height: 24),
                _ProfileField(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  controller: _email,
                  editable: _editing,
                  emptyValue: 'Not added',
                ),
                const Divider(height: 24),
                _ProfileField(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  controller: _phone,
                  editable: false,
                ),
                const Divider(height: 24),
                _ProfileField(
                  icon: Icons.school_outlined,
                  label: 'University',
                  controller: _university,
                  editable: _editing,
                  emptyValue: 'Not added',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: _PasswordSection(
              hasPassword: user?.hasPassword == true,
              loading: auth.isLoading,
              oldPassword: _oldPassword,
              newPassword: _newPassword,
              confirmPassword: _confirmPassword,
              onSave: () => unawaited(_savePassword()),
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Academic Information',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 14),
                _InfoRow(
                  icon: Icons.school_outlined,
                  label: 'University',
                  value: university == null || university.isEmpty
                      ? 'Not added'
                      : university,
                ),
                const SizedBox(height: 12),
                const _InfoRow(
                  icon: Icons.computer_rounded,
                  label: 'Department',
                  value: 'Computer Science & Engineering',
                ),
                const SizedBox(height: 12),
                const _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Study year',
                  value: '3rd Year',
                ),
                const SizedBox(height: 12),
                const _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Student ID',
                  value: 'STU-2001001',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            color: AppColors.purpleSoft,
            onTap: () => context.push('/student-id'),
            child: const Row(
              children: <Widget>[
                Icon(Icons.badge_outlined, color: AppColors.purple, size: 34),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Student verification',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Verify by university email or student ID upload.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.purple),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => context.push('/logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: BorderSide(color: AppColors.danger.withValues(alpha: .35)),
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.icon,
    required this.label,
    required this.controller,
    required this.editable,
    this.emptyValue = 'Not set',
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool editable;
  final String emptyValue;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Icon(icon, color: AppColors.teal),
      const SizedBox(width: 12),
      Expanded(
        child: editable
            ? TextField(
                controller: controller,
                decoration: InputDecoration(labelText: label, isDense: true),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.text.trim().isEmpty
                        ? emptyValue
                        : controller.text,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
      ),
    ],
  );
}

class _PasswordSection extends StatelessWidget {
  const _PasswordSection({
    required this.hasPassword,
    required this.loading,
    required this.oldPassword,
    required this.newPassword,
    required this.confirmPassword,
    required this.onSave,
  });

  final bool hasPassword;
  final bool loading;
  final TextEditingController oldPassword;
  final TextEditingController newPassword;
  final TextEditingController confirmPassword;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        hasPassword ? 'Change password' : 'Add password',
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
      const SizedBox(height: 14),
      if (hasPassword) ...<Widget>[
        _PasswordField(controller: oldPassword, label: 'Current password'),
        const SizedBox(height: 12),
      ],
      _PasswordField(controller: newPassword, label: 'New password'),
      const SizedBox(height: 12),
      _PasswordField(controller: confirmPassword, label: 'Confirm password'),
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed: loading ? null : onSave,
        icon: loading
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.lock_reset_rounded, size: 18),
        label: Text(hasPassword ? 'Change password' : 'Add password'),
      ),
    ],
  );
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: true,
    decoration: InputDecoration(labelText: label, isDense: true),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Icon(icon, size: 20, color: AppColors.muted),
      const SizedBox(width: 11),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ),
    ],
  );
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<bool> _read;

  @override
  void initState() {
    super.initState();
    _read = notifications.map((item) => !item.unread).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(AppStrings.notifications),
      actions: <Widget>[
        TextButton(
          onPressed: () => setState(
            () => _read = List<bool>.filled(notifications.length, true),
          ),
          child: const Text('Mark all read'),
        ),
        const SizedBox(width: 6),
      ],
    ),
    body: ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = notifications[index];
        final read = _read[index];
        return AppCard(
          color: read ? null : item.color.withValues(alpha: .055),
          onTap: () => setState(() => _read[index] = true),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (!read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.time,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
