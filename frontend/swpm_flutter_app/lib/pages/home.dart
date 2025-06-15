import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../components/water_bottle/water_bottle.dart';
import 'package:provider/provider.dart';
import 'package:swpm_flutter_app/store/user_data.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  double waterLevel = 0.5;

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataNotifier>(context);
    final username = userData.username;
    final dailyGoal = userData.dailyGoal;

    final plain = WaterBottle(
      waterColor: Colors.blue,
      bottleColor: Colors.lightBlue,
      capColor: Colors.blueGrey,
      waterLevel: waterLevel,
    );

    final bottle = Center(
      child: SizedBox(width: 200, height: 300, child: plain),
    );

    final waterDisplay = Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            dailyGoal != null
                ? "${(waterLevel * dailyGoal).toStringAsFixed(1)}L"
                : "–",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dailyGoal != null
                ? "of your ${dailyGoal.toStringAsFixed(1)}L daily goal"
                : "–",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );

    final waterSlider = Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.opacity),
          const SizedBox(width: 10),
          Expanded(
            child: Slider(
              value: waterLevel,
              max: 1.0,
              min: 0.0,
              onChanged: (value) {
                setState(() {
                  waterLevel = value;
                });
              },
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text("Hello ${username ?? "–"}!",
                style: const TextStyle(fontSize: 18)),
            Text(
              DateFormat('EEEE, dd. MMMM yyyy').format(DateTime.now()),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            bottle,
            const Spacer(),
            waterSlider,
            waterDisplay,
            const Spacer(),
          ],
        ),
      ),
    );
  }
}