import 'package:flutter/material.dart';

class DailyGoalTile extends StatelessWidget {
  final Widget Function({required String title, required List<Widget> children})
      buildSection;
  final Widget Function({required String title, required Widget trailing})
      buildListTile;
  final Widget Function({
    required String displayValue,
    required VoidCallback onTap,
    Color background,
  }) buildTiledContainer;

  // Daily goal data
  final double? waterTarget;

  // Callback for updates
  final Function(String field, double value) onUpdateValue;

  const DailyGoalTile({
    super.key,
    required this.buildSection,
    required this.buildListTile,
    required this.buildTiledContainer,
    required this.waterTarget,
    required this.onUpdateValue,
  });

  @override
  Widget build(BuildContext context) {
    return buildSection(
      title: 'Daily Goal',
      children: [
        _buildWaterTargetTile(context),
      ],
    );
  }

  Widget _buildWaterTargetTile(BuildContext context) {
    return buildListTile(
      title: "Water Amount",
      trailing: waterTarget != null
          ? buildTiledContainer(
              displayValue: '${waterTarget!.toStringAsFixed(1)}L',
              onTap: () => _showWaterTargetDialog(context),
              background: const Color.fromARGB(33, 22, 135, 188),
            )
          : const Text("–"),
    );
  }

  void _showWaterTargetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        double tempValue = waterTarget ?? 2.0;
        return AlertDialog(
          title: const Text("Set Daily Goal"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${tempValue.toStringAsFixed(1)} Liter',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 22, 135, 188),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: tempValue,
                    min: 0.0,
                    max: 4.0,
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
                onUpdateValue("Set Daily Goal", tempValue);
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
