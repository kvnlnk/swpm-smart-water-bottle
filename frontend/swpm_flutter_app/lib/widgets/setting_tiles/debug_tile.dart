import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swpm_flutter_app/models/device.dart';
import 'package:swpm_flutter_app/services/bluetooth/ble_service.dart';
import 'package:swpm_flutter_app/store/bluetooth_device_data.dart';
import 'package:swpm_flutter_app/store/user_data.dart';

class DebugTile extends StatelessWidget {
  final Widget Function({required String title, required List<Widget> children})
      buildSection;
  final Widget Function({required String title, required Widget trailing})
      buildListTile;
  final Widget Function(String title, String? value) buildReadOnlyTile;

  const DebugTile({
    super.key,
    required this.buildSection,
    required this.buildListTile,
    required this.buildReadOnlyTile,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothDeviceDataNotifier>(
      builder: (context, bluetoothStore, child) {
        return buildSection(
          title: 'Debug',
          children: [
            ...bluetoothStore.connectedDevices
                .map((device) => _buildSimpleDataTile(device)),
            if (bluetoothStore.connectedDevices.isEmpty)
              buildReadOnlyTile("Status", "No devices connected"),
            if (bluetoothStore.connectedDevices.isNotEmpty)
              _buildCommandButtons(
                  context, bluetoothStore.connectedDevices.first),
          ],
        );
      },
    );
  }

  Widget _buildSimpleDataTile(Device device) {
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

  Widget _buildCommandButtons(BuildContext context, Device device) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send Commands to ${device.name}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          _buildCommandButton(
            context: context,
            device: device,
            label: 'None',
            command: {'DrinkReminderType': 0},
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          _buildCommandButton(
            context: context,
            device: device,
            label: 'Normal',
            command: {'DrinkReminderType': 1},
            color: const Color.fromARGB(255, 197, 197, 2),
          ),
          const SizedBox(height: 8),
          _buildCommandButton(
            context: context,
            device: device,
            label: 'Important',
            command: {'DrinkReminderType': 2},
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildCommandButton({
    required BuildContext context,
    required Device device,
    required String label,
    required Map<String, dynamic> command,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _sendCommand(context, device, command),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _sendCommand(
      BuildContext context, Device device, Map<String, dynamic> data) async {
    final bleService = Provider.of<BleService>(context, listen: false);
    if (device.bluetoothDevice != null) {
      try {
        await bleService.writeDataToDevice(device.bluetoothDevice!, data);
      } catch (_) {}
    }
  }
}
