import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);
  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  double waterTarget = 2.5;
  double weight = 85.0;
  double height = 185.0;
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey[50],
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            buildSection(
              title: 'Daily Goal',
              children: [buildWaterTargetTile()],
            ),
            SizedBox(height: 20),
            buildSection(
              title: 'Notifications',
              children: [buildNotificationToggle()],
            ),
            SizedBox(height: 20),
            buildSection(
              title: 'Profile',
              children: [
                buildReadOnlyTile("Username", "ABC"),
                buildProfileTile("Weight", weight, 0.0, 125.0, "kg", weight),
                buildProfileTile("Height", height, 0.0, 200.0, "cm", height),
              ],
            ),
            SizedBox(height: 20),
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
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(29, 0, 0, 0),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
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

  Widget buildProfileTile(
    String title,
    double currentValue,
    double min,
    double max,
    String unit,
    double value,
  ) {
    return ListTile(
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: GestureDetector(
        onTap: () => showTargetDialog(title, currentValue, min, max, unit),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color.fromARGB(33, 22, 135, 188),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${value.toStringAsFixed(2)} $unit",
            style: TextStyle(
              color: const Color.fromARGB(255, 22, 135, 188),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget buildWaterTargetTile() {
    return ListTile(
      title: Text('Water Amount', style: TextStyle(fontSize: 16)),
      trailing: GestureDetector(
        onTap: () =>
            showTargetDialog("Set Daily Goal", waterTarget, 0.0, 4.0, "Liter"),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color.fromARGB(28, 22, 135, 188),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${waterTarget.toStringAsFixed(1)}L',
            style: TextStyle(
              color: const Color.fromARGB(255, 22, 135, 188),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  void showTargetDialog(
    String title,
    double currentValue,
    double min,
    double max,
    String unit,
  ) {
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
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 22, 135, 188),
                    ),
                  ),
                  SizedBox(height: 20),
                  Slider(
                    value: tempValue,
                    min: min,
                    max: max,
                    divisions: 40,
                    onChanged: (value) {
                      setDialogState(() {
                        tempValue = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (title == 'Height') {
                    height = tempValue;
                  } else if (title == 'Weight') {
                    weight = tempValue;
                  } else if (title.contains('Daily Goal')) {
                    waterTarget = tempValue;
                  }
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget buildNotificationToggle() {
    return ListTile(
      title: Text('Notifications', style: TextStyle(fontSize: 16)),
      trailing: Switch(
        value: notificationsEnabled,
        onChanged: (value) {
          setState(() {
            notificationsEnabled = value;
          });
        },
        activeColor: const Color.fromARGB(255, 22, 135, 188),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget buildLogoutTile() {
    return ListTile(
      leading: Icon(Icons.logout, color: Colors.red),
      title: Text(
        'Sign Out',
        style: TextStyle(
          fontSize: 16,
          color: Colors.red,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: handleLogout,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  void handleLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Sign Out'),
          content: Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _performLogout();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }

  Widget buildReadOnlyTile(String title, String value) {
    return ListTile(
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color.fromARGB(26, 158, 158, 158),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
