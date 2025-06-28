import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swpm_flutter_app/pages/home.dart';
import 'package:swpm_flutter_app/pages/statistics.dart';
import 'package:swpm_flutter_app/pages/settings.dart';
import 'package:swpm_flutter_app/services/bluetooth/ble_service.dart';
import 'package:swpm_flutter_app/store/bluetooth_device_data.dart';
import 'package:swpm_flutter_app/store/user_data.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoConnect();
    });
  }

  Future<void> _autoConnect() async {
    final bluetoothStore = context.read<BluetoothDeviceDataNotifier>();
    final userStore = context.read<UserDataNotifier>();

    await Future.delayed(Duration(milliseconds: 500));

    final bleService = BleService(bluetoothStore, userStore);

    // Auto reconnect if no other devices are connected
    if (bluetoothStore.connectedCount == 0) {
      final success = await bleService.autoConnectToSavedDevice();

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Connected to your device!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  int currentPage = 0;

  List<Widget> get pages => [
        const Home(),
        const Statistics(),
        const Settings(),
      ];

  String get appBarTitle {
    switch (currentPage) {
      case 0:
        return "Smart Water Bottle";
      case 1:
        return "Statistics";
      case 2:
        return "Settings";
      default:
        return "Smart Water Bottle";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: IndexedStack(index: currentPage, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentPage,
        onTap: (value) {
          setState(() {
            currentPage = value;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Statistics",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
