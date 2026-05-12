import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/shared_preferences_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _prefs = SharedPreferencesProvider();

  String _username = '';
  String _hotelName = '';
  String _baseUrl = '';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = await _prefs.getLoginSession();
    final url = await _prefs.getBaseUrl();
    if (!mounted) return;
    setState(() {
      _username = session?.username ?? '';
      _hotelName = session?.hotelName ?? '';
      _baseUrl = url;
      _loading = false;
    });
  }

  // ── Clear cache ───────────────────────────────────────────────────────────
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
              // Preserve credentials — only clear temp/cache keys
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
              await _prefs.clear();
              if (mounted) context.go(AppRoutes.login);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          : Column(
              children: [
                // ── User profile row ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: Color(0xFFE0E0E0),
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.black54,
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
                          if (_hotelName.isNotEmpty)
                            Text(
                              _hotelName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // ── Settings list ─────────────────────────────────────────
                Expanded(
                  child: ListView(
                    children: [
                      _SettingsTile(
                        title: 'HTTPS Address',
                        subtitle: _baseUrl.isNotEmpty ? _baseUrl : 'Not set',
                        onTap: () {}, // Disabled - no editing allowed
                      ),
                      const Divider(height: 1, indent: 16),
                      _SettingsTile(
                        title: 'System Settings',
                        subtitle: 'Open device settings',
                        onTap: () => AppSettings.openAppSettings(),
                      ),
                      const Divider(height: 1, indent: 16),
                      _SettingsTile(
                        title: 'Clear Cache',
                        subtitle: 'This will clear all temporary data',
                        onTap: _clearCache,
                      ),
                      const Divider(height: 1, indent: 16),

                      // Logout
                      ListTile(
                        onTap: _logout,
                        leading: const Icon(
                          Icons.logout_rounded,
                          color: Colors.red,
                          size: 22,
                        ),
                        title: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Version ───────────────────────────────────────────────
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 8),
                    child: Text(
                      'version 1.0',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Reusable settings tile ────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
    );
  }
}
