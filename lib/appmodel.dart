import 'package:flutter/material.dart';
import 'dart:collection';
import 'package:json_annotation/json_annotation.dart';
import 'package:localstorage/localstorage.dart';

part 'appmodel.g.dart';

@JsonSerializable()
class AppState extends ChangeNotifier {
  AppState();

  final List<String> _accounts = [];
  UnmodifiableListView<String> get accounts => UnmodifiableListView(_accounts);

  @JsonKey(defaultValue: '')
  String currentAccount = '';
  void switchAccount(String account) {
    currentAccount = account;
    notifyListeners();
  }

  @JsonKey(defaultValue: false)
  bool testnet = false;
  void setNetwork(bool testnet) {
    this.testnet = testnet;
    notifyListeners();
  }

  @JsonKey(includeToJson: false, includeFromJson: false)
  int counter = 0;

  void increment() {
    counter += 1;
    notifyListeners();
  }

  factory AppState.fromJson(Map<String, dynamic> json) =>
      _$AppStateFromJson(json);

  Map<String, dynamic> toJson() => _$AppStateToJson(this);
}

/// Uses local storage to persist the application state.
class AppStatePersistency {
  final appStateKey = 'appstate';
  final _storage = LocalStorage('planet.json');
  Future<AppState> load() async {
    await _storage.ready;
    final data = _storage.getItem(appStateKey);
    if (data == null) {
      return AppState();
    }
    return AppState.fromJson(data);
  }

  save(AppState appstate) {
    _storage.setItem(appStateKey, appstate.toJson());
  }
}
