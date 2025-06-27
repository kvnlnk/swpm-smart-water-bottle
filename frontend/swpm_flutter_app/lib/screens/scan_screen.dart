import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:swpm_flutter_app/services/ble_service.dart';
import 'package:swpm_flutter_app/store/bluetooth_device_data.dart';

import '../utils/snackbar.dart';
import '../widgets/scan_result_tile.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<BluetoothDevice> _systemDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() => _scanResults = results);
      }
    }, onError: (e) {
      Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      if (mounted) {
        setState(() => _isScanning = state);
      }
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future onScanPressed() async {
    try {
      // `withServices` is required on iOS for privacy purposes, ignored on android.
      var withServices = [Guid("180f")]; // Battery Level Service
      _systemDevices = await FlutterBluePlus.systemDevices(withServices);
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("System Devices Error:", e),
          success: false);
    }
    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        webOptionalServices: [
          Guid("180f"), // battery
          Guid("180a"), // device info
          Guid("1800"), // generic access
          Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e"), // Nordic UART
        ],
      );
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e),
          success: false);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Stop Scan Error:", e),
          success: false);
    }
  }

  Future<void> onConnectPressed(BluetoothDevice device) async {
    final bluetoothStore = context.read<BluetoothDeviceDataNotifier>();
    try {
      await device.connectAndUpdateStream();

      BleService(bluetoothStore).addConnectedDevice(device);
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Connect Error:", e),
          success: false);
    }
  }

  Future<void> onDisconnectPressed(BluetoothDevice device) async {
    final bluetoothStore = context.read<BluetoothDeviceDataNotifier>();
    try {
      await device.disconnect();

      BleService(bluetoothStore).removeConnectedDevice(device);

      Snackbar.show(ABC.c,
          "Disconnected from ${device.platformName.isNotEmpty ? device.platformName : device.remoteId.str}",
          success: true);
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Disconnect Error:", e),
          success: false);
    }
  }

  Future onRefresh() {
    final bluetoothStore = context.read<BluetoothDeviceDataNotifier>();
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
    BleService(bluetoothStore).syncWithFlutterBluePlus();
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(Duration(milliseconds: 500));
  }

  Widget buildScanButton() {
    return Row(children: [
      if (FlutterBluePlus.isScanningNow)
        buildSpinner()
      else
        ElevatedButton(
            onPressed: onScanPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text("SCAN"))
    ]);
  }

  Widget buildSpinner() {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CircularProgressIndicator(
          backgroundColor: Colors.black12,
          color: Colors.black26,
        ),
      ),
    );
  }

  List<Widget> _buildSystemDeviceTiles() {
    return _systemDevices
        .map(
          (d) => ListTile(
            title: Text(
                d.platformName.isNotEmpty ? d.platformName : d.remoteId.str),
            subtitle: Text(d.remoteId.str),
            trailing: ElevatedButton(
              onPressed: () => onConnectPressed(d),
              child: Text('Connect'),
            ),
          ),
        )
        .toList();
  }

  Iterable<Widget> _buildScanResultTiles() {
    return _scanResults.map((r) =>
        ScanResultTile(result: r, onTap: () => onConnectPressed(r.device)));
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Find Devices'),
            actions: [buildScanButton(), const SizedBox(width: 15)],
          ),
          body: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              children: <Widget>[
                ..._buildSystemDeviceTiles(),
                ..._buildScanResultTiles(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
