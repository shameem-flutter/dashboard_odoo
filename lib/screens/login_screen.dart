import 'package:dashboard_odoo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/ip_config_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Theme & Constants
// ─────────────────────────────────────────────────────────────────────────────

class _AppTheme {
  _AppTheme._();

  // Background (Light Theme)
  static const Color bgLight = Color(0xFFF4F7F6);
  static const Color glow1 = Color(0xFFFFFFFF); // Pure white glow
  static const Color glow2 = Color(0xFFCCFBF1); // Very soft teal glow

  // UI (High Contrast)
  static const Color primary = Color(0xFF0D9488); // Darker teal for readability
  static const Color textMain = Color(0xFF0F172A); // Dark slate
  static const Color textMuted = Color(0xFF64748B); // Medium gray
  static const Color inputBorder = Color(0xFFCBD5E1); // Soft gray border
  static const Color error = Color(0xFFEF4444);

  // Durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 700);
}

// ─────────────────────────────────────────────────────────────────────────────
// LoginScreen
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ── Form ──────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _databaseCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _databaseFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // ── State ─────────────────────────────────────────────────────────
  bool _obscurePassword = true;
  bool _isLoading = false;

  // ── Animations ────────────────────────────────────────────────────
  late final AnimationController _enterCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // ─────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Switched to dark icons for the light background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _enterCtrl = AnimationController(vsync: this, duration: _AppTheme.medium);
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) => _enterCtrl.forward());
  }

  @override
  void dispose() {
    _databaseCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _databaseFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    final success = await authService.login(
      db: _databaseCtrl.text.trim(),
      login: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged in successfully'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
      // main.dart will automatically switch to DashboardScreen
      // because it listens to AuthService.
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed. Please check your credentials.'),
          backgroundColor: _AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppTheme.bgLight,
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_AppTheme.glow1, _AppTheme.bgLight, _AppTheme.glow2],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 40,
                          ),
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: _LoginFormContent(
                                formKey: _formKey,
                                databaseCtrl: _databaseCtrl,
                                emailCtrl: _emailCtrl,
                                passwordCtrl: _passwordCtrl,
                                databaseFocus: _databaseFocus,
                                emailFocus: _emailFocus,
                                passwordFocus: _passwordFocus,
                                obscurePassword: _obscurePassword,
                                isLoading: _isLoading,
                                onTogglePassword: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                onLogin: _handleLogin,
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
            Positioned(
              top: 10,
              right: 10,
              child: SafeArea(
                child: IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const IpConfigDialog(),
                    );
                  },
                  icon: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _AppTheme.primary,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'IP',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  tooltip: 'Configure IP Address',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginFormContent extends StatelessWidget {
  const _LoginFormContent({
    required this.formKey,
    required this.databaseCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.databaseFocus,
    required this.emailFocus,
    required this.passwordFocus,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController databaseCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final FocusNode databaseFocus;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _HeaderSection(),
          const SizedBox(height: 32), // Reduced header spacing

          _LoginField(
            controller: databaseCtrl,
            focusNode: databaseFocus,
            label: 'Database',
            icon: Icons.dns_outlined,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).requestFocus(emailFocus),
          ),
          const SizedBox(height: 12),

          _LoginField(
            controller: emailCtrl,
            focusNode: emailFocus,
            label: 'Username',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(passwordFocus),
          ),
          const SizedBox(height: 12),

          _LoginField(
            controller: passwordCtrl,
            focusNode: passwordFocus,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            obscureText: obscurePassword,
            onToggleVisibility: onTogglePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onLogin(),
          ),

          // Forgot password
          // Align(
          //   alignment: Alignment.centerRight,
          //   child: TextButton(
          //     onPressed: () {},
          //     style: TextButton.styleFrom(
          //       foregroundColor: _AppTheme.textMuted,
          //       padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          //       minimumSize: Size.zero,
          //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          //     ),
          //     child: const Text(
          //       'Forgot Password?',
          //       style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          //     ),
          //   ),
          // ),
          const SizedBox(height: 32),

          _SignInButton(isLoading: isLoading, onPressed: onLogin),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 110,
          width: 110,
          decoration: BoxDecoration(
            color: _AppTheme.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: _AppTheme.primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/logo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.hub_rounded,
                color: _AppTheme.primary,
                size: 34,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Odoo Dashboard',
          style: GoogleFonts.poppins(
            color: _AppTheme.textMain,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign in to your workspace',
          style: TextStyle(
            color: _AppTheme.textMuted,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _LoginField extends StatefulWidget {
  const _LoginField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<_LoginField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
    if (widget.focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.3,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;

    return AnimatedContainer(
      duration: _AppTheme.fast,
      decoration: BoxDecoration(
        color: focused
            ? Colors.white
            : const Color(0xFFFFFFFF).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: focused ? _AppTheme.primary : _AppTheme.inputBorder,
          width: 1.2,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: _AppTheme.primary.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        style: const TextStyle(
          color: _AppTheme.textMain,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (widget.isPassword && v.length < 4) return 'Too short';
          return null;
        },
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: focused ? _AppTheme.primary : _AppTheme.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            widget.icon,
            color: focused ? _AppTheme.primary : _AppTheme.textMuted,
            size: 18,
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    widget.obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: focused ? _AppTheme.primary : _AppTheme.textMuted,
                    size: 18,
                  ),
                  onPressed: widget.onToggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          errorStyle: const TextStyle(color: _AppTheme.error, height: 0.8),
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _AppTheme.primary,
          disabledBackgroundColor: _AppTheme.primary.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: AnimatedSwitcher(
          duration: _AppTheme.fast,
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('load'),
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                )
              : const Text(
                  key: ValueKey('idle'),
                  'Sign In',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
