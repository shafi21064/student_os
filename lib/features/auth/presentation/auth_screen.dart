import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentos/core/constants/app_strings.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/features/auth/data/auth_controller.dart';

enum _AuthStep { tabs, signInOtp, signUpOtp, forgot, resetOtp, newPassword }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _newConfirmPasswordController = TextEditingController();

  late final TabController _tabController;
  _AuthStep _step = _AuthStep.tabs;
  String _countryCode = '+880';
  bool _loginWithPassword = false;
  bool _rememberMe = false;
  bool _showPassword = false;
  bool _showNewPassword = false;
  bool _showNewConfirmPassword = false;

  static const _countries = <_CountryCode>[
    _CountryCode('+880', 'BD'),
    // _CountryCode('+91', 'IN'),
    // _CountryCode('+92', 'PK'),
    // _CountryCode('+977', 'NP'),
    // _CountryCode('+94', 'LK'),
    // _CountryCode('+975', 'BT'),
    // _CountryCode('+960', 'MV'),
    // _CountryCode('+95', 'MM'),
    // _CountryCode('+86', 'CN'),
    // _CountryCode('+81', 'JP'),
    // _CountryCode('+82', 'KR'),
    // _CountryCode('+62', 'ID'),
    // _CountryCode('+60', 'MY'),
    // _CountryCode('+65', 'SG'),
    // _CountryCode('+66', 'TH'),
    // _CountryCode('+84', 'VN'),
    // _CountryCode('+63', 'PH'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _newConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final controller = ref.read(authProvider.notifier);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ListView(
                padding: const EdgeInsets.all(24),
                shrinkWrap: true,
                children: <Widget>[
                  const _HeaaderPart(),
                  const SizedBox(height: 32),
                  if (_step == _AuthStep.tabs)
                    _AuthTabsCard(
                      tabController: _tabController,
                      login: _loginForm(controller, auth),
                      register: _signUpForm(controller, auth),
                    )
                  else
                    _StepCard(child: _stepBody(controller, auth)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepBody(AuthController controller, AuthState auth) {
    switch (_step) {
      case _AuthStep.signInOtp:
        return _otpForm(
          title: 'Verify Yourself',
          subtitle: 'Enter the OTP code sent to your phone.',
          buttonText: 'Verify',
          auth: auth,
          onVerify: () =>
              unawaited(controller.verifySignInOtp(_otpController.text)),
          onResend: () => unawaited(
            controller.sendSignInOtp(
              countryCode: _countryCode,
              mobile: _phoneController.text,
            ),
          ),
        );
      case _AuthStep.signUpOtp:
        return _otpForm(
          title: 'Verify Yourself',
          subtitle: 'Enter the OTP code sent to your phone.',
          buttonText: 'Verify',
          auth: auth,
          onVerify: () => unawaited(controller.verify(_otpController.text)),
          onResend: () => unawaited(
            controller.startSignUp(
              name: _nameController.text,
              countryCode: _countryCode,
              mobile: _phoneController.text,
            ),
          ),
        );
      case _AuthStep.forgot:
        return _forgotPasswordForm(controller, auth);
      case _AuthStep.resetOtp:
        return _otpForm(
          title: 'Verify Yourself',
          subtitle: 'Enter the OTP code sent to your phone.',
          buttonText: 'Verify',
          auth: auth,
          onVerify: () => unawaited(
            controller.verifyPasswordResetOtp(_otpController.text).then((_) {
              if (mounted &&
                  ref.read(authProvider).passwordResetVerified &&
                  ref.read(authProvider).error.isEmpty) {
                setState(() => _step = _AuthStep.newPassword);
              }
            }),
          ),
          onResend: () => unawaited(
            controller.sendPasswordResetOtp(
              countryCode: _countryCode,
              mobile: _phoneController.text,
            ),
          ),
        );
      case _AuthStep.newPassword:
        return _newPasswordForm(controller, auth);
      case _AuthStep.tabs:
        return const SizedBox.shrink();
    }
  }

  Widget _loginForm(AuthController controller, AuthState auth) => Form(
    key: _loginFormKey,
    child: AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Feedback(auth),
          const _FieldLabel('Phone'),
          _PhoneField(
            countryCode: _countryCode,
            countries: _countries,
            controller: _phoneController,
            onCountryChanged: (value) =>
                setState(() => _countryCode = value ?? '+880'),
            validator: _validatePhone,
          ),
          if (_loginWithPassword) ...<Widget>[
            const SizedBox(height: 18),
            const _FieldLabel('Password'),
            _AuthInput(
              controller: _passwordController,
              hintText: 'Password',
              obscureText: !_showPassword,
              autofillHints: const <String>[AutofillHints.password],
              validator: _validatePassword,
              suffixIcon: _VisibilityButton(
                showing: _showPassword,
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
              onSubmitted: (_) => _signIn(controller),
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Checkbox(
                      value: _rememberMe,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (value) =>
                          setState(() => _rememberMe = value ?? false),
                    ),
                    const Text('Remember me', style: TextStyle(fontSize: 12)),
                  ],
                ),
                TextButton(
                  onPressed: auth.isLoading
                      ? null
                      : () => _goToStep(_AuthStep.forgot, controller),
                  child: const Text('Forget Password?'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          _PrimaryButton(
            text: _loginWithPassword ? 'Login' : 'Send OTP',
            loading: auth.isLoading,
            onPressed: _loginWithPassword
                ? () => _signIn(controller)
                : () => _sendSignInOtp(controller),
          ),
          const SizedBox(height: 28),
          const _DividerLabel('Or Login With'),
          const SizedBox(height: 12),
          _SecondaryButton(
            text: _loginWithPassword ? 'Login with OTP' : 'Login with Password',
            onPressed: auth.isLoading
                ? null
                : () {
                    controller.clearFeedback();
                    setState(() => _loginWithPassword = !_loginWithPassword);
                  },
          ),
          const SizedBox(height: 14),
          // _SocialButton(
          //   text: 'Login with Google',
          //   icon: const _GoogleMark(),
          //   onPressed: auth.isLoading ? null : controller.onPressedGoogleLogin,
          // ),
          if (!_isAndroid) ...<Widget>[
            const SizedBox(height: 12),
            _SocialButton(
              text: 'Login with Apple',
              icon: const Icon(Icons.apple_rounded, size: 21),
              onPressed: auth.isLoading ? null : controller.onPressedAppleLogin,
            ),
          ],
          const SizedBox(height: 20),
          _SwitchPrompt(
            normal: "Don't have an account?",
            action: ' Sign Up',
            onTap: () => _tabController.animateTo(1),
          ),
        ],
      ),
    ),
  );

  Widget _signUpForm(AuthController controller, AuthState auth) => Form(
    key: _signUpFormKey,
    child: AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Feedback(auth),
          const _FieldLabel('Full Name'),
          _AuthInput(
            controller: _nameController,
            hintText: 'Enter your full name',
            autofillHints: const <String>[AutofillHints.name],
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Name is required.'
                : null,
          ),
          const SizedBox(height: 18),
          const _FieldLabel('Phone'),
          _PhoneField(
            countryCode: _countryCode,
            countries: _countries,
            controller: _phoneController,
            onCountryChanged: (value) =>
                setState(() => _countryCode = value ?? '+880'),
            validator: _validatePhone,
          ),
          const SizedBox(height: 20),
          _PrimaryButton(
            text: 'Send OTP',
            loading: auth.isLoading,
            onPressed: () => _startSignUp(controller),
          ),
          const SizedBox(height: 20),
          const _DividerLabel('Or Register With'),
          const SizedBox(height: 12),
          _SocialButton(
            text: 'Signup with Google',
            icon: const _GoogleMark(),
            onPressed: auth.isLoading ? null : controller.onPressedGoogleLogin,
          ),
          if (!_isAndroid) ...<Widget>[
            const SizedBox(height: 12),
            _SocialButton(
              text: 'Signup with Apple',
              icon: const Icon(Icons.apple_rounded, size: 21),
              onPressed: auth.isLoading ? null : controller.onPressedAppleLogin,
            ),
          ],
          const SizedBox(height: 20),
          _SwitchPrompt(
            normal: 'Already have an account?',
            action: ' Login',
            onTap: () => _tabController.animateTo(0),
          ),
        ],
      ),
    ),
  );

  Widget _forgotPasswordForm(AuthController controller, AuthState auth) => Form(
    key: _resetFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _StepHeader(title: 'Forget Password'),
        _Feedback(auth),
        const _FieldLabel('Phone'),
        _PhoneField(
          countryCode: _countryCode,
          countries: _countries,
          controller: _phoneController,
          onCountryChanged: (value) =>
              setState(() => _countryCode = value ?? '+880'),
          validator: _validatePhone,
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          text: 'Send OTP',
          loading: auth.isLoading,
          onPressed: () {
            if (!(_resetFormKey.currentState?.validate() ?? false)) return;
            controller.clearFeedback();
            unawaited(
              controller
                  .sendPasswordResetOtp(
                    countryCode: _countryCode,
                    mobile: _phoneController.text,
                  )
                  .then((_) {
                    if (mounted && ref.read(authProvider).error.isEmpty) {
                      _otpController.clear();
                      setState(() => _step = _AuthStep.resetOtp);
                    }
                  }),
            );
          },
        ),
        const SizedBox(height: 12),
        _TextBackButton(onPressed: () => _goToStep(_AuthStep.tabs, controller)),
      ],
    ),
  );

  Widget _otpForm({
    required String title,
    required String subtitle,
    required String buttonText,
    required AuthState auth,
    required VoidCallback onVerify,
    required VoidCallback onResend,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _StepHeader(title: title, subtitle: subtitle),
      _Feedback(auth),
      _AuthInput(
        controller: _otpController,
        hintText: 'OTP',
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        validator: (value) => RegExp(r'^\d{4,6}$').hasMatch(value?.trim() ?? '')
            ? null
            : 'Enter a valid OTP code.',
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: auth.isLoading ? null : onResend,
        child: const Text('Resend Code'),
      ),
      const SizedBox(height: 16),
      _PrimaryButton(
        text: buttonText,
        loading: auth.isLoading,
        color: AppColors.gray800,
        onPressed: auth.isLoading ? null : onVerify,
      ),
      const SizedBox(height: 12),
      _TextBackButton(
        onPressed: () =>
            _goToStep(_AuthStep.tabs, ref.read(authProvider.notifier)),
      ),
    ],
  );

  Widget _newPasswordForm(AuthController controller, AuthState auth) => Form(
    key: _resetFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _StepHeader(title: 'New Password'),
        _Feedback(auth),
        const _FieldLabel('Password'),
        _AuthInput(
          controller: _newPasswordController,
          hintText: 'New password',
          obscureText: !_showNewPassword,
          validator: _validatePassword,
          suffixIcon: _VisibilityButton(
            showing: _showNewPassword,
            onPressed: () =>
                setState(() => _showNewPassword = !_showNewPassword),
          ),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Retype Password'),
        _AuthInput(
          controller: _newConfirmPasswordController,
          hintText: 'Confirm password',
          obscureText: !_showNewConfirmPassword,
          validator: (value) => value != _newPasswordController.text
              ? 'Confirm Password must be match with Password.'
              : null,
          suffixIcon: _VisibilityButton(
            showing: _showNewConfirmPassword,
            onPressed: () => setState(
              () => _showNewConfirmPassword = !_showNewConfirmPassword,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          text: 'Submit',
          loading: auth.isLoading,
          color: AppColors.gray800,
          onPressed: () {
            if (!(_resetFormKey.currentState?.validate() ?? false)) return;
            unawaited(
              controller
                  .resetPassword(
                    password: _newPasswordController.text,
                    confirmPassword: _newConfirmPasswordController.text,
                  )
                  .then((_) {
                    if (mounted && ref.read(authProvider).error.isEmpty) {
                      _goToStep(_AuthStep.tabs, controller);
                    }
                  }),
            );
          },
        ),
      ],
    ),
  );

  void _signIn(AuthController controller) {
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;
    controller.clearFeedback();
    unawaited(
      controller.signIn(
        countryCode: _countryCode,
        mobile: _phoneController.text,
        password: _passwordController.text,
      ),
    );
  }

  void _sendSignInOtp(AuthController controller) {
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;
    controller.clearFeedback();
    unawaited(
      controller
          .sendSignInOtp(
            countryCode: _countryCode,
            mobile: _phoneController.text,
          )
          .then((_) {
            if (mounted && ref.read(authProvider).error.isEmpty) {
              _otpController.clear();
              setState(() => _step = _AuthStep.signInOtp);
            }
          }),
    );
  }

  void _startSignUp(AuthController controller) {
    if (!(_signUpFormKey.currentState?.validate() ?? false)) return;
    controller.clearFeedback();
    unawaited(
      controller
          .startSignUp(
            name: _nameController.text,
            countryCode: _countryCode,
            mobile: _phoneController.text,
          )
          .then((_) {
            if (mounted && ref.read(authProvider).error.isEmpty) {
              _otpController.clear();
              setState(() => _step = _AuthStep.signUpOtp);
            }
          }),
    );
  }

  void _goToStep(_AuthStep step, AuthController controller) {
    controller.cancelPendingAuth();
    setState(() {
      _step = step;
      _otpController.clear();
      _newPasswordController.clear();
      _newConfirmPasswordController.clear();
      _showNewPassword = false;
      _showNewConfirmPassword = false;
    });
  }

  String? _validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Phone is required.';
    if (_countryCode != '+880') {
      return text.replaceAll(RegExp(r'\D'), '').length >= 6
          ? null
          : 'Invalid Phone';
    }
    final phone = RegExp(r'^(\+88|0088)?(01)[3456789](\d){8}$');
    return phone.hasMatch(text) ? null : 'Invalid Phone';
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password is required.';
    if (text.length < 6) return 'Password must be at least 6 characters long.';
    return null;
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

// class _HeaderLogo extends StatelessWidget {
//   const _HeaderLogo();

//   @override
//   Widget build(BuildContext context) => ClipRRect(
//     borderRadius: BorderRadius.circular(16),
//     child: Image.asset(
//       'assets/branding/studentos_logo.png',
//       width: 96,
//       height: 96,
//       fit: BoxFit.cover,
//     ),
//   );
// }

class _HeaaderPart extends StatelessWidget {
  const _HeaaderPart();

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/branding/studentos_logo.png',
          width: 96,
          height: 96,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        "Welcome to ${AppStrings.appName}",
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _AuthTabsCard extends StatelessWidget {
  const _AuthTabsCard({
    required this.tabController,
    required this.login,
    required this.register,
  });

  final TabController tabController;
  final Widget login;
  final Widget register;

  @override
  Widget build(BuildContext context) => _StepCard(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TabBar(
          controller: tabController,
          indicatorColor: AppColors.brand,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppColors.brand,
          unselectedLabelColor: AppColors.muted,
          labelStyle: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          tabs: const <Widget>[
            Tab(text: 'Login'),
            Tab(text: 'Register'),
          ],
        ),
        const SizedBox(height: 24),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: AnimatedBuilder(
            animation: tabController,
            builder: (context, _) => tabController.index == 0
                ? KeyedSubtree(key: const ValueKey('login'), child: login)
                : KeyedSubtree(
                    key: const ValueKey('register'),
                    child: register,
                  ),
          ),
        ),
      ],
    ),
  );
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF6F7F9),
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: const EdgeInsets.all(24), child: child),
  );
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppColors.brand,
          fontWeight: FontWeight.w900,
        ),
      ),
      if (subtitle != null) ...<Widget>[
        const SizedBox(height: 8),
        Text(
          subtitle!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
      const SizedBox(height: 28),
    ],
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.countryCode,
    required this.countries,
    required this.controller,
    required this.onCountryChanged,
    required this.validator,
  });

  final String countryCode;
  final List<_CountryCode> countries;
  final TextEditingController controller;
  final ValueChanged<String?> onCountryChanged;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SizedBox(
        width: 118,
        child: DropdownButtonFormField<String>(
          initialValue: countryCode,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.brand),
            ),
          ),
          items: countries
              .map(
                (country) => DropdownMenuItem<String>(
                  value: country.code,
                  child: Text(
                    '${country.country} ${country.code}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: onCountryChanged,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _AuthInput(
          controller: controller,
          hintText: AppStrings.mobileExample,
          keyboardType: TextInputType.phone,
          autofillHints: const <String>[
            AutofillHints.telephoneNumber,
            AutofillHints.username,
          ],
          validator: validator,
        ),
      ),
    ],
  );
}

