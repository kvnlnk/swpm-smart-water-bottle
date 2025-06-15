import 'package:flutter/material.dart';

class UserDataNotifier extends ChangeNotifier {
  String? _username;
  double? _dailyGoal;
  bool? _notificationsEnabled;

  String? get username => _username;
  double? get dailyGoal => _dailyGoal;
  bool? get notificationsEnabled => _notificationsEnabled;

  void updateFromJson(Map<String, dynamic> json) {
    _username = json['username'];
    _dailyGoal = (json['dailyGoalMl'] != null)
        ? json['dailyGoalMl'] / 1000.0
        : null;
    _notificationsEnabled = json['notificationsEnabled'];
    notifyListeners();
  }

  void updateDailyGoal(double value) {
    _dailyGoal = value;
    notifyListeners();
  }

  void updateNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void clear() {
    _username = null;
    _dailyGoal = null;
    _notificationsEnabled = null;
    notifyListeners();
  }
}
