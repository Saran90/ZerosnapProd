import 'dart:developer' as dev;

import 'package:flutter/material.dart';

import '../network/shared_preferences_provider.dart';
import '../theme/app_colors.dart';
import '../../features/auth/data/auth_repository.dart';

/// A modal bottom sheet that lets the user re-authenticate after a 401.
///
/// The username is read from the stored session and displayed as a non-editable
/// field — the user only needs to enter their password.
///
/// Call [SessionExpiredSheet.show] from any form page that catches an
/// [UnauthorisedException]. Returns `true` when login succeeds so the caller
/// can immediately retry the failed operation.
class SessionExpiredSheet extends StatefulWidget {
  const SessionExpiredSheet({super.key});

  /// Shows the sheet and returns `true` if the user logged in successfully,
  /// or `false` / `null` if they dismissed it without logging in.
  static Future<bool> show(BuildContext context) async {
    dev.log(
      'SessionExpiredSheet.show: opening bottom sheet',
      name: 'SessionSheet',
    );
    debugPrint('[SessionSheet] show() called — opening bottom sheet');
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SessionExpiredSheet(),
    );
    return result == true;
  }

  @override
  State<SessionExpiredSheet> createState() => _SessionExpiredSheetState();
}

class _SessionExpiredSheetState extends State<SessionExpiredSheet> {
  final _repo = AuthRepository();
  final _prefs = SharedPreferencesProvider();

  final _passwordCtrl = TextEditingController();
  // Username field controller and focus node — created once, never interactive.
  final _usernameCtrl = TextEditingController();
  final _usernameFocusNode = FocusNode();

  // Loaded from SharedPreferences.
  // _userEmail is shown in the read-only field AND passed to the login API.
  String _userEmail = '';

  bool _busy = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    dev.log(
      'SessionExpiredSheet: initState — sheet mounted',
      name: 'SessionSheet',
    );
    debugPrint('[SessionSheet] initState — sheet mounted');
    _usernameFocusNode.canRequestFocus = false;
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await _prefs.getLoginSession();
    if (!mounted) return;
    setState(() {
      _userEmail = session?.userEmail ?? '';
    });
    _usernameCtrl.text = _userEmail;
    dev.log(
      'SessionExpiredSheet._loadSession: userEmail="$_userEmail"',
      name: 'SessionSheet',
    );
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final password = _passwordCtrl.text.trim();
    dev.log(
      'SessionExpiredSheet._login: userEmail="$_userEmail" '
      'password=${password.isEmpty ? "<empty>" : "<provided>"}',
      name: 'SessionSheet',
    );
    if (_userEmail.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password');
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final url = await _prefs.getBaseUrl();
      dev.log(
        'SessionExpiredSheet._login: calling login API at $url',
        name: 'SessionSheet',
      );
      final result = await _repo.login(url, _userEmail, password);
      dev.log(
        'SessionExpiredSheet._login: result success=${result.success} '
        'message=${result.message}',
        name: 'SessionSheet',
      );
      if (!mounted) return;
      if (result.success && result.session != null) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = result.message?.isNotEmpty == true
              ? result.message
              : 'Login failed. Please check your password.';
        });
      }
    } catch (e, st) {
      dev.log(
        'SessionExpiredSheet._login: exception $e',
        name: 'SessionSheet',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        setState(() => _errorMessage = 'Login failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ────────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Header ────────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_clock_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Expired',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Log in again to continue — your form data is safe.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Username / email (read-only TextField) ────────────────────────
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEEF0F4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: TextField(
              controller: _usernameCtrl,
              readOnly: true,
              focusNode: _usernameFocusNode,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondaryLight,
              ),
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: AppColors.textSecondaryLight,
                  size: 20,
                ),
                suffixIcon: Icon(
                  Icons.lock_outline,
                  color: AppColors.textSecondaryLight,
                  size: 16,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Password ──────────────────────────────────────────────────────
          _PasswordField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onSubmitted: (_) => _login(),
          ),

          // ── Error message ─────────────────────────────────────────────────
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // ── Login button ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _busy
                  ? null
                  : () {
                      dev.log(
                        'SessionExpiredSheet: LOG IN button tapped',
                        name: 'SessionSheet',
                      );
                      debugPrint('[SessionSheet] LOG IN button tapped');
                      _login();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.6,
                ),
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
                  : const Text(
                      'LOG IN',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Password field ────────────────────────────────────────────────────────────
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleObscure;
  final ValueChanged<String>? onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.obscureText,
    required this.onToggleObscure,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        textInputAction: TextInputAction.done,
        onSubmitted: onSubmitted,
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimaryLight),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: const TextStyle(
            color: AppColors.textSecondaryLight,
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: AppColors.primary,
            size: 20,
          ),
          suffixIcon: GestureDetector(
            onTap: onToggleObscure,
            child: Icon(
              obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textSecondaryLight,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
