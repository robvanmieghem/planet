import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:logger/logger.dart';
import 'package:planet/appmodel.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as stellar_sdk;
import 'package:collection/collection.dart';

Logger logger = Logger();

stellar_sdk.StellarSDK getSDK(bool testnet) {
  return testnet
      ? stellar_sdk.StellarSDK.TESTNET
      : stellar_sdk.StellarSDK.PUBLIC;
}

Future<void> loadAssetsForAccount(Account? account) async {
  try {
    var value =
        await getSDK(account!.testnet).accounts.account(account.address);
    account.exists = true;
    for (var balance in value.balances) {
      Asset? asset;
      switch (balance.assetType) {
        case stellar_sdk.Asset.TYPE_NATIVE:
          asset = Asset(
              code: 'XLM',
              issuer: '',
              amount: Decimal.parse(balance.balance) -
                  Decimal.fromInt(value.subentryCount + 2) *
                      Decimal.fromInt(5).shift(-1),
              testnet: account.testnet);

        case stellar_sdk.Asset.TYPE_CREDIT_ALPHANUM12:
        case stellar_sdk.Asset.TYPE_CREDIT_ALPHANUM4:
          asset = Asset(
              code: balance.assetCode!,
              issuer: balance.assetIssuer!,
              amount: Decimal.parse(balance.balance),
              testnet: account.testnet);
        default:
          continue;
      }
      if (balance.sellingLiabilities != null) {
        asset.amount -= Decimal.parse(balance.sellingLiabilities!);
      }
      Asset? existing = account.assets.firstWhereOrNull(
          (element) => element.fullAssetCode == asset!.fullAssetCode);
      if (existing != null) {
        existing.setAmount(asset.amount);
      } else {
        account.addAsset(asset);
        loadAssetInfo(asset);
      }
    }
  } on SocketException catch (error) {
    logger.i('Unable load assets for ${account!.address} : $error');
    //TODO: propagate to the frontend
  } on stellar_sdk.ErrorResponse catch (error) {
    if (error.code == 404) {
      account!.exists = false;
      return;
    }
    logger.i('horizon responded with an error ${account!.address} : $error');
    //TODO: propagate to the frontend
  } catch (error) {
    logger.i(
        'Unable load assets for ${account!.address} (${error.runtimeType}): $error');
    //TODO: propagate to the frontend
  }
}

void loadAssetInfo(Asset asset) async {
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

stellar_sdk.Asset toStellarSDKAsset(Asset asset) {
  return asset.isNative()
      ? stellar_sdk.Asset.NATIVE
      : stellar_sdk.Asset.createNonNativeAsset(asset.code, asset.issuer);
}

Future<void> send(String destination, Decimal amount, Asset asset, String? memo,
    Account from) async {
  var sdk = getSDK(from.testnet);
  stellar_sdk.AccountResponse sender = await sdk.accounts.account(from.address);

  // Build the transaction to send 100 XLM native payment from sender to destination
  stellar_sdk.Transaction transaction = stellar_sdk.TransactionBuilder(sender)
      .addOperation(stellar_sdk.PaymentOperationBuilder(
              destination, toStellarSDKAsset(asset), amount.toString())
          .build())
      .build();

  // Sign the transaction with the sender's key pair.
  var kp = stellar_sdk.KeyPair.fromSecretSeed(from.secret);
  transaction.sign(kp,
      from.testnet ? stellar_sdk.Network.TESTNET : stellar_sdk.Network.PUBLIC);

  // Submit the transaction to the stellar network.
  stellar_sdk.SubmitTransactionResponse response =
      await sdk.submitTransaction(transaction);
  if (!response.success) {
    logger.e('Failed to submit payment: $response extras: ${response.extras}');
    //TODO: propagate error
  }
  loadAssetsForAccount(from);
}

Future<({Decimal receiveAmount, List<stellar_sdk.Asset> path})?>
    findBestStrictSend(
        Asset fromAsset, Decimal sendAmount, Asset toAsset) async {
  var sdk = getSDK(fromAsset.testnet);
  var requestBuilder = sdk.strictSendPaths;
  var response = await requestBuilder
      .sourceAsset(toStellarSDKAsset(fromAsset))
      .sourceAmount(sendAmount.toStringAsFixed(7))
      .destinationAssets([toStellarSDKAsset(toAsset)]).execute();
  if (response.records == null || response.records!.isEmpty) {
    return null;
  }

  var result = (receiveAmount: Decimal.zero, path: <stellar_sdk.Asset>[]);
  for (var record in response.records!) {
    var amount = Decimal.parse(record.destinationAmount);
    if (amount > result.receiveAmount) {
      result = (receiveAmount: amount, path: record.path);
    }
  }
  return result;
}

Future<void> swap(Asset fromAsset, Decimal sendAmount, Asset toAsset,
    Decimal receiveAmount, Decimal allowedSlippage, Account from) async {
  var sdk = getSDK(from.testnet);
  stellar_sdk.AccountResponse sender = await sdk.accounts.account(from.address);

  stellar_sdk.Transaction transaction = stellar_sdk.TransactionBuilder(sender)
      .addOperation(stellar_sdk.PathPaymentStrictSendOperationBuilder(
              toStellarSDKAsset(fromAsset),
              sendAmount.toString(),
              from.address,
              toStellarSDKAsset(toAsset),
              (receiveAmount * (Decimal.one - allowedSlippage)).toString())
          .build())
      .build();

  // Sign the transaction with the sender's key pair.
  var kp = stellar_sdk.KeyPair.fromSecretSeed(from.secret);
  transaction.sign(kp,
      from.testnet ? stellar_sdk.Network.TESTNET : stellar_sdk.Network.PUBLIC);

  // Submit the transaction to the stellar network.
  stellar_sdk.SubmitTransactionResponse response =
      await sdk.submitTransaction(transaction);
  if (!response.success) {
    logger.e('Failed to submit payment: $response extras: ${response.extras}');
    //TODO: propagate error
  }
  loadAssetsForAccount(from);
}
