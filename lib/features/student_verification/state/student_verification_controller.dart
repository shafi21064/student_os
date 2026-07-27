import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentos/features/auth/data/auth_controller.dart';

enum VerificationMethod { universityEmail, studentId }
enum IdReviewStatus { idle, reviewing, verified }

@immutable
class StudentVerificationState {
  const StudentVerificationState({
    this.method = VerificationMethod.universityEmail,
    this.universityEmail = '',
    this.emailSent = false,
    this.emailVerified = false,
    this.studentIdFileName,
    this.idStatus = IdReviewStatus.idle,
  });

  final VerificationMethod method;
  final String universityEmail;
  final bool emailSent;
  final bool emailVerified;
  final String? studentIdFileName;
  final IdReviewStatus idStatus;

  bool get isVerified => emailVerified || idStatus == IdReviewStatus.verified;

  StudentVerificationState copyWith({
    VerificationMethod? method,
    String? universityEmail,
    bool? emailSent,
    bool? emailVerified,
    Object? studentIdFileName = _unset,
    IdReviewStatus? idStatus,
  }) =>
      StudentVerificationState(
        method: method ?? this.method,
        universityEmail: universityEmail ?? this.universityEmail,
        emailSent: emailSent ?? this.emailSent,
        emailVerified: emailVerified ?? this.emailVerified,
        studentIdFileName: identical(studentIdFileName, _unset) ? this.studentIdFileName : studentIdFileName as String?,
        idStatus: idStatus ?? this.idStatus,
      );
}

const _unset = Object();

final studentVerificationProvider = NotifierProvider<StudentVerificationController, StudentVerificationState>(StudentVerificationController.new);

class StudentVerificationController extends Notifier<StudentVerificationState> {
  @override
  StudentVerificationState build() {
    final user = ref.watch(authProvider.select((value) => value.user));
    final university = user?.university.trim() ?? '';
    final fallbackEmail = university.isEmpty ? '' : '${user?.firstName.toLowerCase() ?? 'student'}@${university.toLowerCase().replaceAll(' ', '')}.ac.bd';
    return StudentVerificationState(
      universityEmail: user?.email.isNotEmpty == true ? user!.email : fallbackEmail,
      emailVerified: user?.verified ?? false,
      idStatus: user?.verified == true ? IdReviewStatus.verified : IdReviewStatus.idle,
    );
  }

  void selectMethod(VerificationMethod method) => state = state.copyWith(method: method);

  void updateEmail(String value) {
    state = state.copyWith(universityEmail: value, emailSent: false);
  }

  bool sendVerificationEmail() {
    final email = state.universityEmail.trim();
    if (email.isEmpty || !email.contains('@')) return false;
    state = state.copyWith(emailSent: true);
    return true;
  }

  void confirmEmailVerification() {
    state = state.copyWith(emailVerified: true);
    ref.read(authProvider.notifier).setStudentVerified(true);
  }

  void selectStudentIdFile(String? fileName) {
    state = state.copyWith(studentIdFileName: fileName, idStatus: IdReviewStatus.idle);
  }

  Future<void> submitStudentId() async {
    if (state.studentIdFileName == null) return;
    state = state.copyWith(idStatus: IdReviewStatus.reviewing);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    state = state.copyWith(idStatus: IdReviewStatus.verified);
    ref.read(authProvider.notifier).setStudentVerified(true);
  }
}
