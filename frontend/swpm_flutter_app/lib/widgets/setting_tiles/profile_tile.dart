import 'package:flutter/material.dart';

class ProfileTile extends StatelessWidget {
  final Widget Function({required String title, required List<Widget> children})
      buildSection;
  final Widget Function({required String title, required Widget trailing})
      buildListTile;
  final Widget Function(String title, String? value) buildReadOnlyTile;
  final Widget Function({
    required String displayValue,
    required VoidCallback onTap,
    Color background,
  }) buildTiledContainer;

  // Profile data
  final String? username;
  final double? weight;
  final double? height;

  // Callback for updates
  final Function(String field, double value) onUpdateValue;

  const ProfileTile({
    super.key,
    required this.buildSection,
    required this.buildListTile,
    required this.buildReadOnlyTile,
    required this.buildTiledContainer,
    required this.username,
    required this.weight,
    required this.height,
    required this.onUpdateValue,
  });

  @override
  Widget build(BuildContext context) {
    return buildSection(
      title: 'Profile',
      children: [
        buildReadOnlyTile("Username", username),
        _buildProfileTile(context, "Weight", weight ?? 80.0, 0.0, 125.0, "kg"),
        _buildProfileTile(context, "Height", height ?? 170.0, 0.0, 200.0, "cm"),
      ],
    );
  }

  Widget _buildProfileTile(BuildContext context, String title,
      double currentValue, double min, double max, String unit) {
    return buildListTile(
        title: title,
        trailing: buildTiledContainer(
          displayValue: "${currentValue.toStringAsFixed(2)} $unit",
          onTap: () =>
              _showTargetDialog(context, title, currentValue, min, max, unit),
          background: const Color.fromARGB(33, 22, 135, 188),
        ));
  }

  void _showTargetDialog(BuildContext context, String title,
      double currentValue, double min, double max, String unit) {
    showDialog(
      context: context,
      builder: (context) {
        double tempValue = currentValue;
        return AlertDialog(
          title: Text(title),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${tempValue.toStringAsFixed(1)} $unit',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 22, 135, 188),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: tempValue,
                    min: min,
                    max: max,
                    divisions: 40,
                    onChanged: (value) =>
                        setDialogState(() => tempValue = value),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                onUpdateValue(title, tempValue);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
