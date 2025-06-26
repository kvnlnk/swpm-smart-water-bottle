import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  static Future<List<BluetoothDevice>> scanForDevices(
      {Duration timeout = const Duration(seconds: 15)}) async {
    List<BluetoothDevice> foundDevices = [];

    // Check if bluetooth is supported
    if (await FlutterBluePlus.isSupported == false) {
      throw Exception('Bluetooth not supported by this device');
    }

    // Check if bluetooth is on
    if (await FlutterBluePlus.isSupported == false) {
      throw Exception('Bluetooth is not turned on');
    }

    // Start scanning
    await FlutterBluePlus.startScan(timeout: timeout);

    // Listen to scan results
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!foundDevices.contains(result.device) &&
            result.device.name.isNotEmpty) {
          foundDevices.add(result.device);
        }
      }
    });

    // Wait for scan to complete
    await FlutterBluePlus.isScanning.where((val) => val == false).first;

    return foundDevices;
  }

  static Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
    } catch (e) {
      throw Exception('Failed to connect to device: $e');
    }
  }

  static Future<void> disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } catch (e) {
      throw Exception('Failed to disconnect device: $e');
    }
  }
}
