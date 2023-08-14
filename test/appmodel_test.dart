import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:test/test.dart';
import 'package:planet/appmodel.dart';

void main() {
  group('Application State', () {
    test('set network', () {
      final model = AppState();
      var listenerCalled = false;
      model.addListener(() {
        expect(model.testnet, true);
        listenerCalled = true;
      });
      model.setNetwork(true);
      expect(listenerCalled, true);
    });
    test('json deserialization', () {
      var jsonInput = '''
      { 
        "accounts":[{
          "friendlyName":"Account1",
          "address":"GA",
          "secret":"SA",
          "network":"testnet"
        }],
        "testnet":true
      }
      ''';
      var json = jsonDecode(jsonInput);
      var appstate = AppState.fromJson(json);
      expect(appstate.testnet, true);
      expect(appstate.accounts.length, 1);
    });
  });
  group('Asset', () {
    test('fullAssetCode', () {
      final asset = Asset(
          code: 'USDC',
          issuer: 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
          amount: Decimal.one);
      expect(asset.fullAssetCode,
          'USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN');
    });
  });
}
