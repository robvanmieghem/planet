import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:planet/appmodel.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as stellar_sdk;

void loadAssetsForAccount(Account? account) {
  var sdk = account!.testnet
      ? stellar_sdk.StellarSDK.TESTNET
      : stellar_sdk.StellarSDK.PUBLIC;
  sdk.accounts.account(account.address).then((value) {
    var assets = <Asset>[];

    for (var balance in value.balances) {
      switch (balance.assetType) {
        case stellar_sdk.Asset.TYPE_NATIVE:
          assets.add(Asset(
              code: 'XLM', issuer: '', amount: Decimal.parse(balance.balance)));
        case stellar_sdk.Asset.TYPE_CREDIT_ALPHANUM12:
        case stellar_sdk.Asset.TYPE_CREDIT_ALPHANUM4:
          assets.add(Asset(
              code: balance.assetCode!,
              issuer: balance.assetIssuer!,
              amount: Decimal.parse(balance.balance)));
        default: // TODO: Handle liquidity pool shares
      }
    }
    account.assets = assets;
  }).onError<SocketException>((error, stackTrace) {
    print(error);
  }).onError((error, stackTrace) {
    print(error);
  });
}
