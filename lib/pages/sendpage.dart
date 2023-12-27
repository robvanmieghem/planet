import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'package:provider/provider.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as stellar_sdk;
import '../appmodel.dart';
import '../stellar/stellar.dart';
import '../widgets/appbar.dart';
import '../widgets/icons.dart';
import '../widgets/input.dart';
import 'selectassetpage.dart';

class SendPageModel extends ChangeNotifier {
  Asset asset;

  String? destination;
  String? destinationError;
  void setDestination(String value) {
    if (destinationError != null) {
      //Clear the error if a value is entered after a failed send button click
      destinationError = null;
    }
    destination = value;
    notifyListeners();
  }

  Decimal? amount;
  String? amountError;
  void setAmount(String value) {
    if (amountError != null) {
      //Clear the error if a value is entered after a failed send button click
      amountError = null;
    }
    amount = Decimal.tryParse(value);
    calculateReceiveAmountAndPath();
    notifyListeners();
  }

  String? memo;
  String? memoError;
  void setMemo(String value) {
    try {
      stellar_sdk.MemoText(value);
      memoError = null;
    } on stellar_sdk.MemoTooLongException {
      memoError = 'Too long';
    }
    memo = value;
    notifyListeners();
  }

  bool convert = false;
  void setConvert(bool? value) {
    convert = value == true;
    notifyListeners();
    calculateReceiveAmountAndPath();
  }

  void calculateReceiveAmountAndPath() {
    if (amount == null || amount! == Decimal.zero) {
      receiveAmount = null;
      notifyListeners();
    } else {
      findBestStrictSend(asset, amount!, toAsset).then((value) {
        if (value == null) {
          //TODO: Show that there is no path and set in model
        } else {
          receiveAmount = value.receiveAmount;
          path = value.path;
        }
        notifyListeners();
      }).onError((error, stackTrace) {
        //TODO: show error
      });
    }
  }

  Asset toAsset = Asset(code: "XLM", issuer: "", amount: Decimal.zero);

  void setToAsset(Asset value) {
    toAsset = value;
    notifyListeners();
  }

  Decimal? receiveAmount;
  List<stellar_sdk.Asset>? path;

  SendPageModel({required this.asset});

  bool validate() {
    if (amount == Decimal.zero || amount == null) {
      amountError = 'Required';
    } else if (amount! > asset.amount) {
      amountError = 'Insufficient funds';
    } else {
      amountError = null;
    }
    if (destination == '' || destination == null) {
      destinationError = 'Required';
    } else {
      try {
        stellar_sdk.StrKey.decodeStellarAccountId(destination!);
      } catch (e) {
        destinationError = 'Invalid address';
      }
    }
    notifyListeners();
    return destinationError == null && amountError == null && memoError == null;
  }
}

class SendPage extends StatelessWidget {
  SendPage({super.key});

  final amountController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createSimpleAppBar(
          context, 'Send ${context.read<SendPageModel>().asset.code}'),
      body: Center(
        child: Consumer<SendPageModel>(
            builder: (context, model, child) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: TextField(
                        decoration: InputDecoration(
                            labelText: 'To',
                            border: const OutlineInputBorder(),
                            errorText: model.destinationError),
                        autocorrect: false,
                        onChanged: (value) => {model.setDestination(value)},
                      )),
                  Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Row(children: [
                        Flexible(
                            child: TextField(
                          controller: amountController,
                          decoration: InputDecoration(
                              labelText: 'Amount',
                              border: const OutlineInputBorder(),
                              errorText: model.amountError),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: getAmountTextInputFormatters(),
                          autocorrect: false,
                          onChanged: (value) => {model.setAmount(value)},
                        )),
                        TextButton(
                            onPressed: () {
                              amountController.text =
                                  model.asset.amount.toString();
                              model.setAmount(model.asset.amount.toString());
                            },
                            child: Text('Max ${model.asset.amount}'))
                      ])),
                  Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: TextField(
                        decoration: InputDecoration(
                            labelText: 'Memo (optional)',
                            border: const OutlineInputBorder(),
                            errorText: model.memoError),
                        autocorrect: false,
                        onChanged: (value) => {model.setMemo(value)},
                      )),
                  Row(
                    children: [
                      Checkbox(
                          value: model.convert,
                          onChanged: (value) {
                            model.setConvert(value);
                          }),
                      const Text("Convert")
                    ],
                  ),
                  if (model.convert)
                    Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Row(
                          children: [
                            const Text("To "),
                            Text(model.receiveAmount != null
                                ? model.receiveAmount.toString()
                                : ""),
                            Flexible(
                                child: ListTile(
                              title: Text(model.toAsset.info.name ??
                                  model.toAsset.code),
                              subtitle: model.toAsset.info.domain != null
                                  ? Text(model.toAsset.info.domain!)
                                  : null,
                              leading: model.toAsset.isNative()
                                  ? const Icon(PlanetIcon.xlmIcon)
                                  : model.toAsset.info.image != null
                                      ? Image(
                                          image: NetworkImage(
                                              model.toAsset.info.image!))
                                      : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.arrow_drop_down),
                                tooltip: "Change",
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ChangeNotifierProvider<
                                                      Account>.value(
                                                  value: context
                                                      .read<AppState>()
                                                      .currentAccount!,
                                                  builder: (context, child) {
                                                    return const SelectAssetPage();
                                                  }))).then((result) {
                                    if (result != null) {
                                      model.setToAsset(result);
                                    }
                                  });
                                },
                              ),
                            )),
                            const Spacer(),
                          ],
                        )),
                ])),
      ),
      floatingActionButton: Consumer<SendPageModel>(
          builder: (context, model, child) => FloatingActionButton(
                tooltip: 'Send',
                onPressed: () {
                  if (model.validate()) {
                    showDialog(
                      context: context,
                      builder: (context) => FutureProgressDialog(
                        send(
                                model.destination!,
                                model.amount!,
                                model.asset,
                                model.memo,
                                context.read<AppState>().currentAccount!,
                                model.convert ? model.toAsset : null,
                                model.receiveAmount,
                                model.path)
                            .then((result) {
                          Navigator.pop(context, 'sent');
                        }),
                      ),
                    );
                  }
                },
                child: const Text('Send'),
              )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const BottomAppBar(),
    );
  }
}
