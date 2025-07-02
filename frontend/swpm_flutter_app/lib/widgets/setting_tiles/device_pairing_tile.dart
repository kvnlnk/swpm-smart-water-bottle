import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:swpm_flutter_app/models/device.dart';
import 'package:swpm_flutter_app/screens/scan_screen.dart';
import 'package:swpm_flutter_app/services/bluetooth/ble_service.dart';
import 'package:swpm_flutter_app/services/bluetooth/bluetooth_device_extension.dart';
import 'package:swpm_flutter_app/store/bluetooth_device_data.dart';
import 'package:swpm_flutter_app/store/user_data.dart';

class DevicePairingTile extends StatelessWidget {
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

  const DevicePairingTile({
    super.key,
    required this.buildSection,
    required this.buildListTile,
    required this.buildReadOnlyTile,
    required this.buildTiledContainer,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothDeviceDataNotifier>(
      builder: (context, bluetoothStore, child) {
        return buildSection(
          title: 'Device Pairing',
          children: [
            buildReadOnlyTile("Connected Devices",
                '${bluetoothStore.connectedCount.toString()} Connected'),
            ..._buildDevicesTiles(bluetoothStore.devices),
            _buildBluetoothScanningTile(context, "Add New Device", "Scan")
          ],
        );
      },
    );
  }

  List<Widget> _buildDevicesTiles(List<Device> devices) {
    return devices
        .where((device) => device.isConnected)
        .map((device) => _buildDeviceTile(device))
        .toList();
  }

  Widget _buildDeviceTile(Device device) {
    return Builder(
      builder: (context) => Container(
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
                  _showDisconnectDialog(context, device);
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
      ),
    );
  }

  Widget _buildBluetoothScanningTile(
      BuildContext context, String title, String displayValue) {
    return buildListTile(
      title: title,
      trailing: buildTiledContainer(
        displayValue: displayValue,
        onTap: () => _showBluetoothScanDialog(context),
        background: const Color.fromARGB(33, 22, 135, 188),
      ),
    );
  }

  void _showBluetoothScanDialog(BuildContext context) {
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

  void _showDisconnectDialog(BuildContext context, Device device) {
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
                _performDisconnect(dialogContext, device.bluetoothDevice!);
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

  Future<void> _performDisconnect(
      BuildContext context, BluetoothDevice device) async {
    final bleService = Provider.of<BleService>(context, listen: false);
    try {
      await device.disconnectAndUpdateStream();

      bleService.removeConnectedDevice(device);
      bleService.removeSavedDeviceData(device);
    } catch (_) {}
  }
}
