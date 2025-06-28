import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:swpm_flutter_app/store/drinking_history_data.dart';
import 'package:swpm_flutter_app/services/water_service.dart';

class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  final WaterService waterService = WaterService();
  bool isLoading = true;
  WaterSummary? summary;

  @override
  void initState() {
    super.initState();
    _fetchDrinkingData();
  }

  Future<void> _fetchDrinkingData() async {
    setState(() => isLoading = true);

    final entries = await waterService.fetchDrinkingHistory();
    final summaryData = await waterService.fetchDailySummary();

    Provider.of<DrinkingHistoryDataNotifier>(context, listen: false)
        .setEntries(entries);
    setState(() {
      summary = summaryData;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DrinkingHistoryDataNotifier>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _fetchDrinkingData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 20),
            _buildTopStats(data),
            const SizedBox(height: 20),
            _buildSection(
                title: "Course of the day", child: _buildBarChart(data)),
            const SizedBox(height: 20),
            _buildSection(
                title: "Individual entries", child: _buildDetailList(data)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStats(DrinkingHistoryDataNotifier data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTopBox(
          title: summary?.drinkCount.toString() ?? "-",
          subtitle: summary?.drinkCount == 1
              ? 'drinking session'
              : 'drinking sessions',
        ),
        _buildTopBox(
          title: '${data.averagePerDay.toStringAsFixed(1)}L',
          subtitle: 'consumed',
        ),
      ],
    );
  }

  Widget _buildTopBox({required String title, required String subtitle}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(29, 0, 0, 0),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(29, 0, 0, 0),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBarChart(DrinkingHistoryDataNotifier data) {
    final Map<int, int> hourlyMl = {};

    for (var entry in data.entries) {
      final hour = entry.createdAt.hour;
      hourlyMl[hour] = (hourlyMl[hour] ?? 0) + entry.amountMl;
    }

    final hours = hourlyMl.keys.toList()..sort();
    // Maximum consumption in a single hour + 20% buffer for Y-axis scaling
    final int maxAmount;
    if (hourlyMl.values.isEmpty) {
      maxAmount = 1000; // Default fallback value if no data is available
    } else {
      final maxEntry = hourlyMl.values
          .reduce((a, b) => a > b ? a : b); // Find the highest hourly value
      maxAmount =
          (maxEntry * 1.2).ceil(); // Add 20% padding and round up for UX
    }

    final yAxisSteps = 4;
    final yStepValue = (maxAmount / yAxisSteps).ceil();

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // y-axes
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(yAxisSteps + 1, (i) {
              final label = yStepValue * (yAxisSteps - i);
              return SizedBox(
                height: 200 / (yAxisSteps + 1),
                child: Text('$label ml', style: const TextStyle(fontSize: 10)),
              );
            }),
          ),
          const SizedBox(width: 12),
          // x-axes
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: hours.map((hour) {
                  final amount = hourlyMl[hour]!;
                  final heightFactor = maxAmount > 0 ? amount / maxAmount : 0.0;

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: FractionallySizedBox(
                            heightFactor: heightFactor,
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 111, 140, 255),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('$hour h',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600])),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailList(DrinkingHistoryDataNotifier data) {
    if (data.entries.isEmpty) {
      return const Text('No entries.');
    }

    final sortedEntries = [...data.entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: sortedEntries.map((e) {
        return ListTile(
          leading: const Icon(Icons.local_drink),
          title: Text("${e.amountMl} ml"),
          subtitle: Text(DateFormat.Hm().format(e.createdAt)),
        );
      }).toList(),
    );
  }
}
