import 'package:flutter/foundation.dart';

class WaterDataNotifier extends ChangeNotifier {
  double _consumed = 0.0;
  double _dailyGoal = 2.5;
  int _percentageAchieved = 0;
  int _drinkCount = 0;
  bool _isGoalReached = false;

  double get consumed => _consumed;
  double get dailyGoal => _dailyGoal;
  int get percentageAchieved => _percentageAchieved;
  int get drinkCount => _drinkCount;
  bool get isGoalReached => _isGoalReached;

  void updateFromMap(Map<String, dynamic> json) {
    _consumed = (json['consumed'] as num?)?.toDouble() ?? 0.0;
    _dailyGoal = (json['goal'] as num?)?.toDouble() ?? 2.5;
    _percentageAchieved = json['percentageAchieved'] ?? 0;
    _drinkCount = json['drinkCount'] ?? 0;
    _isGoalReached = json['isGoalReached'] ?? false;
    notifyListeners();
  }

  void updatePercentage(int newPercentage) {
    _percentageAchieved = newPercentage;
    notifyListeners();
  }

  void clear() {
    _consumed = 0.0;
    _dailyGoal = 2.5;
    _percentageAchieved = 0;
    _drinkCount = 0;
    _isGoalReached = false;
    notifyListeners();
  }
}