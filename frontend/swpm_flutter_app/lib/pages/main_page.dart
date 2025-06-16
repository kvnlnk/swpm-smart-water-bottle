import 'package:flutter/material.dart';
import 'package:swpm_flutter_app/pages/home.dart';
import 'package:swpm_flutter_app/pages/statistics.dart';
import 'package:swpm_flutter_app/pages/settings.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
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