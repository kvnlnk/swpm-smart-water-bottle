import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsService {
  static final String apiBaseUrl = dotenv.env['API_BASE_URL']!;

  static Future<Map<String, dynamic>?> fetchUserData() async {
    try {
      final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
      if (jwt == null) return null;

      final url = Uri.parse("$apiBaseUrl/api/user/information");
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $jwt',
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}

    return null;
  }

  static Future<bool> updateProfile({
    double? weight,
    double? height,
    double? waterTarget,
    bool? notificationsEnabled,
  }) async {
    try {
      final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
      if (jwt == null) return false;

      final url = Uri.parse("$apiBaseUrl/api/user/profile/update");

      final body = {
        if (weight != null) 'WeightKg': weight.round(),
        if (height != null) 'HeightCm': height.round(),
        if (waterTarget != null) 'DailyGoalMl': (waterTarget * 1000).round(),
        if (notificationsEnabled != null) 'NotificationsEnabled': notificationsEnabled,
      };

      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (_) {}

    return false;
  }
}
