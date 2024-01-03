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

class SwapPageModel extends ChangeNotifier {
  Asset fromAsset;

  void setFromAsset(Asset value) {
    fromAsset = value;
    notifyListeners();
  }

  Asset toAsset;

  void setToAsset(Asset value) {
    toAsset = value;
    notifyListeners();
  }

  List<stellar_sdk.Asset>? path;

  Decimal? sendAmount;
  String sendAmountString = "";
  String? sendAmountError;
  void setSendAmount(String value) {
    if (sendAmountError != null) {
      //Clear the error if a value is entered after a failed send button click
      sendAmountError = null;
    }
    sendAmountString = value;
    sendAmount = Decimal.tryParse(value);
    if (sendAmount == null || sendAmount! == Decimal.zero) {
      receiveAmount = Decimal.zero;
      receiveAmountString = "";
    } else {
      findBestStrictSend(fromAsset, sendAmount!, toAsset).then((value) {
        if (value == null) {
          //TODO: Show that there is no path and set in model
        } else {
          receiveAmount = value.receiveAmount;
          receiveAmountString = receiveAmount.toString();
          path = value.path;
        }
        notifyListeners();
      }).onError((error, stackTrace) {
        //TODO: show error
      });
    }
    notifyListeners();
  }

  Decimal? receiveAmount;
  String receiveAmountString = "";
  String? receiveAmountError;
  void setReceiveAmount(String value) {
    if (receiveAmountError != null) {
      //Clear the error if a value is entered after a failed send button click
      receiveAmountError = null;
    }
    receiveAmount = Decimal.tryParse(value);
    notifyListeners();
  }

  SwapPageModel({required this.fromAsset, required this.toAsset});

  bool validate() {
    if (sendAmount == Decimal.zero || sendAmount == null) {
      sendAmountError = 'Required';
    } else if (sendAmount! > fromAsset.amount) {
      sendAmountError = 'Insufficient funds';
    } else {
      sendAmountError = null;
    }
    if (receiveAmount == Decimal.zero || receiveAmount == null) {
      receiveAmountError = 'Required';
    } else {
      receiveAmountError = null;
    }
    notifyListeners();
    return sendAmountError == null && receiveAmountError == null;
  }
}

class SwapPage extends StatelessWidget {
  SwapPage({super.key});

  final sendAmountController = TextEditingController();

  final receiveAmountController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    var model = context.read<SwapPageModel>();
    model.addListener(() {
      sendAmountController.text = model.sendAmountString;
      receiveAmountController.text = model.receiveAmountString;
    });

    return Scaffold(
      appBar: createSimpleAppBar(context, 'Swap'),
      body: Center(
          child: Consumer<SwapPageModel>(
              builder: (context, model, child) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("From"),
                        Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(children: [
                              Flexible(
                                  child: TextField(
                                controller: sendAmountController,
                                decoration: InputDecoration(
                                    hintText: "0.0",
                                    border: InputBorder.none,
                                    errorText: model.sendAmountError),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: getAmountTextInputFormatters(),
                                autocorrect: false,
                                onChanged: (value) =>
                                    {model.setSendAmount(value)},
                              )),
                              const Spacer(),
                              Flexible(
                                  child: ListTile(
                                title: Text(model.fromAsset.info.name ??
                                    model.fromAsset.code),
                                subtitle:
                                    Text(model.fromAsset.info.domain ?? ''),
                                leading: model.fromAsset.isNative()
                                    ? const Icon(PlanetIcon.xlmIcon)
                                    : model.fromAsset.info.image != null
                                        ? Image(
                                            image: NetworkImage(
                                                model.fromAsset.info.image!))
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
                                        model.setFromAsset(result);
                                      }
                                    });
                                  },
                                ),
                              )),
                            ])),
                        Row(
                          children: [
                            const Spacer(),
                            TextButton(
                                onPressed: () {
                                  model.setSendAmount(
                                      model.fromAsset.amount.toString());
                                },
                                child: Text('Max ${model.fromAsset.amount}'))
                          ],
                        ),
                        const Text("To"),
                        Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(children: [
                              Flexible(
                                  child: TextField(
                                controller: receiveAmountController,
                                decoration: InputDecoration(
                                    hintText: "0.0",
                                    border: InputBorder.none,
                                    errorText: model.receiveAmountError),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: getAmountTextInputFormatters(),
                                autocorrect: false,
                                onChanged: (value) =>
                                    {model.setReceiveAmount(value)},
                              )),
                              const Spacer(),
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
                            ])),
                      ]))),
      floatingActionButton: Consumer<SwapPageModel>(
          builder: (context, model, child) => FloatingActionButton(
                tooltip: 'Swap',
                onPressed: () {
                  if (model.validate()) {
                    showDialog(
                      context: context,
                      builder: (context) => FutureProgressDialog(
                        swap(
                                model.fromAsset,
                                model.sendAmount!,
                                model.toAsset,
                                model.receiveAmount!,
                                Decimal.parse("0.01"),
                                context.read<AppState>().currentAccount!,
                                model.path!)
                            .then((result) {
                          Navigator.pop(context, 'swapped');
                        }).onError<StellarException>((error, stackTrace) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(error.toString()),
                            showCloseIcon: true,
                          ));
                        }),
                      ),
                    );
                  }
                },
                child: const Text('Swap'),
              )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const BottomAppBar(),
    );
  }
}
