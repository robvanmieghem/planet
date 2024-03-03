import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:logger/logger.dart';
import 'package:planet/appmodel.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as stellar_sdk;
import 'package:collection/collection.dart';

Logger logger = Logger();
const int maxBaseFee = 1000000; // 0.1 XLM
//TODO: although Stellar will not take the maximum fee,
//getting this from feestats would be better

class StellarException implements Exception {
  String error;
  StellarException({required this.error});
  StellarException.timeout() : error = "Timeout";

  factory StellarException.fromSubmitTransactionResponse(
      stellar_sdk.SubmitTransactionResponse response) {
    if (response.extras?.resultCodes?.transactionResultCode != null) {
      switch (response.extras?.resultCodes?.transactionResultCode) {
        case "tx_insufficient_fee":
          return StellarException(error: "Insufficient fee");
        default:
          return StellarException(error: "Unexpected error");
      }
    }
    return StellarException(error: "Unexpected error");
  }

  @override
  String toString() => error;
}

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
    List<Asset> unseenAccountAssets = account.assets.toList();
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
      unseenAccountAssets.removeWhere(
          (element) => element.fullAssetCode == asset!.fullAssetCode);
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
      for (var assetNoLongerTrusted in unseenAccountAssets) {
        account.removeAsset(assetNoLongerTrusted);
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

Future<void> removeTrustline(Asset asset, Account from) async {
  var sdk = getSDK(from.testnet);
  stellar_sdk.AccountResponse sender = await sdk.accounts.account(from.address);

  var tb = stellar_sdk.TransactionBuilder(sender);
  tb.addOperation(
      stellar_sdk.ChangeTrustOperation(toStellarSDKAsset(asset), "0"));
  tb.setMaxOperationFee(maxBaseFee);

  var transaction = tb.build();
  // Sign the transaction with the sender's key pair.
  var kp = stellar_sdk.KeyPair.fromSecretSeed(from.secret);
  transaction.sign(kp,
      from.testnet ? stellar_sdk.Network.TESTNET : stellar_sdk.Network.PUBLIC);

  await submitTransaction(sdk, transaction);

  loadAssetsForAccount(from);
}

Future<void> addTrustline(String assetCode, String issuer, Account from) async {
  var sdk = getSDK(from.testnet);
  stellar_sdk.AccountResponse sender = await sdk.accounts.account(from.address);

  var tb = stellar_sdk.TransactionBuilder(sender);
  tb.addOperation(stellar_sdk.ChangeTrustOperation(
      stellar_sdk.Asset.createNonNativeAsset(assetCode, issuer),
      (1 << 53).toString()));
  tb.setMaxOperationFee(maxBaseFee);

  var transaction = tb.build();
  // Sign the transaction with the sender's key pair.
  var kp = stellar_sdk.KeyPair.fromSecretSeed(from.secret);
  transaction.sign(kp,
      from.testnet ? stellar_sdk.Network.TESTNET : stellar_sdk.Network.PUBLIC);

  await submitTransaction(sdk, transaction);

  loadAssetsForAccount(from);
}

Future<void> send(
    String destination,
    Decimal amount,
    Asset asset,
    String? memo,
    Account from,
    Asset? toAsset,
    Decimal? receiveAmount,
    List<stellar_sdk.Asset>? path) async {
  var sdk = getSDK(from.testnet);
  stellar_sdk.AccountResponse sender = await sdk.accounts.account(from.address);

  var tb = stellar_sdk.TransactionBuilder(sender);
  if (toAsset == null) {
    tb.addOperation(stellar_sdk.PaymentOperationBuilder(
            destination, toStellarSDKAsset(asset), amount.toString())
        .build());
  } else {
    var allowedSlippage = Decimal.parse("0.01");
    tb.addOperation(stellar_sdk.PathPaymentStrictSendOperationBuilder(
            toStellarSDKAsset(asset),
            amount.toString(),
            destination,
            toStellarSDKAsset(toAsset),
            (receiveAmount! * (Decimal.one - allowedSlippage))
                .toStringAsFixed(7))
        .setPath(path!)
        .build());
  }

  if (memo != null) {
    tb.addMemo(stellar_sdk.MemoText(memo));
  }
  var transaction = tb.build();
  // Sign the transaction with the sender's key pair.
  var kp = stellar_sdk.KeyPair.fromSecretSeed(from.secret);
  transaction.sign(kp,
      from.testnet ? stellar_sdk.Network.TESTNET : stellar_sdk.Network.PUBLIC);

  await submitTransaction(sdk, transaction);

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

Future<({Decimal sendAmount, List<stellar_sdk.Asset> path})?>
    findBestStrictReceive(
        Asset fromAsset, Decimal receiveAmount, Asset toAsset) async {
  var sdk = getSDK(fromAsset.testnet);
  var requestBuilder = sdk.strictReceivePaths;
  var response = await requestBuilder
      .sourceAssets([toStellarSDKAsset(fromAsset)])
      .destinationAmount(receiveAmount.toStringAsFixed(7))
      .destinationAsset(toStellarSDKAsset(toAsset))
      .execute();
  if (response.records == null || response.records!.isEmpty) {
    return null;
  }

  var result = (sendAmount: Decimal.zero, path: <stellar_sdk.Asset>[]);
  for (var record in response.records!) {
    var amount = Decimal.parse(record.sourceAmount);
    if ((amount < result.sendAmount) || result.sendAmount == Decimal.zero) {
      result = (sendAmount: amount, path: record.path);
    }
  }
  return result;
}

Future<void> swap(
    Asset fromAsset,
    Decimal sendAmount,
    Asset toAsset,
    Decimal receiveAmount,
    Decimal allowedSlippage,
    Account from,
    List<stellar_sdk.Asset> path,
    {bool strictSend = true}) async {
  var sdk = getSDK(from.testnet);
  stellar_sdk.AccountResponse sender = await sdk.accounts.account(from.address);

  var tb = stellar_sdk.TransactionBuilder(sender);
  if (strictSend) {
    tb.addOperation(stellar_sdk.PathPaymentStrictSendOperationBuilder(
            toStellarSDKAsset(fromAsset),
            sendAmount.toString(),
            from.address,
            toStellarSDKAsset(toAsset),
            (receiveAmount * (Decimal.one - allowedSlippage))
                .toStringAsFixed(7))
        .setPath(path)
        .build());
  } else {
    tb.addOperation(stellar_sdk.PathPaymentStrictReceiveOperationBuilder(
            toStellarSDKAsset(fromAsset),
            (sendAmount * (Decimal.one + allowedSlippage)).toStringAsFixed(7),
            from.address,
            toStellarSDKAsset(toAsset),
            receiveAmount.toString())
        .setPath(path)
        .build());
  }
  tb.setMaxOperationFee(maxBaseFee);

  var transaction = tb.build();

  // Sign the transaction with the sender's key pair.
  var kp = stellar_sdk.KeyPair.fromSecretSeed(from.secret);
  transaction.sign(kp,
      from.testnet ? stellar_sdk.Network.TESTNET : stellar_sdk.Network.PUBLIC);

  await submitTransaction(sdk, transaction);

  loadAssetsForAccount(from);
}

Future<void> submitTransaction(
    stellar_sdk.StellarSDK sdk, stellar_sdk.Transaction transaction) async {
  try {
    stellar_sdk.SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);

    if (!response.success) {
      logger.e(
          'Failed to submit transaction: ${response.toString()} extras: ${response.extras?.resultCodes?.transactionResultCode}');
      throw StellarException.fromSubmitTransactionResponse(response);
    }
  } on stellar_sdk.SubmitTransactionTimeoutResponseException {
    logger.w("Timeout while submitting transaction");
    throw StellarException.timeout();
  }
}
