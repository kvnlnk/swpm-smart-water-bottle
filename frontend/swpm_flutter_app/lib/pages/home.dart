import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swpm_flutter_app/store/user_data.dart';
import 'package:swpm_flutter_app/controller/water_controller.dart';
import '../components/water_bottle/water_bottle.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  final WaterController waterController = WaterController();
  double waterConsumed = 0.0;
  double waterLevel = 0.5;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWaterData();
  }

  Future<void> _loadWaterData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final summary = await waterController.getDailySummary();
      setState(() {
        waterConsumed = summary['consumed'] ?? 0.0;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataNotifier>(context);
    final username = userData.username ?? '–';
    final dailyGoal = userData.dailyGoal ?? 2.5;

    waterLevel =
    dailyGoal > 0 ? (waterConsumed / dailyGoal).clamp(0.0, 1.0) : 0.0;

    final bottle = Center(
      child: SizedBox(
        width: 200,
        height: 300,
        child: WaterBottle(
          waterColor: Colors.blue,
          bottleColor: Colors.lightBlue,
          capColor: Colors.blueGrey,
          waterLevel: waterLevel,
        ),
      ),
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
            "${waterConsumed.toStringAsFixed(2)}L",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "of your ${dailyGoal.toStringAsFixed(2)}L daily goal",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text("Hello $username!", style: const TextStyle(fontSize: 18)),
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
      body: RefreshIndicator(
        onRefresh: _loadWaterData,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      bottle,
                      const Spacer(),
                      waterDisplay,
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}