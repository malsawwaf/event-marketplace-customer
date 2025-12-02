import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../config/app_theme.dart';
import '../../services/language_service.dart';
import '../../l10n/app_localizations.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader(l10n.account),
          _buildListTile(
            icon: Icons.lock_outline,
            title: l10n.changePassword,
            onTap: () => _showChangePasswordDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              l10n.deleteAccount,
              style: const TextStyle(color: Colors.red),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: () => _showDeleteAccountDialog(),
          ),
          const Divider(),

          // Notifications Section
          _buildSectionHeader(l10n.notifications),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(l10n.pushNotifications),
            subtitle: Text(l10n.receiveOrderUpdates),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.email_outlined),
            title: Text(l10n.emailNotifications),
            subtitle: Text(l10n.receiveUpdatesViaEmail),
            value: _emailNotifications,
            onChanged: (value) {
              setState(() => _emailNotifications = value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.sms_outlined),
            title: Text(l10n.smsNotifications),
            subtitle: Text(l10n.receiveUpdatesViaSMS),
            value: _smsNotifications,
            onChanged: (value) {
              setState(() => _smsNotifications = value);
            },
          ),
          const Divider(),

          // Language Section
          _buildSectionHeader(l10n.language),
          Consumer<LanguageService>(
            builder: (context, languageService, child) {
              final l10n = AppLocalizations.of(context);
              return ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.language),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      languageService.isArabic ? l10n.arabic : l10n.english,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: languageService.isArabic,
                      onChanged: (value) async {
                        await languageService.toggleLanguage();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),

          // About Section
          _buildSectionHeader(l10n.about),
          _buildListTile(
            icon: Icons.info_outline,
            title: l10n.aboutApp,
            subtitle: '${l10n.version} 1.0.0',
            onTap: () => _showAboutDialog(),
          ),
          _buildListTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicy,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.privacyPolicyComingSoon)),
              );
            },
          ),
          _buildListTile(
            icon: Icons.description_outlined,
            title: l10n.termsOfService,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.termsOfServiceComingSoon)),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryNavy,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final l10n = AppLocalizations.of(context);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.changePassword),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  decoration: InputDecoration(
                    labelText: l10n.currentPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterCurrentPassword;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterNewPassword;
                    }
                    if (value.length < 6) {
                      return l10n.passwordMustBeAtLeast6Characters;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: l10n.confirmNewPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return l10n.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setState(() => isLoading = true);

                      try {
                        // First verify current password by attempting to sign in
                        final email = supabase.auth.currentUser?.email;
                        if (email == null) throw Exception(l10n.userNotFound);

                        await supabase.auth.signInWithPassword(
                          email: email,
                          password: currentPasswordController.text,
                        );

                        // Update password
                        await supabase.auth.updateUser(
                          UserAttributes(
                            password: newPasswordController.text,
                          ),
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.passwordChangedSuccessfully),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${l10n.error}: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.change),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.aboutAzimahTech),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.version}: 1.0.0'),
            const SizedBox(height: 8),
            Text(l10n.azimahTechEventMarketplace),
            const SizedBox(height: 8),
            Text(l10n.browseAndBookEventServices),
            const SizedBox(height: 16),
            Text(l10n.copyrightAzimahTech),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final l10n = AppLocalizations.of(context);
    bool isConfirmed = false;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.deleteAccountTitle,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.deleteAccountWarning,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildBulletPoint(l10n.deleteAccountBullet1),
                _buildBulletPoint(l10n.deleteAccountBullet2),
                _buildBulletPoint(l10n.deleteAccountBullet3),
                _buildBulletPoint(l10n.deleteAccountBullet4),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.deleteAccount30Days,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: isConfirmed,
                  onChanged: isLoading
                      ? null
                      : (value) {
                          setState(() => isConfirmed = value ?? false);
                        },
                  title: Text(
                    l10n.deleteAccountConfirmCheckbox,
                    style: const TextStyle(fontSize: 14),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.red,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: (!isConfirmed || isLoading)
                  ? null
                  : () async {
                      setState(() => isLoading = true);

                      try {
                        // Get current session token
                        final session = supabase.auth.currentSession;
                        if (session == null) {
                          throw Exception('No active session');
                        }

                        // Call Edge Function to delete account
                        final response = await http.post(
                          Uri.parse(
                            '$supabaseUrl/functions/v1/delete-user-account',
                          ),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer ${session.accessToken}',
                          },
                          body: jsonEncode({'account_type': 'customer'}),
                        );

                        final responseBody = response.body;
                        Map<String, dynamic>? responseData;

                        try {
                          responseData = jsonDecode(responseBody) as Map<String, dynamic>?;
                        } catch (_) {
                          // Response is not valid JSON
                        }

                        if (response.statusCode == 200 && responseData?['success'] == true) {
                          // Sign out locally (ignore errors - user may already be signed out)
                          try {
                            await supabase.auth.signOut();
                          } catch (_) {
                            // Ignore sign out errors - auth user is already deleted
                          }

                          if (context.mounted) {
                            Navigator.pop(context); // Close dialog

                            // Navigate to login and clear stack
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.accountDeletedSuccessfully),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                          return; // Exit early on success
                        } else {
                          throw Exception(responseData?['error'] ?? 'Failed to delete account (${response.statusCode})');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${l10n.errorDeletingAccount}: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.deleteAccountButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
