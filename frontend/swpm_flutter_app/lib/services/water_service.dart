import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WaterService {
  final String _baseUrl = dotenv.env['API_BASE_URL']!;
  final _client = Supabase.instance.client;

  Future<WaterSummary?> fetchDailySummary() async {
    final jwt = _client.auth.currentSession?.accessToken;
    if (jwt == null) return null;

    final url = Uri.parse('$_baseUrl/api/water/daily-summary');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return WaterSummary.fromJson(jsonData);
      }
    } catch (_) {}

    return WaterSummary(
      date: DateTime.now(),
      totalAmountMl: 1200,
      goalAmountMl: 2500,
      percentageAchieved: 48,
      drinkCount: 5,
      isGoalReached: false,
    );
  }

  Future<List<DrinkingEntry>> fetchDrinkingHistory() async {
    final jwt = _client.auth.currentSession?.accessToken;
    if (jwt == null) return [];

    final url = Uri.parse('$_baseUrl/api/water/drinking-history');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final entries = jsonData['drinkingEntries'] as List;
        return entries.map((e) => DrinkingEntry.fromJson(e)).toList();
      }
    } catch (_) {}

    return [];
  }

  Future<void> addDrink(int amountMl, String timestamp) async {
    final jwt = _client.auth.currentSession?.accessToken;
    if (jwt == null) return;

    final url = Uri.parse('$_baseUrl/api/water/log-drinking');

    try {
      await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'amountMl': amountMl, 'timestamp': timestamp}),
      );
    } catch (_) {}
  }
}

class WaterSummary {
  final DateTime date;
  final int totalAmountMl;
  final int goalAmountMl;
  final int percentageAchieved;
  final int drinkCount;
  final bool isGoalReached;

  WaterSummary({
    required this.date,
    required this.totalAmountMl,
    required this.goalAmountMl,
    required this.percentageAchieved,
    required this.drinkCount,
    required this.isGoalReached,
  });

  factory WaterSummary.fromJson(Map<String, dynamic> json) {
    return WaterSummary(
      date: DateTime.parse(json['date']),
      totalAmountMl: json['totalAmountMl'],
      goalAmountMl: json['goalAmountMl'],
      percentageAchieved: json['percentageAchieved'],
      drinkCount: json['drinkCount'],
      isGoalReached: json['isGoalReached'],
    );
  }
}

class DrinkingEntry {
  final String id;
  final int amountMl;
  final DateTime createdAt;

  DrinkingEntry({
    required this.id,
    required this.amountMl,
    required this.createdAt,
  });

  factory DrinkingEntry.fromJson(Map<String, dynamic> json) {
    return DrinkingEntry(
      id: json['id'],
      amountMl: json['amountMl'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
