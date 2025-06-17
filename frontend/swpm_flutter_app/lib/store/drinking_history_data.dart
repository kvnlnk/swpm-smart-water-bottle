import 'package:flutter/material.dart';
import 'package:swpm_flutter_app/services/water_service.dart';

class DrinkingHistoryDataNotifier extends ChangeNotifier {
  List<DrinkingEntry> _entries = [];

  List<DrinkingEntry> get entries => _entries;

  double get totalLitersToday =>
      _entries.fold(0.0, (sum, e) => sum + e.amountMl) / 1000.0;

  double get averagePerDay => totalLitersToday / 1; // currently 1 day //TODO history

  void setEntries(List<DrinkingEntry> newEntries) {
    _entries = newEntries;
    notifyListeners();
  }

  void clear() {
    _entries = [];
    notifyListeners();
  }
}
