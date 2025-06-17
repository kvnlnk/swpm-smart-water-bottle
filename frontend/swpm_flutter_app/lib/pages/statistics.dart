import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:swpm_flutter_app/store/drinking_history_data.dart';
import 'package:swpm_flutter_app/services/water_service.dart';

class Statistics extends StatefulWidget {
  const Statistics({Key? key}) : super(key: key);

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  final WaterService waterService = WaterService();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDrinkingData();
  }

  Future<void> _fetchDrinkingData() async {
    setState(() => isLoading = true);
    final entries = await waterService.fetchDrinkingHistory();
    Provider.of<DrinkingHistoryDataNotifier>(context, listen: false).setEntries(entries);
    setState(() => isLoading = false);
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
            const Center(
              child: Text(
                'Statistics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            _buildTopStats(data),
            const SizedBox(height: 20),
            _buildSection(title: "Course of the day", child: _buildBarChart(data)),
            const SizedBox(height: 20),
            _buildSection(title: "Individual entries", child: _buildDetailList(data)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStats(DrinkingHistoryDataNotifier data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTopBox(title: '7 Days', subtitle: 'Streak'), // TODO dynamic
        _buildTopBox(
            title: '${data.averagePerDay.toStringAsFixed(1)}L',
            subtitle: 'Ø per Day'),
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
              style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.bold)),
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

    final List<int> hours = [6, 9, 12, 15, 18, 21, 24];
    final maxAmount = hourlyMl.values.fold<int>(0, (prev, next) => next > prev ? next : prev);

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: hours.map((hour) {
          final amount = hourlyMl.entries
              .where((e) => e.key >= hour - 3 && e.key < hour)
              .fold<int>(0, (sum, e) => sum + e.value);
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
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 111, 140, 255),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text('${hour}h', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailList(DrinkingHistoryDataNotifier data) {
    if (data.entries.isEmpty) {
      return const Text('Keine Einträge für heute.');
    }

    final sortedEntries = [...data.entries] // Kopie erstellen
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // absteigend sortieren

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
