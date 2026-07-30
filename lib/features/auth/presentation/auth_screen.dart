import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/features/auth/data/auth_controller.dart';

enum _AuthMode { signIn, signUp }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _universityController = TextEditingController();
  final _verificationController = TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  String _countryCode = '+880';
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  static const _countries = <_CountryCode>[
    _CountryCode('+880', '🇧🇩', 'BD'),
    _CountryCode('+91', '🇮🇳', 'IN'),
    _CountryCode('+92', '🇵🇰', 'PK'),
    _CountryCode('+977', '🇳🇵', 'NP'),
    _CountryCode('+94', '🇱🇰', 'LK'),
    _CountryCode('+975', '🇧🇹', 'BT'),
    _CountryCode('+960', '🇲🇻', 'MV'),
    _CountryCode('+95', '🇲🇲', 'MM'),
    _CountryCode('+86', '🇨🇳', 'CN'),
    _CountryCode('+81', '🇯🇵', 'JP'),
    _CountryCode('+82', '🇰🇷', 'KR'),
    _CountryCode('+62', '🇮🇩', 'ID'),
    _CountryCode('+60', '🇲🇾', 'MY'),
    _CountryCode('+65', '🇸🇬', 'SG'),
    _CountryCode('+66', '🇹🇭', 'TH'),
    _CountryCode('+84', '🇻🇳', 'VN'),
    _CountryCode('+63', '🇵🇭', 'PH'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _universityController.dispose();
    _verificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final controller = ref.read(authProvider.notifier);
    final verificationMode =
        _mode == _AuthMode.signUp && auth.pendingSignUp != null;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFFE0F5F5),
              Color(0xFFF8FAFC),
              Color(0xFFF0EDFF),
              Color(0xFFE0FFF6),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Material(
                  elevation: 10,
                  shadowColor: Colors.black.withValues(alpha: .12),
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Center(
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.teal.withValues(
                                      alpha: .18,
                                    ),
                                    width: 4,
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: AppColors.purple.withValues(
                                        alpha: .18,
                                      ),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.asset(
                                  'assets/branding/studentos_logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              verificationMode
                                  ? 'Verify your number'
                                  : _mode == _AuthMode.signIn
                                  ? 'Welcome Back'
                                  : 'Create account',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              verificationMode
                                  ? 'Enter the verification code sent to ${auth.pendingSignUp?.mobile ?? ''}.'
                                  : _mode == _AuthMode.signIn
                                  ? 'Sign in to continue to StudentOS.'
                                  : 'Create your account to continue.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                height: 1.45,
                              ),
                            ),
                            if (auth.error.isNotEmpty ||
                                auth.message.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 16),
                              _FeedbackBanner(
                                message: auth.error.isNotEmpty
                                    ? auth.error
                                    : auth.message,
                                error: auth.error.isNotEmpty,
                              ),
                            ],
                            const SizedBox(height: 20),
                            if (verificationMode)
                              _verificationForm(controller)
                            else if (_mode == _AuthMode.signIn)
                              _signInForm(controller)
                            else
                              _signUpForm(controller),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _signInForm(AuthController controller) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _mobileField(),
      const SizedBox(height: 12),
      TextFormField(
        controller: _passwordController,
        obscureText: !_showPassword,
        autofillHints: const <String>[AutofillHints.password],
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _signIn(controller),
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            onPressed: () => setState(() => _showPassword = !_showPassword),
            icon: Icon(
              _showPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () => _signIn(controller),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF3B2A78),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: const Text('Sign in'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: controller.onPressedGoogleLogin,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        icon: const _GoogleMark(),
        label: const Text('Continue with Google'),
      ),
      const SizedBox(height: 12),
      // Text(
      //   'Demo account: +880 1700000000  •  studentos123',
      //   textAlign: TextAlign.center,
      //   style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
      // ),
      const SizedBox(height: 15),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Text("Don't have an account?"),
          TextButton(
            onPressed: () => _changeMode(_AuthMode.signUp, controller),
            child: const Text('Sign up'),
          ),
        ],
      ),
    ],
  );

  Widget _signUpForm(AuthController controller) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => _changeMode(_AuthMode.signIn, controller),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Back to sign in'),
        ),
      ),
      const SizedBox(height: 4),
      TextFormField(
        controller: _nameController,
        autofillHints: const <String>[AutofillHints.name],
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Full name',
          prefixIcon: Icon(Icons.person_outline_rounded),
        ),
      ),
      const SizedBox(height: 12),
      _mobileField(),
      const SizedBox(height: 12),
      TextFormField(
        controller: _universityController,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'University',
          prefixIcon: Icon(Icons.school_outlined),
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _passwordController,
        obscureText: !_showPassword,
        autofillHints: const <String>[AutofillHints.newPassword],
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            onPressed: () => setState(() => _showPassword = !_showPassword),
            icon: Icon(
              _showPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _confirmPasswordController,
        obscureText: !_showConfirmPassword,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _signUp(controller),
        decoration: InputDecoration(
          labelText: 'Confirm password',
          prefixIcon: const Icon(Icons.lock_reset_rounded),
          suffixIcon: IconButton(
            onPressed: () =>
                setState(() => _showConfirmPassword = !_showConfirmPassword),
            icon: Icon(
              _showConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[AppColors.purple, AppColors.teal],
          ),
          borderRadius: BorderRadius.circular(17),
        ),
        child: FilledButton(
          onPressed: () => _signUp(controller),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          child: const Text('Create account'),
        ),
      ),
    ],
  );

  Widget _verificationForm(AuthController controller) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      TextFormField(
        controller: _verificationController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 8,
        ),
        decoration: const InputDecoration(
          labelText: 'Verification code',
          counterText: '',
          prefixIcon: Icon(Icons.sms_outlined),
        ),
      ),
      const SizedBox(height: 16),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[AppColors.purple, AppColors.teal],
          ),
          borderRadius: BorderRadius.circular(17),
        ),
        child: FilledButton(
          onPressed: () => controller.verify(_verificationController.text),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          child: const Text('Verify and create account'),
        ),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () => _changeMode(_AuthMode.signIn, controller),
        child: const Text('Cancel and return to sign in'),
      ),
    ],
  );

  Widget _mobileField() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SizedBox(
        width: 116,
        child: DropdownButtonFormField<String>(
          initialValue: _countryCode,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Country'),
          items: _countries
              .map(
                (country) => DropdownMenuItem<String>(
                  value: country.code,
                  child: Text(
                    '${country.flag} ${country.code}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (value) => setState(() => _countryCode = value ?? '+880'),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          autofillHints: const <String>[AutofillHints.telephoneNumber],
          decoration: const InputDecoration(
            labelText: 'Mobile number',
            hintText: '1700000000',
          ),
        ),
      ),
    ],
  );

  void _signIn(AuthController controller) {
    controller.clearFeedback();
    controller.signIn(
      countryCode: _countryCode,
      mobile: _mobileController.text,
      password: _passwordController.text,
    );
  }

  void _signUp(AuthController controller) {
    controller.clearFeedback();
    controller.startSignUp(
      name: _nameController.text,
      countryCode: _countryCode,
      mobile: _mobileController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      university: _universityController.text,
    );
  }

  void _changeMode(_AuthMode mode, AuthController controller) {
    controller.clearFeedback();
    setState(() {
      _mode = mode;
      _countryCode = '+880';
      _nameController.clear();
      _mobileController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _universityController.clear();
      _verificationController.clear();
      _showPassword = false;
      _showConfirmPassword = false;
    });
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.message, required this.error});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: error
          ? AppColors.danger.withValues(alpha: .08)
          : AppColors.green.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          error
              ? Icons.error_outline_rounded
              : Icons.check_circle_outline_rounded,
          color: error ? AppColors.danger : AppColors.greenDark,
          size: 19,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: error ? AppColors.danger : AppColors.greenDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/icons/google.png', width: 18, height: 18);
}

class _CountryCode {
  const _CountryCode(this.code, this.flag, this.country);

  final String code;
  final String flag;
  final String country;
}
