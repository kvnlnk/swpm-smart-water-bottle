import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:swpm_flutter_app/models/device.dart';
import 'package:swpm_flutter_app/screens/scan_screen.dart';
import 'package:swpm_flutter_app/services/bluetooth/ble_service.dart';
import 'package:swpm_flutter_app/services/bluetooth/bluetooth_device_extension.dart';
import 'package:swpm_flutter_app/store/user_data.dart';
import 'package:swpm_flutter_app/store/bluetooth_device_data.dart';
import 'package:swpm_flutter_app/services/settings_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swpm_flutter_app/utils/snackbar.dart';

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
            buildSection(
                title: 'Daily Goal', children: [buildWaterTargetTile()]),
            const SizedBox(height: 20),
            buildSection(
                title: 'Notifications', children: [buildNotificationToggle()]),
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
            Consumer<BluetoothDeviceDataNotifier>(
              builder: (context, bluetoothStore, child) {
                return buildSection(
                  title: 'Device Pairing',
                  children: [
                    buildReadOnlyTile("Connected Devices",
                        '${bluetoothStore.connectedCount.toString()} Connected'),
                    ...buildDevicesTiles(bluetoothStore.devices),
                    buildBluetoothScanningTile("Add New Device", "Scan")
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Consumer<BluetoothDeviceDataNotifier>(
              builder: (context, bluetoothStore, child) {
                return buildSection(
                  title: 'Debug',
                  children: [
                    ...bluetoothStore.connectedDevices
                        .map((device) => buildSimpleDataTile(device)),
                    if (bluetoothStore.connectedDevices.isEmpty)
                      buildReadOnlyTile("Status", "No devices connected"),

                    // Einfacher Button
                    if (bluetoothStore.connectedDevices.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _sendCommand(
                                    bluetoothStore.connectedDevices.first, {
                                  'DrinkReminderType': 0,
                                }),
                                child: const Text('None'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _sendCommand(
                                    bluetoothStore.connectedDevices.first, {
                                  'DrinkReminderType': 1,
                                }),
                                child: const Text('Nomal'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _sendCommand(
                                    bluetoothStore.connectedDevices.first, {
                                  'DrinkReminderType': 2,
                                }),
                                child: const Text('Important'),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
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

  Widget buildSimpleDataTile(Device device) {
    String displayValue = "No data";

    if (device.lastData != null && device.lastData!.containsKey('amountMl')) {
      displayValue = "${device.lastData!['amountMl']} ml";
    } else if (device.lastData != null) {
      displayValue = "Waiting...";
    }

    return buildListTile(
      title: device.name,
      trailing: Text(displayValue),
    );
  }

  Widget buildProfileTile(
      String title, double? currentValue, double min, double max, String unit) {
    return buildListTile(
      title: title,
      trailing: currentValue != null
          ? buildTiledContainer(
              displayValue: "${currentValue.toStringAsFixed(2)} $unit",
              onTap: () =>
                  showTargetDialog(title, currentValue, min, max, unit),
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
              onTap: () => showTargetDialog(
                  "Set Daily Goal", waterTarget!, 0.0, 4.0, "Liter"),
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

  Widget buildNotificationToggle() {
    return buildListTile(
      title: "Notifications",
      trailing: Switch(
        value: notificationsEnabled ?? false,
        onChanged: (value) async {
          setState(() {
            notificationsEnabled = value;
          });
          await _updateProfile(notificationsEnabled: value);
        },
        activeColor: const Color.fromARGB(255, 22, 135, 188),
      ),
    );
  }

  void showBluetoothScanDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: SizedBox(
            height: 600,
            width: double.maxFinite,
            child: Column(
              children: [
                Expanded(child: ScanScreen()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildBluetoothScanningTile(String title, String displayValue) {
    return buildListTile(
      title: title,
      trailing: buildTiledContainer(
        displayValue: displayValue,
        onTap: () => showBluetoothScanDialog(),
      ),
    );
  }

  List<Widget> buildDevicesTiles(List<Device> devices) {
    return devices
        .where((device) => device.isConnected)
        .map((device) => buildDeviceTile(device))
        .toList();
  }

  Widget buildDeviceTile(Device device) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color.fromARGB(33, 22, 135, 188),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              device.icon,
              color: const Color.fromARGB(255, 22, 135, 188),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Connected',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                showDisconnectDialog(device);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showDisconnectDialog(Device device) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Disconnect Device'),
          content:
              Text('Are you sure you want to disconnect "${device.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _performDisconnect(device.bluetoothDevice!);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Disconnect',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildLogoutTile() {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text(
        'Sign Out',
        style: TextStyle(
            fontSize: 16, color: Colors.red, fontWeight: FontWeight.w500),
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
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _performLogout();
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
          style:
              TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _sendCommand(Device device, Map<String, dynamic> data) async {
    final bluetoothStore = context.read<BluetoothDeviceDataNotifier>();
    final userStore = context.read<UserDataNotifier>();
    if (device.bluetoothDevice != null) {
      await BleService(bluetoothStore, userStore)
          .writeDataToDevice(device.bluetoothDevice!, data);
    }
  }

  Future<void> _performDisconnect(BluetoothDevice device) async {
    final bluetoothStore = context.read<BluetoothDeviceDataNotifier>();
    final userStore = context.read<UserDataNotifier>();
    try {
      await device.disconnectAndUpdateStream();

      BleService(bluetoothStore, userStore).removeConnectedDevice(device);
      BleService(bluetoothStore, userStore).removeSavedDeviceData(device);

      Snackbar.show(ABC.c,
          "Disconnected from ${device.platformName.isNotEmpty ? device.platformName : device.remoteId.str}",
          success: true);
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Disconnect Error:", e),
          success: false);
    }
  }
}
