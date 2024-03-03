import 'package:flutter/material.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'package:planet/appmodel.dart';
import 'package:provider/provider.dart';

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as stellar_sdk;
import '../stellar/stellar.dart';
import '../widgets/appbar.dart';

class AddAssetPageModel extends ChangeNotifier {
  String? issuer;
  String? issuerError;
  void setIsser(String value) {
    if (issuerError != null) {
      //Clear the error if a value is entered after a failed add button click
      issuerError = null;
    }
    issuer = value;
    notifyListeners();
  }

  String? assetCode;
  String? assetCodeError;
  void setassetCode(String value) {
    if (assetCodeError != null) {
      //Clear the error if a value is entered after a failed add button click
      assetCodeError = null;
    }
    assetCode = value;
    notifyListeners();
  }

  bool validate() {
    if (assetCode == '' || assetCode == null) {
      assetCodeError = 'Required';
    }
    if (issuer == '' || issuer == null) {
      issuerError = 'Required';
    } else {
      try {
        stellar_sdk.StrKey.decodeStellarAccountId(issuer!);
      } catch (e) {
        issuerError = 'Invalid issuer';
      }
    }
    notifyListeners();
    return issuerError == null && assetCodeError == null;
  }
}

class AddAssetPage extends StatelessWidget {
  const AddAssetPage({super.key});

  @override
  Widget build(BuildContext context) {
    var account = context.read<AppState>().currentAccount!;
    return Scaffold(
      appBar:
          createSimpleAppBar(context, 'Add asset to ${account.friendlyName}'),
      body: Center(
          child: Consumer<AddAssetPageModel>(
              builder: (context, model, child) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: TextField(
                              decoration: InputDecoration(
                                  labelText: 'Code',
                                  border: const OutlineInputBorder(),
                                  errorText: model.assetCodeError),
                              autocorrect: false,
                              onChanged: (value) => {model.setassetCode(value)},
                            )),
                        Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: TextField(
                              decoration: InputDecoration(
                                  labelText: 'Issuer',
                                  border: const OutlineInputBorder(),
                                  errorText: model.issuerError),
                              autocorrect: false,
                              onChanged: (value) => {model.setIsser(value)},
                            ))
                      ]))),
      floatingActionButton: Consumer<AddAssetPageModel>(
          builder: (context, model, child) => FloatingActionButton(
                tooltip: 'Add asset',
                onPressed: () {
                  if (model.validate()) {
                    showDialog(
                      context: context,
                      builder: (context) => FutureProgressDialog(
                        addTrustline(
                          model.assetCode!,
                          model.issuer!,
                          context.read<AppState>().currentAccount!,
                        ).then((result) {
                          Navigator.pop(context, 'Asset added');
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
                child: const Text('Add'),
              )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const BottomAppBar(),
    );
  }
}
