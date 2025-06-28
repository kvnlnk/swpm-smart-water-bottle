import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:swpm_flutter_app/services/bluetooth/bluetooth_device_extension.dart';
import 'package:swpm_flutter_app/services/water_service.dart';
import 'package:swpm_flutter_app/store/bluetooth_device_data.dart';
import 'package:swpm_flutter_app/services/bluetooth/ble_operations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swpm_flutter_app/store/user_data.dart';

/// Main BLE service for device management and data handling
/// Handles device connections, monitoring, and water data processing
class BleService {
  final BluetoothDeviceDataNotifier _store;
  final UserDataNotifier _userStore;
  final WaterService _waterService = WaterService();

  // Timer for periodic fetches
  Timer? _periodicFetchTimer;
  static const Duration _fetchInterval = Duration(minutes: 1);

  BleService(this._store, this._userStore) {
    // Store Listener hinzufügen um auf Connection Changes zu reagieren
    // Store listener to react to connection changes so we can start/stop periodic fetches
    _store.addListener(_onStoreChanged);
    _userStore.addListener(_onNotificationPermissionChanged);
  }

  // Will only be called if store changes
  void _onStoreChanged() {
    if (_store.hasConnectedDevices) {
      _startPeriodicFetch();
    } else {
      _stopPeriodicFetch();
    }
  }

  void _onNotificationPermissionChanged() {
    // Perform one fetch immediately if notifications are enabled to ensure data is up-to-date
    if (_userStore.notificationsEnabled == true ||
        _userStore.notificationsEnabled == false) {
      for (var deviceData in _store.devices) {
        if (deviceData.isConnected && deviceData.bluetoothDevice != null) {
          _performFetch(deviceData.bluetoothDevice!);
        }
      }
    }
  }

  void _startPeriodicFetch() {
    if (_periodicFetchTimer?.isActive == true) {
      return;
    }

    _periodicFetchTimer = Timer.periodic(_fetchInterval, (timer) {
      for (var deviceData in _store.devices) {
        if (deviceData.isConnected && deviceData.bluetoothDevice != null) {
          _performFetch(deviceData.bluetoothDevice!);
        }
      }
    });
  }

  void _stopPeriodicFetch() {
    if (_periodicFetchTimer?.isActive == true) {
      _periodicFetchTimer?.cancel();
      _periodicFetchTimer = null;
    }
  }

  Future<void> _performFetch(BluetoothDevice device) async {
    if (!_store.hasConnectedDevices) {
      return;
    }

    try {
      final result = await _waterService.fetchLastDrinkingTime();
      if (result == null) {
        return;
      }

      BleOperations.writeDataToDevice(device, result);
    } catch (_) {}
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

  // Subscription management
  void _cancelAllConnectionSubscriptions() {
    for (var subscription in _store.connectionSubscriptions.values) {
      subscription.cancel();
    }
    _store.connectionSubscriptions.clear();
  }

  // ignore: unused_element
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
        await BleOperations.subscribeToWaterSensorData(bluetoothDevice);

    if (dataStream != null) {
      // Cancel any existing subscription
      _cancelDataSubscription(deviceId);

      // Start new subscription
      _store.dataSubscriptions[deviceId] = dataStream.listen(
        (data) => _handleReceivedData(bluetoothDevice, data),
      );
    }
  }

  // Data handling
  void _handleReceivedData(BluetoothDevice device, Map<String, dynamic> data) {
    _store.updateDeviceData(device, data);

    // Extract water data
    if (data.containsKey('amountMl') && data.containsKey('timestamp')) {
      double amountMl = (data['amountMl'] as num).toDouble();
      String timestamp = data['timestamp'] as String;

      _onWaterDataReceived(device, amountMl, timestamp);
    }

    if (data.containsKey('syncRequest') && data['syncRequest']) {
      String currentTime = DateTime.now().toUtc().toIso8601String();

      Map<String, dynamic> syncResponse = {
        'syncConfirmed': true,
        'timestamp': currentTime
      };

      BleOperations.writeDataToDevice(device, syncResponse);
    }
  }

  void _onWaterDataReceived(
      BluetoothDevice device, double amountMl, String timestamp) {
    WaterService wataterService = WaterService();
    wataterService.addDrink(amountMl.toInt(), timestamp);
  }

  // Public API methods
  Future<void> writeDataToDevice(
      BluetoothDevice device, Map<String, dynamic> data) async {
    await BleOperations.writeDataToDevice(device, data);
  }

  // Device management
  void addConnectedDevice(BluetoothDevice bluetoothDevice) async {
    saveDeviceForAutoConnect(bluetoothDevice);
    _store.addOrUpdateDevice(bluetoothDevice);

    _startMonitoringDevice(bluetoothDevice);
    // Automatically subscribe to data after connection
    await _subscribeToDeviceData(bluetoothDevice);
  }

  void removeConnectedDevice(BluetoothDevice bluetoothDevice) async {
    String deviceId = bluetoothDevice.remoteId.str;

    // Unsubscribe from data before disconnecting
    await BleOperations.unsubscribeFromWaterSensorData(bluetoothDevice);
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
    _stopPeriodicFetch();
  }

  // Auto-connect functionality
  Future<bool> autoConnectToSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final String? remoteId = prefs.getString('saved_device_id');
    final String? deviceName = prefs.getString('saved_device_name');

    if (remoteId == null) return false;

    var device = BluetoothDevice.fromId(remoteId);
    await device.connectAndUpdateStream();

    _store.addOrUpdateDevice(device);
    _store.updateDeviceName(device, deviceName);
    _startMonitoringDevice(device);
    await _subscribeToDeviceData(device);

    return true;
  }

  Future<void> saveDeviceForAutoConnect(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    // Save device id
    await prefs.setString('saved_device_id', device.remoteId.str);

    // Save device name
    String deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : device.advName.isNotEmpty
            ? device.advName
            : 'Unknown Device';

    await prefs.setString('saved_device_name', deviceName);
  }

  Future<void> removeSavedDeviceData(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedDeviceId = prefs.getString('saved_device_id');

    if (savedDeviceId == device.remoteId.str) {
      await prefs.remove('saved_device_id');
      await prefs.remove('saved_device_name');
    }
  }

  void dispose() {
    _stopPeriodicFetch();
    _store.removeListener(_onStoreChanged);
    _cancelAllConnectionSubscriptions();
    _cancelAllDataSubscriptions();
  }
}
