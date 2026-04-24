import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/n_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscureLogin = true;
  bool _obscureSignup = true;
  bool _obscureConfirm = true;

  // Login controllers
  final _loginEmailCtrl = TextEditingController();
  final _loginPwCtrl = TextEditingController();

  // Signup controllers
  final _signupNameCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPwCtrl = TextEditingController();
  final _signupConfirmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPwCtrl.dispose();
    _signupNameCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPwCtrl.dispose();
    _signupConfirmCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final result = await AuthService.logIn(
      _loginEmailCtrl.text,
      _loginPwCtrl.text,
    );

    setState(() => _loading = false);
    if (!mounted) return;

    if (result.success) {
      final hasSetup = await AuthService.hasCompletedSetup();
      if (!mounted) return;
      if (hasSetup) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
      }
    } else {
      _showError(result.error ?? 'Login failed.');
    }
  }

  // ── Sign up ────────────────────────────────────────────────────────────────
  Future<void> _signup() async {
    FocusScope.of(context).unfocus();

    final name = _signupNameCtrl.text.trim();
    if (name.isEmpty) {
      _showError('Please enter your name.');
      return;
    }
    if (_signupPwCtrl.text != _signupConfirmCtrl.text) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _loading = true);

    final result = await AuthService.signUp(
      _signupEmailCtrl.text,
      _signupPwCtrl.text,
    );

    setState(() => _loading = false);
    if (!mounted) return;

    if (result.success) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.profileSetup,
        arguments: name,
      );
    } else {
      _showError(result.error ?? 'Sign up failed.');
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() => _googleLoading = true);

    final result = await AuthService.signInWithGoogle();

    setState(() => _googleLoading = false);
    if (!mounted) return;

    if (result.success) {
      final hasSetup = await AuthService.hasCompletedSetup();
      if (!mounted) return;
      if (hasSetup) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        final name = result.user?.displayName ?? '';
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.profileSetup,
          arguments: name,
        );
      }
    } else {
      _showError(result.error ?? 'Google sign-in failed.');
    }
  }

  // ── Forgot Password ────────────────────────────────────────────────────────
  Future<void> _showForgotPasswordSheet() async {
    final emailCtrl = TextEditingController(text: _loginEmailCtrl.text.trim());
    bool sending = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            decoration: BoxDecoration(
              color: ctx.surfaceElevated,
              borderRadius: BorderRadius.circular(24),
              border: ctx.isDark
                  ? Border.all(color: ctx.cardBorder, width: 1)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ctx.textHint.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.lock_reset_rounded,
                            color: AppColors.green, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reset Password',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: ctx.textPrimary)),
                          Text("We'll email you a reset link",
                              style: TextStyle(
                                  fontSize: 12, color: ctx.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    style: TextStyle(color: ctx.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Enter your email address',
                      hintStyle:
                          TextStyle(fontSize: 13, color: ctx.textHint),
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: AppColors.green, size: 20),
                      filled: true,
                      fillColor: ctx.inputFill,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: ctx.isDark
                            ? BorderSide(color: ctx.mutedBorder, width: 1)
                            : BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.green, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: sending
                        ? null
                        : () async {
                            final email = emailCtrl.text.trim();
                            if (email.isEmpty) return;
                            setSheet(() => sending = true);
                            final result =
                                await AuthService.sendPasswordReset(email);
                            setSheet(() => sending = false);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (result.success) {
                              _showSuccess(
                                  'Reset link sent! Check your inbox.');
                            } else {
                              _showError(
                                  result.error ?? 'Could not send reset email.');
                            }
                          },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black),
                              )
                            : const Text('Send Reset Link',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            context.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            context.isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: context.pageBg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/app_logo.png',
                        width: 110,
                        height: 110,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.eco_rounded,
                              size: 50, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'NUTRIFY',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Track. Thrive. Nourish.',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.black45,
                            fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                Container(
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: context.isDark
                        ? Border.all(color: context.cardBorder)
                        : null,
                  ),
                  child: TabBar(
                    controller: _tabCtrl,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.black87,
                    unselectedLabelColor: context.textMuted,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Log In'),
                      Tab(text: 'Sign Up'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 540,
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildLoginTab(),
                      _buildSignupTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back!',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 4),
          Text('Log in to continue your health journey.',
              style: TextStyle(fontSize: 13, color: context.textMuted)),
          const SizedBox(height: 24),
          _field(
            controller: _loginEmailCtrl,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _field(
            controller: _loginPwCtrl,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscureLogin,
            onToggleObscure: () =>
                setState(() => _obscureLogin = !_obscureLogin),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _showForgotPasswordSheet,
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                    color: AppColors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _actionButton(
            label: 'Log In',
            loading: _loading,
            onTap: _login,
          ),
          const SizedBox(height: 16),
          _orDivider(),
          const SizedBox(height: 16),
          _googleButton(),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () => _tabCtrl.animateTo(1),
              child: RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(color: context.textMuted, fontSize: 13),
                  children: const [
                    TextSpan(
                      text: 'Sign Up',
                      style: TextStyle(
                          color: Color(0xFF6BCB77),
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create account',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 4),
          Text('Join NUTRIFY and start your journey today.',
              style: TextStyle(fontSize: 13, color: context.textMuted)),
          const SizedBox(height: 24),
          _field(
            controller: _signupNameCtrl,
            hint: 'Full name',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),
          _field(
            controller: _signupEmailCtrl,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _field(
            controller: _signupPwCtrl,
            hint: 'Password (min. 6 characters)',
            icon: Icons.lock_outline_rounded,
            obscure: _obscureSignup,
            onToggleObscure: () =>
                setState(() => _obscureSignup = !_obscureSignup),
          ),
          const SizedBox(height: 14),
          _field(
            controller: _signupConfirmCtrl,
            hint: 'Confirm password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscureConfirm,
            onToggleObscure: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 24),
          _actionButton(
            label: 'Create Account',
            loading: _loading,
            onTap: _signup,
          ),
          const SizedBox(height: 16),
          _orDivider(),
          const SizedBox(height: 16),
          _googleButton(),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () => _tabCtrl.animateTo(0),
              child: RichText(
                text: TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(color: context.textMuted, fontSize: 13),
                  children: const [
                    TextSpan(
                      text: 'Log In',
                      style: TextStyle(
                          color: Color(0xFF6BCB77),
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _orDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: context.textHint.withOpacity(0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: TextStyle(
                color: context.textMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Divider(
            color: context.textHint.withOpacity(0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _googleButton() {
    return GestureDetector(
      onTap: _googleLoading ? null : _signInWithGoogle,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.isDark
                ? context.cardBorder
                : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: _googleLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Google "G" logo rendered with coloured text
                    RichText(
                      text: const TextSpan(
                        style:
                            TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                        children: [
                          TextSpan(
                              text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
                          TextSpan(
                              text: 'o', style: TextStyle(color: Color(0xFFEA4335))),
                          TextSpan(
                              text: 'o', style: TextStyle(color: Color(0xFFFBBC05))),
                          TextSpan(
                              text: 'g', style: TextStyle(color: Color(0xFF4285F4))),
                          TextSpan(
                              text: 'l', style: TextStyle(color: Color(0xFF34A853))),
                          TextSpan(
                              text: 'e', style: TextStyle(color: Color(0xFFEA4335))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Sign in with Google',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: context.textPrimary),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(color: context.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: context.textHint),
        prefixIcon: Icon(icon, color: AppColors.green, size: 20),
        suffixIcon: onToggleObscure != null
            ? GestureDetector(
                onTap: onToggleObscure,
                child: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: context.textHint,
                  size: 20,
                ),
              )
            : null,
        filled: true,
        fillColor: context.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: context.isDark
              ? BorderSide(color: context.mutedBorder, width: 1)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }
}
