import 'package:flutter/material.dart';

class UserDataNotifier extends ChangeNotifier {
  String? _username;
  double? _dailyGoal;
  bool? _notificationsEnabled;
  double? _weight;
  double? _height;

  String? get username => _username;
  double? get dailyGoal => _dailyGoal;
  bool? get notificationsEnabled => _notificationsEnabled;
  double? get weight => _weight;
  double? get height => _height;

  void updateFromJson(Map<String, dynamic> json) {
    _username = json['username'];
    _dailyGoal = (json['dailyGoalMl'] != null)
        ? json['dailyGoalMl'] / 1000.0
        : null;
    _notificationsEnabled = json['notificationsEnabled'];
    _weight = (json['weightKg'] as num?)?.toDouble();
    _height = (json['heightCm'] as num?)?.toDouble();
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

  void updateWeight(double value) {
    _weight = value;
    notifyListeners();
  }

  void updateHeight(double value) {
    _height = value;
    notifyListeners();
  }

  void clear() {
    _username = null;
    _dailyGoal = null;
    _notificationsEnabled = null;
    _weight = null;
    _height = null;
    notifyListeners();
  }
}