import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/notification_service.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/addresses_screen.dart';
import '../profile/settings_screen.dart';
import '../profile/help_support_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.customerProfile;
    final user = authProvider.user;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.logout),
                  content: Text(l10n.areYouSureLogout),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text(l10n.logout),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // Clear notification data before logout
                final notificationService = context.read<NotificationService>();
                await notificationService.deleteToken();
                notificationService.clear();

                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: profile == null
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryNavy))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.primaryNavy.withOpacity(0.1),
                    backgroundImage: profile['profile_image_url'] != null
                        ? NetworkImage(profile['profile_image_url'])
                        : null,
                    child: profile['profile_image_url'] == null
                        ? Icon(
                            Icons.person,
                            size: 60,
                            color: AppTheme.primaryNavy,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Name
                  Text(
                    '${profile['first_name']} ${profile['last_name']}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Email
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Phone
                  Text(
                    profile['phone'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Profile Options
                  _buildProfileOption(
                    context,
                    l10n: l10n,
                    icon: Icons.edit,
                    title: l10n.editProfile,
                    subtitle: l10n.updateProfile,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),

                  _buildProfileOption(
                    context,
                    l10n: l10n,
                    icon: Icons.location_on,
                    title: l10n.manageAddresses,
                    subtitle: l10n.addOrEditDeliveryAddresses,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddressesScreen(),
                        ),
                      );
                    },
                  ),

                  _buildProfileOption(
                    context,
                    l10n: l10n,
                    icon: Icons.settings,
                    title: l10n.settings,
                    subtitle: l10n.appPreferencesAndSecurity,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),

                  _buildProfileOption(
                    context,
                    l10n: l10n,
                    icon: Icons.help_outline,
                    title: l10n.helpAndSupport,
                    subtitle: l10n.getHelpOrContactUs,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),

                  _buildProfileOption(
                    context,
                    l10n: l10n,
                    icon: Icons.info_outline,
                    title: l10n.about,
                    subtitle: l10n.appVersionAndInformation,
                    onTap: () {
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
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required AppLocalizations l10n,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryNavy.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryNavy,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }
}
