import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/water_bottle/water_bottle.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  double waterLevel = 0.5;
  double dailyGoal = 2.5;
  final supabase = Supabase.instance.client;
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  void _loadUsername() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        username = user.userMetadata?['username'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            "${(waterLevel * dailyGoal).toStringAsFixed(1)}L",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "von ${dailyGoal.toStringAsFixed(1)}L Tagesziel",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
    final waterSlider = Padding(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.opacity),
          SizedBox(width: 10),
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
            Text("Hallo $username!", style: const TextStyle(fontSize: 18)),
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
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Spacer(),
            bottle,
            Spacer(),
            waterSlider,
            waterDisplay,
            Spacer(),
          ],
        ),
      ),
    );
  }
}
