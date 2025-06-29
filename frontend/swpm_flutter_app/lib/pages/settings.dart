import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swpm_flutter_app/widgets/setting_tiles/account_tile.dart';
import 'package:swpm_flutter_app/widgets/setting_tiles/daily_goal_tile.dart';
import 'package:swpm_flutter_app/widgets/setting_tiles/debug_tile.dart';
import 'package:swpm_flutter_app/widgets/setting_tiles/device_pairing_tile.dart';
import 'package:swpm_flutter_app/widgets/setting_tiles/notifications_tile.dart';
import 'package:swpm_flutter_app/widgets/setting_tiles/profile_tile.dart';
import 'package:swpm_flutter_app/store/user_data.dart';
import 'package:swpm_flutter_app/services/settings_service.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  double? waterTarget;
  double? weight;
  double? height;
  bool? notificationsEnabled;
  String? username;

  late final UserDataNotifier store;

  @override
  void initState() {
    super.initState();
    store = Provider.of<UserDataNotifier>(context, listen: false);
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final data = await SettingsService.fetchUserData();
    if (data == null) return;

    setState(() {
      username = data['username'];
      waterTarget =
          (data['dailyGoalMl'] != null) ? data['dailyGoalMl'] / 1000.0 : null;
      notificationsEnabled = data['notificationsEnabled'];
      weight = (data['weightKg'] as num?)?.toDouble();
      height = (data['heightCm'] as num?)?.toDouble();
    });

    store.updateFromJson(data);
  }

  Future<void> _updateProfile({
    double? weight,
    double? height,
    double? waterTarget,
    bool? notificationsEnabled,
  }) async {
    final success = await SettingsService.updateProfile(
      weight: weight,
      height: height,
      waterTarget: waterTarget,
      notificationsEnabled: notificationsEnabled,
    );

    if (success) {
      if (notificationsEnabled != null) {
        store.updateNotifications(notificationsEnabled);
      }
      if (waterTarget != null) store.updateDailyGoal(waterTarget);
    }
  }

  void updateLocalState(String field, double value) {
    setState(() {
      if (field == 'Height') height = value;
      if (field == 'Weight') weight = value;
      if (field.contains('Daily Goal')) waterTarget = value;
    });

    _updateProfile(
      height: field == 'Height' ? value : null,
      weight: field == 'Weight' ? value : null,
      waterTarget: field.contains('Daily Goal') ? value : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey[50],
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DailyGoalTile(
              buildSection: buildSection,
              buildListTile: buildListTile,
              buildTiledContainer: buildTiledContainer,
              waterTarget: waterTarget,
              onUpdateValue: updateLocalState,
            ),
            const SizedBox(height: 20),
            NotificationsTile(
              buildSection: buildSection,
              buildListTile: buildListTile,
              notificationsEnabled: notificationsEnabled,
              onNotificationChanged: (value) async {
                setState(() {
                  notificationsEnabled = value;
                });
                await _updateProfile(notificationsEnabled: value);
              },
            ),
            const SizedBox(height: 20),
            ProfileTile(
              buildSection: buildSection,
              buildListTile: buildListTile,
              buildReadOnlyTile: buildReadOnlyTile,
              buildTiledContainer: buildTiledContainer,
              username: username,
              weight: weight,
              height: height,
              onUpdateValue: updateLocalState,
            ),
            const SizedBox(height: 20),
            DevicePairingTile(
              buildSection: buildSection,
              buildListTile: buildListTile,
              buildReadOnlyTile: buildReadOnlyTile,
              buildTiledContainer: buildTiledContainer,
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            DebugTile(
              buildSection: buildSection,
              buildListTile: buildListTile,
              buildReadOnlyTile: buildReadOnlyTile,
            ),
            const SizedBox(height: 20),
            AccountTile(
              buildSection: buildSection,
              onLogoutSuccess: () {
                if (mounted) Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSection({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color.fromARGB(29, 0, 0, 0),
              blurRadius: 10,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700]),
            ),
          ),
          ...children.map(
            (child) => Column(
              children: [
                child,
                if (children.indexOf(child) < children.length - 1)
                  Divider(height: 1, color: Colors.grey[200]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTiledContainer({
    required String displayValue,
    required VoidCallback onTap,
    Color background = const Color.fromARGB(33, 22, 135, 188),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(20)),
        child: Text(
          displayValue,
          style: const TextStyle(
            color: Color.fromARGB(255, 22, 135, 188),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget buildListTile({required String title, required Widget trailing}) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  void showTargetDialog(
      String title, double currentValue, double min, double max, String unit) {
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
                updateLocalState(title, tempValue);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget buildReadOnlyTile(String title, String? value) {
    return buildListTile(
      title: title,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color.fromARGB(26, 158, 158, 158),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          value ?? '–',
          style:
              TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
