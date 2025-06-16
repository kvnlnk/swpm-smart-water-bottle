import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class WaterService {
  static String? get _baseUrl => dotenv.env['API_BASE_URL'];
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, String> _getHeaders() {
    final token = _supabase.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, double>> getDailySummary() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/water/daily-summary'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'consumed': (data['totalAmountMl'] as num?)!.toDouble() / 1000,
          'goal': (data['goalAmountMl'] as num?)!.toDouble() / 1000,
        };
      } else {
        return {'consumed': 0.0, 'goal': 2.5};
      }
    } catch (e) {
      return {'consumed': 0.0, 'goal': 2.5};
    }
  }
}