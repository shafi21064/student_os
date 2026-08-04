import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentos/core/constants/app_strings.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/widgets/app_card.dart';
import 'package:studentos/core/widgets/common_widgets.dart';
import 'package:studentos/features/auth/data/auth_controller.dart';
import 'package:studentos/features/student_verification/state/student_verification_controller.dart';

class StudentIdScreen extends ConsumerWidget {
  const StudentIdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authProvider).user;
    final verification = ref.watch(studentVerificationProvider);
    final controller = ref.read(studentVerificationProvider.notifier);
    final university = authUser?.university.trim();
    final isVerified = verification.isVerified || authUser?.verified == true;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.studentId)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          _StudentIdentityCard(
            name: authUser?.name ?? 'Student',
            initials: authUser?.initials ?? 'S',
            university: university == null || university.isEmpty
                ? 'University not added'
                : university,
            verified: isVerified,
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Verify your student status',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose one way to confirm your university account.',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isVerified)
                      const BadgeLabel(
                        '✓ Verified',
                        color: AppColors.greenDark,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MethodButton(
                        selected:
                            verification.method ==
                            VerificationMethod.universityEmail,
                        icon: Icons.email_outlined,
                        label: 'University email',
                        onTap: () => controller.selectMethod(
                          VerificationMethod.universityEmail,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _MethodButton(
                        selected:
                            verification.method == VerificationMethod.studentId,
                        icon: Icons.upload_file_outlined,
                        label: 'Student ID upload',
                        onTap: () => controller.selectMethod(
                          VerificationMethod.studentId,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (verification.method == VerificationMethod.universityEmail)
                  _EmailVerificationPanel(
                    state: verification,
                    controller: controller,
                  )
                else
                  _IdUploadPanel(state: verification, controller: controller),
              ],
            ),
          ),
          if (isVerified) ...<Widget>[
            const SizedBox(height: 14),
            const _QuickScanCard(),
          ],
          const SizedBox(height: 14),
          const BadgeLabel(
            'Prototype verification flow',
            color: AppColors.orange,
          ),
        ],
      ),
    );
  }
}

class _StudentIdentityCard extends StatelessWidget {
  const _StudentIdentityCard({
    required this.name,
    required this.initials,
    required this.university,
    required this.verified,
  });

  final String name;
  final String initials;
  final String university;
  final bool verified;

  @override
  Widget build(BuildContext context) => Container(
    height: 410,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: <Color>[AppColors.teal, AppColors.purple, AppColors.purpleDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(30),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: AppColors.purple.withValues(alpha: .25),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: Stack(
      children: <Widget>[
        Positioned(
          right: -42,
          top: -50,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: -40,
          bottom: -55,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .07),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.school_rounded, color: Colors.white),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    university,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  verified ? Icons.verified_rounded : Icons.pending_outlined,
                  color: verified
                      ? AppColors.successSoft
                      : AppColors.warningSoft,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .17),
                border: Border.all(color: Colors.white, width: 3),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'Computer Science & Engineering',
              style: TextStyle(color: AppColors.blueSoft, fontSize: 13),
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _IdMetric(label: 'Student ID', value: '2001001'),
                _IdMetric(label: 'Year', value: '3rd'),
                _IdMetric(label: 'Session', value: '2023–24'),
              ],
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    verified
                        ? Icons.verified_user_outlined
                        : Icons.shield_outlined,
                    color: Colors.white,
                    size: 34,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      verified
                          ? 'Verified StudentOS identity\nValid through Dec 2027'
                          : 'Verification required\nComplete one method below',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.blueSoft
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? AppColors.blue
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            size: 20,
            color: selected
                ? AppColors.blue
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: selected
                  ? AppColors.blue
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmailVerificationPanel extends StatelessWidget {
  const _EmailVerificationPanel({
    required this.state,
    required this.controller,
  });

  final StudentVerificationState state;
  final StudentVerificationController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      TextFormField(
        initialValue: state.universityEmail,
        onChanged: controller.updateEmail,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'University email',
          prefixIcon: Icon(Icons.alternate_email_rounded),
          hintText: AppStrings.searchEmail,
        ),
      ),
      const SizedBox(height: 12),
      if (state.emailVerified)
        const _SuccessPanel(text: 'Email verified successfully')
      else if (state.emailSent) ...<Widget>[
        Text(
          'Verification email sent to ${state.universityEmail}.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 9),
        FilledButton(
          onPressed: controller.confirmEmailVerification,
          child: const Text('I verified my email'),
        ),
      ] else
        FilledButton(
          onPressed: () {
            if (!controller.sendVerificationEmail()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enter a valid university email.'),
                ),
              );
            }
          },
          child: const Text('Send verification email'),
        ),
    ],
  );
}

class _IdUploadPanel extends StatelessWidget {
  const _IdUploadPanel({required this.state, required this.controller});

  final StudentVerificationState state;
  final StudentVerificationController controller;

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: false,
    );
    if (!context.mounted || result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.size > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a file smaller than 10 MB.')),
      );
      return;
    }
    controller.selectStudentIdFile(file.name);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      InkWell(
        onTap: () => _pickFile(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 105,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.blueSoft.withValues(alpha: .6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.blue.withValues(alpha: .35),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.upload_file_rounded,
                color: AppColors.blue,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                state.studentIdFileName ?? 'Upload your student ID',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'JPG, PNG or PDF up to 10 MB',
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (state.idStatus == IdReviewStatus.verified)
        const _SuccessPanel(text: 'Student ID verified successfully')
      else if (state.idStatus == IdReviewStatus.reviewing)
        const _ReviewingPanel()
      else
        FilledButton(
          onPressed: state.studentIdFileName == null
              ? null
              : controller.submitStudentId,
          child: const Text('Submit for verification'),
        ),
      const SizedBox(height: 8),
      Text(
        'Your selected file remains local in this prototype. A production build should upload it through an encrypted verification service.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 10,
          height: 1.4,
        ),
      ),
    ],
  );
}

class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.green.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.check_circle_rounded, color: AppColors.greenDark),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReviewingPanel extends StatelessWidget {
  const _ReviewingPanel();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.blueSoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
        SizedBox(width: 9),
        Text(
          'Checking your student ID...',
          style: TextStyle(
            color: AppColors.blue,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _QuickScanCard extends StatelessWidget {
  const _QuickScanCard();

  static const darkCells = <int>{
    0,
    1,
    2,
    3,
    4,
    5,
    9,
    10,
    14,
    15,
    19,
    20,
    21,
    22,
    23,
    24,
    6,
    12,
    18,
  };

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: <Widget>[
        Container(
          width: 70,
          height: 70,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: 25,
            itemBuilder: (context, index) => DecoratedBox(
              decoration: BoxDecoration(
                color: darkCells.contains(index)
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Quick Scan QR',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 4),
              Text(
                'Show this to verify your student status at participating services.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _IdMetric extends StatelessWidget {
  const _IdMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Text(
        label,
        style: const TextStyle(color: AppColors.onBrandSoft, fontSize: 10),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    ],
  );
}