class _AuthInput extends StatelessWidget {
  const _AuthInput({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
    this.autofillHints,
    this.textAlign = TextAlign.start,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final List<String>? autofillHints;
  final TextAlign textAlign;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscureText,
    validator: validator,
    autofillHints: autofillHints,
    textAlign: textAlign,
    onFieldSubmitted: onSubmitted,
    cursorColor: AppColors.brand,
    decoration: InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.brand),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    ),
  );
}

class _VisibilityButton extends StatelessWidget {
  const _VisibilityButton({required this.showing, required this.onPressed});

  final bool showing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: showing ? 'Hide password' : 'Show password',
    onPressed: onPressed,
    icon: Icon(showing ? Icons.visibility : Icons.visibility_off_outlined),
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.color = AppColors.brand,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final Color color;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading ? null : onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: color,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: loading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(text),
  );
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.gray800,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: Text(text),
  );
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  final String text;
  final Widget icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: icon,
    label: Text(text),
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink,
      minimumSize: const Size.fromHeight(52),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const Expanded(child: Divider()),
    ],
  );
}

class _SwitchPrompt extends StatelessWidget {
  const _SwitchPrompt({
    required this.normal,
    required this.action,
    required this.onTap,
  });

  final String normal;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: InkWell(
      onTap: onTap,
      child: RichText(
        text: TextSpan(
          text: normal,
          style: Theme.of(context).textTheme.titleMedium,
          children: <TextSpan>[
            TextSpan(
              text: action,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.brand,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.brand,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TextBackButton extends StatelessWidget {
  const _TextBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
    label: const Text('Back to login'),
  );
}

class _Feedback extends StatelessWidget {
  const _Feedback(this.auth);

  final AuthState auth;

  @override
  Widget build(BuildContext context) {
    final isError = auth.error.isNotEmpty;
    final message = isError ? auth.error : auth.message;
    if (message.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isError
              ? AppColors.danger.withValues(alpha: .08)
              : AppColors.green.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isError ? AppColors.danger : AppColors.greenDark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/icons/google.png', width: 18, height: 18);
}

class _CountryCode {
  const _CountryCode(this.code, this.country);

  final String code;
  final String country;
}
