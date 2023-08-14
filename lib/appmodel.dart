import 'package:flutter/material.dart';
import 'dart:collection';
import 'package:json_annotation/json_annotation.dart';
import 'package:localstorage/localstorage.dart';
import 'package:decimal/decimal.dart';

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

  void setState(AppState from) {
    _accounts = from._accounts;
    currentAccountAddress = from.currentAccountAddress;
    testnet = from.testnet;
    loaded = true;
  }

  @JsonKey(includeToJson: false, includeFromJson: false)
  //Indicates wheter the state has been loaded from persistent storage
  bool loaded = false;

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
  List<Asset> _assets = [];
  UnmodifiableListView<Asset> get assets => UnmodifiableListView(_assets);

  set assets(List<Asset> newAssets) {
    _assets = newAssets;
    notifyListeners();
  }

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);

  Map<String, dynamic> toJson() => _$AccountToJson(this);
}

class Asset extends ChangeNotifier {
  String code;
  String issuer;
  Decimal amount;
  Asset({required this.code, required this.issuer, required this.amount});
  bool isNative() => code == 'XLM' && issuer == '';
  String get fullAssetCode => '$code:$issuer';
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
