import 'package:flutter/material.dart';

class NotificationsTile extends StatelessWidget {
  final Widget Function({required String title, required List<Widget> children})
      buildSection;
  final Widget Function({required String title, required Widget trailing})
      buildListTile;

  // Notification data
  final bool? notificationsEnabled;

  // Callback for updates
  final Function(bool value) onNotificationChanged;

  const NotificationsTile({
    super.key,
    required this.buildSection,
    required this.buildListTile,
    required this.notificationsEnabled,
    required this.onNotificationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return buildSection(
      title: 'Notifications',
      children: [
        _buildNotificationToggle(),
      ],
    );
  }

  Widget _buildNotificationToggle() {
    return buildListTile(
      title: "Notifications",
      trailing: Switch(
        value: notificationsEnabled ?? false,
        onChanged: onNotificationChanged,
        activeColor: const Color.fromARGB(255, 22, 135, 188),
      ),
    );
  }
}
