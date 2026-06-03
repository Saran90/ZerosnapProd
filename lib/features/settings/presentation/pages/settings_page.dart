import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/shared_preferences_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/version_text.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _prefs = SharedPreferencesProvider();
  static const platform = MethodChannel('com.zerosnap.app/cache');

  String _username = '';
  String _hotelName = '';
  String _baseUrl = '';
  bool _loading = true;
  bool _clearUrlOnLogout = true; // default: clear everything on logout

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = await _prefs.getLoginSession();
    final url = await _prefs.getBaseUrl();
    final clearUrl = await _prefs.getClearUrlOnLogout();
    if (!mounted) return;
    setState(() {
      _username = session?.username ?? '';
      _hotelName = session?.hotelName ?? '';
      _baseUrl = url;
      _clearUrlOnLogout = clearUrl;
      _loading = false;
    });
  }

  // ── Clear cache ───────────────────────────────────────────────────────────
  Future<void> _clearNativeCache() async {
    try {
      await platform.invokeMethod('clearCache');
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing cache: ${e.message}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all temporary data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final url = _baseUrl;
              final token = await _prefs.getAccessToken();
              final apiKey = await _prefs.getApiKey();
              final session = await _prefs.getLoginSession();
              await _prefs.clear();
              await _prefs.saveBaseUrl(url);
              await _prefs.saveAccessToken(token);
              await _prefs.saveApiKey(apiKey);
              if (session != null) await _prefs.saveLoginSession(session);

              if (mounted) {
                imageCache.clear();
                imageCache.clearLiveImages();
              }

              await _clearNativeCache();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (_clearUrlOnLogout) {
                // Clear everything — login page will show domain entry step
                await _prefs.clear();
              } else {
                // Keep base URL — login page will pre-fill it and show credentials step
                final url = _baseUrl;
                await _prefs.clear();
                await _prefs.saveBaseUrl(url);
                // Restore the toggle preference too so it survives logout
                await _prefs.saveClearUrlOnLogout(false);
              }
              if (mounted) context.go(AppRoutes.login);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Profile card ──────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.12,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 30,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _username.isNotEmpty ? _username : 'User',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            if (_hotelName.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                _hotelName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── General section ───────────────────────────────────────
                  _SectionLabel(label: 'General'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.link_rounded,
                        iconColor: AppColors.primary,
                        title: 'Domain URL',
                        subtitle: _baseUrl.isNotEmpty ? _baseUrl : 'Not set',
                        onTap: () {},
                        showChevron: false,
                      ),
                      _TileDivider(),
                      _SettingsTile(
                        icon: Icons.settings_rounded,
                        iconColor: Colors.grey.shade600,
                        title: 'System Settings',
                        subtitle: 'Open device settings',
                        onTap: () => AppSettings.openAppSettings(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Account section ───────────────────────────────────────
                  _SectionLabel(label: 'Account'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.lock_outline_rounded,
                        iconColor: AppColors.primary,
                        title: 'FRRO Credentials',
                        subtitle: 'Manage FRRO login details',
                        onTap: () => context.push('/settings/frro-credentials'),
                      ),
                      _TileDivider(),
                      _SettingsTile(
                        icon: Icons.cleaning_services_rounded,
                        iconColor: Colors.orange.shade600,
                        title: 'Clear Cache',
                        subtitle: 'Remove all temporary data',
                        onTap: _clearCache,
                      ),
                      _TileDivider(),
                      _ToggleTile(
                        icon: Icons.link_off_rounded,
                        iconColor: Colors.purple.shade400,
                        title: 'Reset URL on Logout',
                        subtitle: _clearUrlOnLogout
                            ? 'Logout will return to domain entry'
                            : 'Logout will return to login screen',
                        value: _clearUrlOnLogout,
                        onChanged: (val) async {
                          setState(() => _clearUrlOnLogout = val);
                          await _prefs.saveClearUrlOnLogout(val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Logout ────────────────────────────────────────────────
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.logout_rounded,
                        iconColor: Colors.red,
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        titleColor: Colors.red,
                        onTap: _logout,
                        showChevron: false,
                      ),
                    ],
                  ),

                  // ── Version ───────────────────────────────────────────────
                  const SizedBox(height: 24),
                  Center(
                    child: VersionText(
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Card wrapper that groups tiles ────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(children: children),
    );
  }
}

// ── Thin divider between tiles inside a card ──────────────────────────────────
class _TileDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 56, endIndent: 0);
  }
}

// ── Individual settings tile ──────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? const Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Toggle settings tile ──────────────────────────────────────────────────────
class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
