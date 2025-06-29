import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Device {
  final String name;
  final IconData icon;
  final bool isConnected;
  final BluetoothDevice? bluetoothDevice;
  final Map<String, dynamic>? lastData;

  Device({
    required this.name,
    required this.icon,
    required this.isConnected,
    this.bluetoothDevice,
    this.lastData,
  });

  Device copyWith({
    String? name,
    IconData? icon,
    bool? isConnected,
    BluetoothDevice? bluetoothDevice,
    Stream<Map<String, dynamic>>? dataStream,
    Map<String, dynamic>? lastData,
  }) {
    return Device(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isConnected: isConnected ?? this.isConnected,
      bluetoothDevice: bluetoothDevice ?? this.bluetoothDevice,
      lastData: lastData ?? this.lastData,
    );
  }
}
