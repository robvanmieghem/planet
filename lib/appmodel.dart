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
  String currentAccountAddress = '';
  void setCurrentAccountByCurrentAccountAddress() {
    switchAccount(_accounts.cast<Account?>().firstWhere(
        (element) =>
            element?.address == currentAccountAddress &&
            element?.testnet == testnet,
        orElse: () => null));
  }

  @JsonKey(includeToJson: false, includeFromJson: false)
  Account? currentAccount;
  void switchAccount(Account? account) {
    currentAccount = account;
    currentAccountAddress = account != null ? account.address : '';
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

  void setState(AppState from) {
    _accounts = from._accounts;
    currentAccountAddress = from.currentAccountAddress;
    testnet = from.testnet;
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

  @JsonKey(includeToJson: false, includeFromJson: false)
  List<Asset> assets = [];

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);

  Map<String, dynamic> toJson() => _$AccountToJson(this);
}

class Asset extends ChangeNotifier {
  String code;
  String issuer;
  String amount;
  Asset({required this.code, required this.issuer, required this.amount});
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
