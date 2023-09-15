import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'package:provider/provider.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as stellar_sdk;
import '../appmodel.dart';
import '../stellar/stellar.dart';
import '../widgets/appbar.dart';

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
              builder: (context, model, child) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: TextField(
                              decoration: InputDecoration(
                                  labelText: 'To',
                                  border: const OutlineInputBorder(),
                                  errorText: model.destinationError),
                              autocorrect: false,
                              onChanged: (value) =>
                                  {model.setDestination(value)},
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
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9]+[,.]{0,1}[0-9]{0,7}')),
                                  TextInputFormatter.withFunction(
                                    (oldValue, newValue) => newValue.copyWith(
                                      text: newValue.text.replaceAll(',', '.'),
                                    ),
                                  ),
                                  TextInputFormatter.withFunction(
                                    // The max 7 decimal digits in the regex does not seem to work
                                    (oldValue, newValue) {
                                      var d = Decimal.tryParse(newValue.text);
                                      if (d == null) {
                                        return const TextEditingValue(text: '');
                                      }
                                      if (d.scale > 7) {
                                        return TextEditingValue(
                                            text: d
                                                .floor(scale: 7)
                                                .toStringAsFixed(7));
                                      }
                                      return newValue;
                                    },
                                  ),
                                ],
                                autocorrect: false,
                                onChanged: (value) => {model.setAmount(value)},
                              )),
                              TextButton(
                                  onPressed: () {
                                    amountController.text =
                                        model.asset.amount.toString();
                                    model.setAmount(
                                        model.asset.amount.toString());
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
                      ]))),
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
                                context.read<AppState>().currentAccount!)
                            .then((result) {
                          Navigator.of(context).pop();
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
