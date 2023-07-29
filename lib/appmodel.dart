import 'package:flutter/material.dart';
import 'dart:collection';

class AppState extends ChangeNotifier {
  final List<String> _accounts = [];
  UnmodifiableListView<String> get accounts => UnmodifiableListView(_accounts);

  String currentAccount = '';
  void switchAccount(String account) {
    currentAccount = account;
    notifyListeners();
  }

  bool testnet = false;
  void setNetwork(bool testnet) {
    this.testnet = testnet;
    notifyListeners();
  }

  int counter = 0;

  void increment() {
    counter += 1;
    notifyListeners();
  }
}
