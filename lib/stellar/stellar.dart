import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:logger/logger.dart';
import 'package:planet/appmodel.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as stellar_sdk;

Logger logger = Logger();

stellar_sdk.StellarSDK getSDK(bool testnet) {
  return testnet
      ? stellar_sdk.StellarSDK.TESTNET
      : stellar_sdk.StellarSDK.PUBLIC;
}

void loadAssetsForAccount(Account? account) {
  getSDK(account!.testnet).accounts.account(account.address).then((value) {
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
    logger.i('Unable load assets for ${account.address} : $error');
    //TODO: propagate to the frontend
  }).onError((error, stackTrace) {
    logger.i('Unable load assets for ${account.address} : $error');
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
  getSDK(asset.testnet).accounts.account(asset.issuer).then((account) {
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
          info.description = c.desc;
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

Future<void> send(String destination, Decimal amount, Asset asset, String? memo,
    Account from) async {
  await Future.delayed(const Duration(seconds: 5));
}
