import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:swpm_flutter_app/store/bluetooth_device_data.dart';
import 'package:swpm_flutter_app/widgets/utils.dart';

class BleService {
  final BluetoothDeviceDataNotifier _store;

  BleService(this._store);

  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String characteristicUuid =
      "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  // Subscribe to ESP32 notifications
  static Future<Stream<Map<String, dynamic>>?> subscribeToWaterSensorData(
      BluetoothDevice device) async {
    try {
      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      // Find the water sensor service
      BluetoothService? waterService;
      for (BluetoothService service in services) {
        if (service.uuid.str.toLowerCase() == serviceUuid.toLowerCase()) {
          waterService = service;
          break;
        }
      }

      if (waterService == null) {
        return null;
      }

      // Find the characteristic
      BluetoothCharacteristic? dataCharacteristic;
      for (BluetoothCharacteristic characteristic
          in waterService.characteristics) {
        if (characteristic.uuid.str.toLowerCase() ==
            characteristicUuid.toLowerCase()) {
          dataCharacteristic = characteristic;
          break;
        }
      }

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

  // Unsubscribe from notifications
  static Future<void> unsubscribeFromWaterSensorData(
      BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();

    for (BluetoothService service in services) {
      if (service.uuid.str.toLowerCase() == serviceUuid.toLowerCase()) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid.str.toLowerCase() ==
              characteristicUuid.toLowerCase()) {
            await characteristic.setNotifyValue(false);
            break;
          }
        }
        break;
      }
    }
  }

  // Connection monitoring
  void _startMonitoringDevice(BluetoothDevice bluetoothDevice) {
    String deviceId = bluetoothDevice.remoteId.str;

    _store.connectionSubscriptions[deviceId]?.cancel();

    _store.connectionSubscriptions[deviceId] =
        bluetoothDevice.connectionState.listen(
      (BluetoothConnectionState state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleAutomaticDisconnect(bluetoothDevice);
        }
      },
      onError: (error) {
        _handleAutomaticDisconnect(bluetoothDevice);
      },
    );
  }

  void _handleAutomaticDisconnect(BluetoothDevice bluetoothDevice) {
    String deviceId = bluetoothDevice.remoteId.str;

    final index = _store.devices
        .indexWhere((d) => d.bluetoothDevice?.remoteId.str == deviceId);

    if (index != -1) {
      // Cancel data subscription on automatic disconnect
      _cancelDataSubscription(deviceId);

      _store.devices[index] = _store.devices[index].copyWith(
        isConnected: false,
        bluetoothDevice: null,
        dataStream: null,
        lastData: null,
      );

      _store.connectionSubscriptions[deviceId]?.cancel();
      _store.connectionSubscriptions.remove(deviceId);
    }
  }

  void _cancelAllConnectionSubscriptions() {
    for (var subscription in _store.connectionSubscriptions.values) {
      subscription.cancel();
    }
    _store.connectionSubscriptions.clear();
  }

  void _cancelAllDataSubscriptions() {
    for (var subscription in _store.dataSubscriptions.values) {
      subscription.cancel();
    }
    _store.dataSubscriptions.clear();
  }

  void _cancelDataSubscription(String deviceId) {
    _store.dataSubscriptions[deviceId]?.cancel();
    _store.dataSubscriptions.remove(deviceId);
  }

  Future<void> _subscribeToDeviceData(BluetoothDevice bluetoothDevice) async {
    String deviceId = bluetoothDevice.remoteId.str;

    Stream<Map<String, dynamic>>? dataStream =
        await BleService.subscribeToWaterSensorData(bluetoothDevice);

    if (dataStream != null) {
      // Cancel any existing subscription
      _cancelDataSubscription(deviceId);

      // Start new subscription
      _store.dataSubscriptions[deviceId] = dataStream.listen(
        (data) => _handleReceivedData(bluetoothDevice, data),
      );

      // Update device with data stream
      final index = _store.devices
          .indexWhere((d) => d.bluetoothDevice?.remoteId.str == deviceId);

      if (index != -1) {
        _store.devices[index] =
            _store.devices[index].copyWith(dataStream: dataStream);
      }
    }
  }

  // NEW: Handle received data from ESP32
  void _handleReceivedData(BluetoothDevice device, Map<String, dynamic> data) {
    _store.updateDeviceData(device, data);

    // Extract water data
    if (data.containsKey('amountMl') && data.containsKey('timestamp')) {
      double amountMl = (data['amountMl'] as num).toDouble();
      String timestamp = data['timestamp'] as String;

      _onWaterDataReceived(device, amountMl, timestamp);
    }
  }

  // NEW: Water data received callback - customize this!
  void _onWaterDataReceived(
      BluetoothDevice device, double amountMl, String timestamp) {
    print(amountMl);
  }

  // Device management
  void addConnectedDevice(BluetoothDevice bluetoothDevice) async {
    _store.addOrUpdateDevice(bluetoothDevice);

    _startMonitoringDevice(bluetoothDevice);
    // Automatically subscribe to data after connection
    await _subscribeToDeviceData(bluetoothDevice);
  }

  void removeConnectedDevice(BluetoothDevice bluetoothDevice) async {
    String deviceId = bluetoothDevice.remoteId.str;

    // Unsubscribe from data before disconnecting
    await unsubscribeFromWaterSensorData(bluetoothDevice);
    _cancelDataSubscription(deviceId);

    _store.disconnectDevice(bluetoothDevice);

    _store.connectionSubscriptions[deviceId]?.cancel();
    _store.connectionSubscriptions.remove(deviceId);
  }

  void removeDeviceCompletely(BluetoothDevice bluetoothDevice) {
    String deviceId = bluetoothDevice.remoteId.str;

    _store.devices
        .removeWhere((d) => d.bluetoothDevice?.remoteId.str == deviceId);

    _store.connectionSubscriptions[deviceId]?.cancel();
    _store.connectionSubscriptions.remove(deviceId);
  }

  // Sync with Flutter Blue Plus
  void syncWithFlutterBluePlus() {
    List<BluetoothDevice> actualConnectedDevices =
        FlutterBluePlus.connectedDevices;

    // Check store devices if they are still connected
    for (var storeDevice in List.from(_store.devices)) {
      if (storeDevice.isConnected && storeDevice.bluetoothDevice != null) {
        bool isActuallyConnected = actualConnectedDevices.any((actualDevice) =>
            actualDevice.remoteId.str ==
            storeDevice.bluetoothDevice!.remoteId.str);

        if (!isActuallyConnected) {
          // Store-Methode verwenden statt direkter Manipulation
          _store.disconnectDevice(storeDevice.bluetoothDevice!);

          String deviceId = storeDevice.bluetoothDevice!.remoteId.str;
          _store.connectionSubscriptions[deviceId]?.cancel();
          _store.connectionSubscriptions.remove(deviceId);
        }
      }
    }

    // Check actually connected devices
    for (var actualDevice in actualConnectedDevices) {
      bool isInStore = _store.devices.any((storeDevice) =>
          storeDevice.bluetoothDevice?.remoteId.str ==
              actualDevice.remoteId.str &&
          storeDevice.isConnected);

      if (!isInStore) {
        // Store-Methode verwenden statt direkter Manipulation
        _store.addOrUpdateDevice(actualDevice);
        _startMonitoringDevice(actualDevice);
      }
    }
  }

  bool isStoreSyncedWithFlutterBluePlus() {
    List<BluetoothDevice> actualConnectedDevices =
        FlutterBluePlus.connectedDevices;

    if (actualConnectedDevices.length != _store.connectedCount) {
      return false;
    }

    for (var actualDevice in actualConnectedDevices) {
      bool isInStore = _store.devices.any((storeDevice) =>
          storeDevice.bluetoothDevice?.remoteId.str ==
              actualDevice.remoteId.str &&
          storeDevice.isConnected);

      if (!isInStore) {
        return false;
      }
    }

    return true;
  }

  void stopMonitoringAllDevices() {
    _cancelAllConnectionSubscriptions();
  }
}

final Map<DeviceIdentifier, StreamControllerReemit<bool>> _cglobal = {};
final Map<DeviceIdentifier, StreamControllerReemit<bool>> _dglobal = {};

/// connect & disconnect + update stream
extension Extra on BluetoothDevice {
  // convenience
  StreamControllerReemit<bool> get _cstream {
    _cglobal[remoteId] ??= StreamControllerReemit(initialValue: false);
    return _cglobal[remoteId]!;
  }

  // convenience
  StreamControllerReemit<bool> get _dstream {
    _dglobal[remoteId] ??= StreamControllerReemit(initialValue: false);
    return _dglobal[remoteId]!;
  }

  // get stream
  Stream<bool> get isConnecting {
    return _cstream.stream;
  }

  // get stream
  Stream<bool> get isDisconnecting {
    return _dstream.stream;
  }

  // connect & update stream
  Future<void> connectAndUpdateStream() async {
    _cstream.add(true);
    try {
      await connect(mtu: 512);
    } finally {
      _cstream.add(false);
    }
  }

  // disconnect & update stream
  Future<void> disconnectAndUpdateStream({bool queue = true}) async {
    _dstream.add(true);
    try {
      await disconnect(queue: queue);
    } finally {
      _dstream.add(false);
    }
  }
}
