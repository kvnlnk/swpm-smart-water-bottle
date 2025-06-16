import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:swpm_flutter_app/store/user_data.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);
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
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
      if (jwt == null) return;

      final url = Uri.parse("${dotenv.env['API_BASE_URL']}/api/user/information");
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $jwt',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          username = data['username'];
          waterTarget = (data['dailyGoalMl'] != null) ? data['dailyGoalMl'] / 1000.0 : null;
          notificationsEnabled = data['notificationsEnabled'];
          weight = (data['weightKg'] as num?)?.toDouble();
          height = (data['heightCm'] as num?)?.toDouble();
        });

        store.updateFromJson(data);
      }
    } catch (_) {}
  }

  Future<void> updateProfile({
    double? weight,
    double? height,
    double? waterTarget,
    bool? notificationsEnabled,
  }) async {
    final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
    if (jwt == null) return;

    final url = Uri.parse("${dotenv.env['API_BASE_URL']}/api/user/profile/update");

    final body = {
      if (weight != null) 'WeightKg': weight.round(),
      if (height != null) 'HeightCm': height.round(),
      if (waterTarget != null) 'DailyGoalMl': (waterTarget * 1000).round(),
      if (notificationsEnabled != null) 'NotificationsEnabled': notificationsEnabled,
    };

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        if (notificationsEnabled != null) store.updateNotifications(notificationsEnabled);
        if (waterTarget != null) store.updateDailyGoal(waterTarget);
      }
    } catch (_) {}
  }

  void updateLocalState(String field, double value) {
    setState(() {
      if (field == 'Height') height = value;
      if (field == 'Weight') weight = value;
      if (field.contains('Daily Goal')) waterTarget = value;
    });

    updateProfile(
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
            buildSection(title: 'Daily Goal', children: [buildWaterTargetTile()]),
            const SizedBox(height: 20),
            buildSection(title: 'Notifications', children: [buildNotificationToggle()]),
            const SizedBox(height: 20),
            buildSection(
              title: 'Profile',
              children: [
                buildReadOnlyTile("Username", username),
                buildProfileTile("Weight", weight, 0.0, 125.0, "kg"),
                buildProfileTile("Height", height, 0.0, 200.0, "cm"),
              ],
            ),
            const SizedBox(height: 20),
            buildSection(title: 'Account', children: [buildLogoutTile()]),
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
          BoxShadow(color: Color.fromARGB(29, 0, 0, 0), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
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

  Widget buildProfileTile(String title, double? currentValue, double min, double max, String unit) {
    return buildListTile(
      title: title,
      trailing: currentValue != null
          ? buildTiledContainer(
        displayValue: "${currentValue.toStringAsFixed(2)} $unit",
        onTap: () => showTargetDialog(title, currentValue, min, max, unit),
      )
          : const Text("–"),
    );
  }

  Widget buildWaterTargetTile() {
    return buildListTile(
      title: "Water Amount",
      trailing: waterTarget != null
          ? buildTiledContainer(
        displayValue: '${waterTarget!.toStringAsFixed(1)}L',
        onTap: () => showTargetDialog("Set Daily Goal", waterTarget!, 0.0, 4.0, "Liter"),
      )
          : const Text("–"),
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
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
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

  void showTargetDialog(String title, double currentValue, double min, double max, String unit) {
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
                    onChanged: (value) => setDialogState(() => tempValue = value),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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

  Widget buildNotificationToggle() {
    return buildListTile(
      title: "Notifications",
      trailing: Switch(
        value: notificationsEnabled ?? false,
        onChanged: (value) async {
          setState(() {
            notificationsEnabled = value;
          });
          await updateProfile(notificationsEnabled: value);
        },
        activeColor: const Color.fromARGB(255, 22, 135, 188),
      ),
    );
  }

  Widget buildLogoutTile() {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text(
        'Sign Out',
        style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.w500),
      ),
      onTap: handleLogout,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  void handleLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _performLogout();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
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
          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}