import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';

class Device {
  final String name;
  final IconData icon;
  final bool isConnected;
  final BluetoothDevice? bluetoothDevice;

  Device({
    required this.name,
    required this.icon,
    required this.isConnected,
    this.bluetoothDevice,
  });
}

class BluetoothDeviceDataNotifier extends ChangeNotifier {
  List<Device> _devices = [
    Device(
        name: "Smart Water Bottle", icon: Icons.sports_bar, isConnected: true),
    Device(
        name: "Digital Scale", icon: Icons.monitor_weight, isConnected: true),
  ];

  bool _isScanning = false;
  List<BluetoothDevice> _availableDevices = [];
  String? _scanError;

  List<Device> get devices => List.unmodifiable(_devices);
  int get connectedCount => _devices.where((d) => d.isConnected).length;
  bool get isScanning => _isScanning;
  List<BluetoothDevice> get availableDevices =>
      List.unmodifiable(_availableDevices);
  String? get scanError => _scanError;

  Future<void> scanForDevices() async {
    _isScanning = true;
    _availableDevices.clear();
    _scanError = null;
    notifyListeners();

    try {
      List<BluetoothDevice> foundDevices = await BleService.scanForDevices();
      _availableDevices = foundDevices;
    } catch (e) {
      _scanError = e.toString();
      print('Scan error: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> connectToDevice(BluetoothDevice bluetoothDevice) async {
    try {
      await BleService.connectToDevice(bluetoothDevice);

      // Check if device is already in list
      bool deviceExists =
          _devices.any((d) => d.bluetoothDevice?.id == bluetoothDevice.id);

      if (!deviceExists) {
        // Add to connected devices
        Device newDevice = Device(
          name: bluetoothDevice.name.isEmpty
              ? 'Unknown Device'
              : bluetoothDevice.name,
          icon: _getDeviceIcon(bluetoothDevice.name),
          isConnected: true,
          bluetoothDevice: bluetoothDevice,
        );

        _devices.add(newDevice);
        notifyListeners();
      }
    } catch (e) {
      print('Connection error: $e');
      rethrow;
    }
  }

  Future<void> disconnectDevice(String deviceName) async {
    final device = _devices.firstWhere((d) => d.name == deviceName);
    if (device.bluetoothDevice != null) {
      try {
        await BleService.disconnectDevice(device.bluetoothDevice!);
        updateDeviceConnection(deviceName, false);
      } catch (e) {
        print('Disconnect error: $e');
        rethrow;
      }
    }
  }

  IconData _getDeviceIcon(String deviceName) {
    String name = deviceName.toLowerCase();
    if (name.contains('bottle') || name.contains('water')) {
      return Icons.sports_bar;
    } else if (name.contains('scale') || name.contains('weight')) {
      return Icons.monitor_weight;
    } else if (name.contains('watch') || name.contains('fitness')) {
      return Icons.watch;
    } else {
      return Icons.bluetooth;
    }
  }

  void updateDeviceConnection(String deviceName, bool isConnected) {
    final index = _devices.indexWhere((d) => d.name == deviceName);
    if (index != -1) {
      _devices[index] = Device(
        name: _devices[index].name,
        icon: _devices[index].icon,
        isConnected: isConnected,
        bluetoothDevice: _devices[index].bluetoothDevice,
      );
      notifyListeners();
    }
  }

  void addDevice(Device device) {
    _devices.add(device);
    notifyListeners();
  }

  void removeDevice(String deviceName) {
    _devices.removeWhere((d) => d.name == deviceName);
    notifyListeners();
  }

  void clearScanResults() {
    _availableDevices.clear();
    _scanError = null;
    notifyListeners();
  }
}
