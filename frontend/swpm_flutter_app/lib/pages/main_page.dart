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
  final GlobalKey<HomeState> homeKey = GlobalKey<HomeState>();
  final GlobalKey<StatisticsState> statisticsKey = GlobalKey<StatisticsState>();
  final GlobalKey<SettingsState> settingsKey = GlobalKey<SettingsState>();

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoConnect();
    });
  }

  void _refreshCurrentPage() {
    switch (currentPage) {
      case 0:
        homeKey.currentState?.refresh();
        break;
      case 1:
        statisticsKey.currentState?.refresh();
        break;
      case 2:
        settingsKey.currentState?.refresh();
        break;
    }
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
              content: Text("Successfully connected to your device!"),
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
        Home(key: homeKey),
        Statistics(key: statisticsKey),
        Settings(key: settingsKey),
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

  void _onPageTap(int value) {
    _pageController.animateToPage(
      value,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int value) {
    setState(() {
      currentPage = value;
    });

    // Manual refresh when changing pages
    _refreshCurrentPage();
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
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentPage,
        onTap: _onPageTap,
        type: BottomNavigationBarType.fixed,
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
