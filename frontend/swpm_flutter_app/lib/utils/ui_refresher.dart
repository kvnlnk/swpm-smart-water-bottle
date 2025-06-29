import 'package:flutter/material.dart';

class UIRefreshNotifier extends ValueNotifier<int> {
  static UIRefreshNotifier? _instance;
  static UIRefreshNotifier get instance =>
      _instance ??= UIRefreshNotifier._internal();

  UIRefreshNotifier._internal() : super(0);

  void refreshUI() {
    value++;
  }
}
