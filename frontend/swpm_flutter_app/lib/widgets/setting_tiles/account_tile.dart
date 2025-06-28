import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountTile extends StatelessWidget {
  final Widget Function({required String title, required List<Widget> children})
      buildSection;

  // Callback for logout completion
  final VoidCallback onLogoutSuccess;

  const AccountTile({
    super.key,
    required this.buildSection,
    required this.onLogoutSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return buildSection(
      title: 'Account',
      children: [
        _buildLogoutTile(context),
      ],
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text(
        'Sign Out',
        style: TextStyle(
            fontSize: 16, color: Colors.red, fontWeight: FontWeight.w500),
      ),
      onTap: () => _handleLogout(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _performLogout(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Sign Out',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLogout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();

      // Call the success callback to handle navigation
      onLogoutSuccess();
    } catch (e) {
      // Show error message if logout fails
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }
}
