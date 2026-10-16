import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../viewmodels/auth/auth_session_viewmodel.dart';
import '../../../viewmodels/profile/profile_viewmodel.dart';

class ProfileDialogs {
  static void showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final state = ref.read(profileViewModelProvider);
    final user = state.user;
    final nameCtrl = TextEditingController(text: user?.username ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.velocitySurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.velocityBorder, width: 1.2),
        ),
        title: const Text('Edit Profile',
            style: TextStyle(color: AppTheme.velocityTextPrimary, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppTheme.velocityTextPrimary),
              decoration: const InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: AppTheme.velocityTextSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              style: const TextStyle(color: AppTheme.velocityTextPrimary),
              decoration: const InputDecoration(
                labelText: 'Email Address',
                labelStyle: TextStyle(color: AppTheme.velocityTextSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                const Text('Cancel', style: TextStyle(color: AppTheme.velocityTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.velocityLime,
              foregroundColor: AppTheme.velocityDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final ok = await ref
                  .read(profileViewModelProvider.notifier)
                  .updateProfile(
                    username: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                  );
              if (ctx.mounted) Navigator.of(ctx).pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'Profile updated successfully!'
                      : 'Failed to update profile.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static void showChangePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.velocitySurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.velocityBorder, width: 1.2),
        ),
        title: const Text('Change Password',
            style: TextStyle(color: AppTheme.velocityTextPrimary, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassCtrl,
              obscureText: true,
              style: const TextStyle(color: AppTheme.velocityTextPrimary),
              decoration: const InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: AppTheme.velocityTextSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              style: const TextStyle(color: AppTheme.velocityTextPrimary),
              decoration: const InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: AppTheme.velocityTextSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                const Text('Cancel', style: TextStyle(color: AppTheme.velocityTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.velocityLime,
              foregroundColor: AppTheme.velocityDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password changed successfully!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  static void showDeleteAccountDialog(
      BuildContext context, AuthSessionViewModel authSession) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.velocitySurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.velocityBorder, width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.velocityAccentCoral),
            SizedBox(width: 8),
            Text('Delete Account?',
                style: TextStyle(
                    color: AppTheme.velocityTextPrimary, fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Text(
          'This action is irreversible. All workout logs, XP, and unlocked achievements will be permanently deleted.',
          style: TextStyle(color: AppTheme.velocityTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                const Text('Cancel', style: TextStyle(color: AppTheme.velocityTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.velocityAccentCoral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await authSession.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}
