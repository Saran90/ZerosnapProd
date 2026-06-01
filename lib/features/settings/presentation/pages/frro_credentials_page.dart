import 'package:flutter/material.dart';

import '../../../../core/config/api_constants.dart';
import '../../../../core/network/api_base_helper.dart';
import '../../../../core/network/shared_preferences_provider.dart';
import '../../../../core/theme/app_colors.dart';

class FrroCredentialsPage extends StatefulWidget {
  const FrroCredentialsPage({super.key});

  @override
  State<FrroCredentialsPage> createState() => _FrroCredentialsPageState();
}

class _FrroCredentialsPageState extends State<FrroCredentialsPage> {
  final _prefs = SharedPreferencesProvider();
  final _api = ApiBaseHelper();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = true;
  bool _isSaving = false;
  bool _isSyncing = false;
  bool _showPassword = false;
  bool _showSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Load stored credentials ───────────────────────────────────────────────
  Future<void> _loadCredentials() async {
    try {
      final session = await _prefs.getLoginSession();
      if (!mounted) return;
      setState(() {
        if (session != null) {
          _usernameController.text = session.frroUsername;
          _passwordController.text = session.frroPassword;
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showErrorSnackBar('Error loading credentials: $e');
      }
    }
  }

  // ── Save credentials locally ──────────────────────────────────────────────
  Future<void> _saveCredentials() async {
    if (_usernameController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final session = await _prefs.getLoginSession();
      if (session != null) {
        final updatedSession = LoginSession(
          token: session.token,
          apiKey: session.apiKey,
          country: session.country,
          username: session.username,
          hotelName: session.hotelName,
          userEmail: session.userEmail,
          apiUrl: session.apiUrl,
          frroUsername: _usernameController.text.trim(),
          frroPassword: _passwordController.text.trim(),
          frroDistrictId: session.frroDistrictId,
          showRoomNo: session.showRoomNo,
          showVehicleType: session.showVehicleType,
          showVehicleNo: session.showVehicleNo,
          showContactPersonToVisit: session.showContactPersonToVisit,
          showDepartmentToVisit: session.showDepartmentToVisit,
          showScanNationalCard: session.showScanNationalCard,
          showScanForeignCard: session.showScanForeignCard,
          showGuestSignature: session.showGuestSignature,
          showPrintMobileApp: session.showPrintMobileApp,
          showFrroCheckOutInExt: session.showFrroCheckOutInExt,
          scanByMrz: session.scanByMrz,
        );

        await _prefs.saveLoginSession(updatedSession);

        if (mounted) {
          setState(() {
            _isSaving = false;
            _showSuccessMessage = true;
          });
          _showSuccessSnackBar('FRRO credentials updated successfully');
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showSuccessMessage = false);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Error saving credentials: $e');
      }
    }
  }

  // ── Sync credentials from server ──────────────────────────────────────────
  Future<void> _syncCredentials() async {
    if (!mounted) return;

    setState(() => _isSyncing = true);

    try {
      final token = await _prefs.getAccessToken();
      final baseUrl = await _prefs.getBaseUrl();

      final response =
          await _api.get(
                ApiConstants.getFrroCredentials,
                baseUrl: baseUrl,
                headers: {'Authorization': 'Bearer $token'},
              )
              as Map<String, dynamic>?;

      if (!mounted) return;
      setState(() => _isSyncing = false);

      if (response == null) {
        _showErrorSnackBar('No response from server');
        return;
      }

      final serverUsername = response['FRRO_Username'] as String? ?? '';
      final serverPassword = response['FRRO_Password'] as String? ?? '';

      if (serverUsername.isEmpty && serverPassword.isEmpty) {
        _showErrorSnackBar('Server returned empty credentials');
        return;
      }

      // Show confirmation dialog before replacing current values
      _showSyncConfirmDialog(serverUsername, serverPassword);
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        _showErrorSnackBar('Sync failed: $e');
      }
    }
  }

  // ── Confirmation dialog shown after a successful sync response ────────────
  void _showSyncConfirmDialog(String newUsername, String newPassword) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Credentials?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The server returned new FRRO credentials. '
              'Do you want to replace the current values with these?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _CredentialPreviewRow(label: 'Username', value: newUsername),
            const SizedBox(height: 8),
            _CredentialPreviewRow(label: 'Password', value: newPassword),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        setState(() {
          _usernameController.text = newUsername;
          _passwordController.text = newPassword;
        });
        _showInfoSnackBar(
          'Fields updated. Tap "Save Credentials" to store them.',
        );
      }
    });
  }

  // ── Snack bar helpers ─────────────────────────────────────────────────────
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final busy = _isSaving || _isSyncing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FRRO Credentials'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Text(
                      'Manage your FRRO login credentials here. These credentials '
                      'are used to automatically fill the FRRO login form when you '
                      'access the FRRO page.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Success indicator
                  if (_showSuccessMessage) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Changes saved successfully',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Username field
                  const Text(
                    'FRRO Username',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'Enter FRRO username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      prefixIcon: const Icon(Icons.person),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  const Text(
                    'FRRO Password',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      hintText: 'Enter FRRO password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _showPassword = !_showPassword),
                        child: Icon(
                          _showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: busy ? null : _saveCredentials,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Save Credentials',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sync button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: busy ? null : _syncCredentials,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSyncing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sync, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text(
                                  'Sync from Server',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // How it works section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How it works:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Your FRRO credentials are stored locally on your device\n'
                          '• They are used to automatically fill the FRRO login form\n'
                          '• You can update them at any time using this page\n'
                          '• Use the Sync button to fetch the latest credentials from the server',
                          style: TextStyle(fontSize: 12, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Small widget to preview a credential value in the confirm dialog ──────────
class _CredentialPreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _CredentialPreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
