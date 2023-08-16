import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:logger/logger.dart';
import 'package:planet/appmodel.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as stellar_sdk;

Logger logger = Logger();
void loadAssetsForAccount(Account? account) {
  var sdk = account!.testnet
      ? stellar_sdk.StellarSDK.TESTNET
      : stellar_sdk.StellarSDK.PUBLIC;
  sdk.accounts.account(account.address).then((value) {
    var assets = <Asset>[];

    for (var balance in value.balances) {
      switch (balance.assetType) {
        case stellar_sdk.Asset.TYPE_NATIVE:
          assets.insert(
              0,
              Asset(
                  code: 'XLM',
                  issuer: '',
                  amount: Decimal.parse(balance.balance)));
        case stellar_sdk.Asset.TYPE_CREDIT_ALPHANUM12:
        case stellar_sdk.Asset.TYPE_CREDIT_ALPHANUM4:
          assets.add(Asset(
              code: balance.assetCode!,
              issuer: balance.assetIssuer!,
              amount: Decimal.parse(balance.balance),
              testnet: account.testnet));
        default: // liquidity pool shares are ignored for now
      }
    }
    account.assets = assets;
    for (var asset in assets) {
      loadAssetInfo(asset);
    }
    account.assets = assets;
  }).onError<SocketException>((error, stackTrace) {
    print(error);
  }).onError((error, stackTrace) {
    print(error);
  });
}

void loadAssetInfo(Asset asset) {
  if (asset.isNative()) {
    var info = AssetInfo(fullAssetCode: asset.fullAssetCode);
    info.name = "Lumens";
    info.domain = 'stellar.org';
    asset.info = info;
    return;
  }
  var sdk = asset.testnet
      ? stellar_sdk.StellarSDK.TESTNET
      : stellar_sdk.StellarSDK.PUBLIC;
  sdk.accounts.account(asset.issuer).then((account) {
    if (account.homeDomain == null) {
      return;
    }
    stellar_sdk.StellarToml.fromDomain(account.homeDomain!).then((value) {
      if (value.currencies == null) {
        return;
      }
      for (var c in value.currencies!) {
        if (c.code == asset.code && c.issuer == asset.issuer) {
          var info = AssetInfo(
              fullAssetCode: asset.fullAssetCode, testnet: asset.testnet);
          info.domain = account.homeDomain;
          info.name = c.name;
          info.image = c.image;
          asset.info = info;
          return;
        }
      }
    }).onError((error, stackTrace) {
      logger.i('Unable to get asset toml  for ${asset.fullAssetCode} : $error');
    });
  }).onError((error, stackTrace) {
    logger.i(
        'Unable to get issuer account info for ${asset.fullAssetCode} : $error');
  });
}
