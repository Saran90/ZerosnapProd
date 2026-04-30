import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/shared_preferences_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _repo = AuthRepository();
  final _prefs = SharedPreferencesProvider();

  final _urlCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _domainVerified = false;
  bool _busy = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final saved = await _prefs.getBaseUrl();
    if (saved.isNotEmpty) _urlCtrl.text = saved;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyDomain() async {
    FocusScope.of(context).unfocus();
    final url = _urlCtrl.text.trim();
    if (!_isValidUrl(url)) {
      _showSnack('Please enter a valid URL (e.g. https://yourdomain.com)');
      return;
    }
    setState(() => _busy = true);
    try {
      final ok = await _repo.verifyDomain(url);
      if (!mounted) return;
      if (ok) {
        await _repo.saveBaseUrl(url);
        setState(() => _domainVerified = true);
      } else {
        _showSnack('Domain verification failed. Please check the URL.');
      }
    } catch (_) {
      _showSnack('Could not reach the server. Please check the URL.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (username.isEmpty || password.isEmpty) {
      _showSnack('Please enter your username and password');
      return;
    }
    setState(() => _busy = true);
    try {
      final url = await _prefs.getBaseUrl();
      final result = await _repo.login(url, username, password);
      if (!mounted) return;
      if (result.success && result.session != null) {
        context.go(AppRoutes.dashboard);
      } else {
        _showSnack(
          result.message?.isNotEmpty == true
              ? result.message!
              : 'Login failed. Please check your credentials.',
        );
      }
    } catch (_) {
      _showSnack('Login failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _isValidUrl(String url) {
    final re = RegExp(
      r'^(https?:\/\/)'
      r'((([a-zA-Z0-9\-]+\.)+[a-zA-Z]{2,})|'
      r'(\d{1,3}(\.\d{1,3}){3}))'
      r'(:\d{1,5})?'
      r'(\/[^\s]*)?$',
    );
    return re.hasMatch(url);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red[700],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),

                      // ── Logo ──────────────────────────────────────
                      Center(
                        child: Image.asset(
                          'assets/icons/logo_zerosnap.png',
                          height: 64,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // ── Heading ───────────────────────────────────
                      const Text(
                        'Welcome back!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _domainVerified
                            ? 'Login to continue'
                            : 'Verify your domain to continue',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Step 1: Domain ────────────────────────────
                      if (!_domainVerified) ...[
                        _InputField(
                          controller: _urlCtrl,
                          hint: 'Domain URL',
                          keyboardType: TextInputType.url,
                          prefixIcon: Icons.language_outlined,
                          onSubmitted: (_) => _verifyDomain(),
                        ),
                      ],

                      // ── Step 2: Credentials ───────────────────────
                      if (_domainVerified) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF7FD),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _urlCtrl.text,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _domainVerified = false),
                                child: const Text(
                                  'Change',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _InputField(
                          controller: _usernameCtrl,
                          hint: 'Username',
                          prefixIcon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        _InputField(
                          controller: _passwordCtrl,
                          hint: 'Password',
                          obscureText: _obscurePassword,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          onSuffixTap: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          onSubmitted: (_) => _login(),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // ── Action button ─────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _busy
                              ? null
                              : (_domainVerified ? _login : _verifyDomain),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            disabledBackgroundColor: AppColors.primary
                                .withValues(alpha: 0.6),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _domainVerified ? 'LOGIN' : 'VERIFY DOMAIN',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),

                      const Spacer(),

                      // ── Version ───────────────────────────────────
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'version 1.0',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Input field ───────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.onSubmitted,
    this.textInputAction = TextInputAction.done,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 20),
          suffixIcon: suffixIcon != null
              ? GestureDetector(
                  onTap: onSuffixTap,
                  child: Icon(suffixIcon, color: Colors.grey[400], size: 20),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
