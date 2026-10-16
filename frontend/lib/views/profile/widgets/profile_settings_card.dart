import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class ProfileSettingsCard extends StatelessWidget {
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  const ProfileSettingsCard({
    super.key,
    required this.onChangePassword,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.velocitySurface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
        ),
        child: Column(
          children: [
            ListTile(
              leading:
                  const Icon(Icons.lock_reset_rounded, color: AppTheme.velocityTextSecondary),
              title: const Text('Change Password',
                  style: TextStyle(color: AppTheme.velocityTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.velocityTextMuted),
              onTap: onChangePassword,
            ),
            const Divider(color: AppTheme.velocityBorder, height: 1),
            ListTile(
              leading:
                  const Icon(Icons.logout_rounded, color: AppTheme.velocityAccentCoral),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  color: AppTheme.velocityAccentCoral,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: onLogout,
            ),
            const Divider(color: AppTheme.velocityBorder, height: 1),
            ListTile(
              leading: Icon(Icons.delete_forever_rounded,
                  color: AppTheme.velocityAccentCoral.withValues(alpha: 0.8)),
              title: Text('Delete Account',
                  style: TextStyle(color: AppTheme.velocityAccentCoral.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.bold)),
              onTap: onDeleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}
