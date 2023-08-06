import 'package:flutter/material.dart';
import 'dart:collection';
import 'package:json_annotation/json_annotation.dart';
import 'package:localstorage/localstorage.dart';

part 'appmodel.g.dart';

@JsonSerializable()
class AppState extends ChangeNotifier {
  AppState();

  @JsonKey(name: "accounts", includeFromJson: true, includeToJson: true)
  // ignore: prefer_final_fields
  List<Account> _accounts = [];
  UnmodifiableListView<Account> get accounts => UnmodifiableListView(_accounts);
  void addAccount(Account value) {
    _accounts.add(value);
    notifyListeners();
  }

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

@JsonSerializable()
class Account extends ChangeNotifier {
  Account();

  String friendlyName = '';

  String address = '';
  String secret = '';
  bool testnet = false;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);

  Map<String, dynamic> toJson() => _$AccountToJson(this);
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
