import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Utility class for low-level BLE operations
/// Handles characteristic discovery, reading, writing, and notifications
class BleOperations {
  static final String serviceUuid = dotenv.env['SERVICE_UUID']!;
  static final String characteristicUuid = dotenv.env['CHARACTERISTIC_UUID']!;

  /// Finds the water sensor characteristic for a given device
  static Future<BluetoothCharacteristic?> findWaterSensorCharacteristic(
      BluetoothDevice device) async {
    try {
      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      // Find the water sensor service
      BluetoothService? waterBottleService;
      for (BluetoothService service in services) {
        if (service.uuid.str.toLowerCase() == serviceUuid.toLowerCase()) {
          waterBottleService = service;
          break;
        }
      }

      if (waterBottleService == null) {
        return null;
      }

      // Find the characteristic
      BluetoothCharacteristic? dataCharacteristic;
      for (BluetoothCharacteristic characteristic
          in waterBottleService.characteristics) {
        if (characteristic.uuid.str.toLowerCase() ==
            characteristicUuid.toLowerCase()) {
          dataCharacteristic = characteristic;
          break;
        }
      }

      return dataCharacteristic;
    } catch (e) {
      return null;
    }
  }

  /// Subscribe to ESP32 notifications and return a stream of parsed data
  static Future<Stream<Map<String, dynamic>>?> subscribeToWaterSensorData(
      BluetoothDevice device) async {
    try {
      BluetoothCharacteristic? dataCharacteristic =
          await findWaterSensorCharacteristic(device);

      if (dataCharacteristic == null) {
        return null;
      }

      // Enable notifications
      await dataCharacteristic.setNotifyValue(true);

      // Return stream that parses JSON data
      return dataCharacteristic.lastValueStream.map((data) {
        try {
          String jsonString = utf8.decode(data);
          Map<String, dynamic> jsonData = json.decode(jsonString);
          return jsonData;
        } catch (e) {
          return <String, dynamic>{};
        }
      }).where((data) => data.isNotEmpty);
    } catch (e) {
      return null;
    }
  }

  /// Unsubscribe from notifications
  static Future<void> unsubscribeFromWaterSensorData(
      BluetoothDevice device) async {
    BluetoothCharacteristic? dataCharacteristic =
        await findWaterSensorCharacteristic(device);

    if (dataCharacteristic != null) {
      await dataCharacteristic.setNotifyValue(false);
    }
  }

  /// Write data to the device
  static Future<void> writeDataToDevice(
      BluetoothDevice device, Map<String, dynamic> data) async {
    String jsonData = json.encode(data);
    List<int> bytes = utf8.encode(jsonData);

    BluetoothCharacteristic? dataCharacteristic =
        await findWaterSensorCharacteristic(device);

    if (dataCharacteristic == null) {
      return;
    }

    await dataCharacteristic.write(bytes);
  }
}
