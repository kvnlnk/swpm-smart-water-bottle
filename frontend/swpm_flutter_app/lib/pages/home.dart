import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:swpm_flutter_app/store/user_data.dart';
import 'package:swpm_flutter_app/store/water_data.dart';
import 'package:swpm_flutter_app/services/water_service.dart';
import '../components/water_bottle/water_bottle.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  final WaterService waterService = WaterService();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWaterData();
  }

  Future<void> _loadWaterData() async {
    setState(() => isLoading = true);

    final summary = await waterService.fetchDailySummary();

    if (summary != null) {
      final store = Provider.of<WaterDataNotifier>(context, listen: false);
      store.updateFromMap({
        'consumed': summary.totalAmountMl / 1000.0,
        'goal': summary.goalAmountMl / 1000.0,
        'percentageAchieved': summary.percentageAchieved,
        'drinkCount': summary.drinkCount,
        'isGoalReached': summary.isGoalReached,
      });
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataNotifier>(context);
    final waterData = Provider.of<WaterDataNotifier>(context);

    final username = userData.username ?? '–';
    final dailyGoal = userData.dailyGoal ?? 2.5;
    final consumed = waterData.consumed;
    final percentage = waterData.percentageAchieved;
    final drinks = waterData.drinkCount;
    final reached = waterData.isGoalReached;

    final waterLevel = dailyGoal > 0 ? (consumed / dailyGoal).clamp(0.0, 1.0) : 0.0;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${consumed.toStringAsFixed(2)}L",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: reached ? Colors.green : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "of your ${dailyGoal.toStringAsFixed(2)}L daily goal",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text("Drinks: $drinks | Achieved: $percentage%"),
          Text("Goal reached: ${reached ? "Yes" : "No"}"),
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
              style: const TextStyle(fontSize: 14),
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
