import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:swpm_flutter_app/models/device.dart';

class BluetoothDeviceDataNotifier extends ChangeNotifier {
  List<Device> _devices = [];
  bool _isScanning = false;
  List<BluetoothDevice> _availableDevices = [];
  String? _scanError;
  final Map<String, StreamSubscription> connectionSubscriptions = {};
  final Map<String, StreamSubscription> dataSubscriptions = {};

  List<Device> get devices => _devices;
  List<Device> get connectedDevices =>
      _devices.where((d) => d.isConnected).toList();
  int get connectedCount => _devices.where((d) => d.isConnected).length;
  bool get isScanning => _isScanning;
  List<BluetoothDevice> get availableDevices =>
      List.unmodifiable(_availableDevices);
  String? get scanError => _scanError;
  bool get hasConnectedDevices => connectedCount > 0;

  void setDevices(List<Device> devices) {
    _devices = devices;
    notifyListeners();
  }

  void updateDevice(Device updatedDevice) {
    final index = _devices.indexWhere((d) =>
        d.bluetoothDevice?.remoteId.str ==
        updatedDevice.bluetoothDevice?.remoteId.str);
    if (index != -1) {
      _devices[index] = updatedDevice;
      notifyListeners();
    }
  }

  void addOrUpdateDevice(BluetoothDevice bluetoothDevice) {
    String deviceName = bluetoothDevice.platformName.isNotEmpty
        ? bluetoothDevice.platformName
        : bluetoothDevice.remoteId.str;

    final existingIndex = _devices.indexWhere(
        (d) => d.bluetoothDevice?.remoteId.str == bluetoothDevice.remoteId.str);

    if (existingIndex != -1) {
      _devices[existingIndex] = _devices[existingIndex].copyWith(
        isConnected: true,
        bluetoothDevice: bluetoothDevice,
      );
    } else {
      Device newDevice = Device(
        name: deviceName,
        icon: Icons.water_drop_outlined,
        isConnected: true,
        bluetoothDevice: bluetoothDevice,
      );
      _devices.add(newDevice);
    }

    notifyListeners();
  }

  void updateDeviceData(BluetoothDevice device, Map<String, dynamic> data) {
    String deviceId = device.remoteId.str;
    final index =
        _devices.indexWhere((d) => d.bluetoothDevice?.remoteId.str == deviceId);

    if (index != -1) {
      _devices[index] = _devices[index].copyWith(lastData: data);
      notifyListeners();
    }
  }

  void updateDeviceName(BluetoothDevice device, String? name) {
    String deviceId = device.remoteId.str;
    final index =
        _devices.indexWhere((d) => d.bluetoothDevice?.remoteId.str == deviceId);
    if (index != -1) {
      _devices[index] = _devices[index].copyWith(name: name);
      notifyListeners();
    }
  }

  void addDevice(Device device) {
    _devices.add(device);
    notifyListeners();
  }

  void removeDeviceById(String deviceId) {
    _devices.removeWhere((d) => d.bluetoothDevice?.remoteId.str == deviceId);
    notifyListeners();
  }

  void setScanState(bool scanning, {String? error}) {
    _isScanning = scanning;
    _scanError = error;
    notifyListeners();
  }

  void setAvailableDevices(List<BluetoothDevice> devices) {
    _availableDevices = devices;
    notifyListeners();
  }

  void clearAllDevices() {
    _devices.clear();
    notifyListeners();
  }

  void clearScanResults() {
    _availableDevices.clear();
    _scanError = null;
    notifyListeners();
  }

  void disconnectDevice(BluetoothDevice bluetoothDevice) {
    String deviceId = bluetoothDevice.remoteId.str;
    final index =
        _devices.indexWhere((d) => d.bluetoothDevice?.remoteId.str == deviceId);

    if (index != -1) {
      _devices[index] = _devices[index].copyWith(
        isConnected: false,
        bluetoothDevice: null,
        dataStream: null,
        lastData: null,
      );

      notifyListeners();
    }
  }
}
