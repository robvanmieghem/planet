import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as stellar_sdk;

import '../appmodel.dart';
import '../widgets/appbar.dart';

class AccountAddPageModel extends ChangeNotifier {
  Account account = Account();
  AccountAddPageModel(bool testnet) {
    account.testnet = testnet;
  }
  void setFriendlyName(String value) {
    account.friendlyName = value;
    notifyListeners();
  }

  void setSecret(String secret) {
    account.secret = secret;
    notifyListeners();
  }

  bool createNew = true;
  void setCreateNew(bool? value) {
    createNew = value ?? false;
    notifyListeners();
  }

  String? friendlyNameError;
  String? secretError;

  void createNewAccountIfNeeded() {
    if (!createNew) return;
    var kp = stellar_sdk.KeyPair.random();
    setSecret(kp.secretSeed);
  }

  bool validate() {
    friendlyNameError = account.friendlyName == '' ? 'Required' : null;
    secretError = account.secret == '' ? 'Required' : null;
    if (secretError == null) {
      try {
        var kp = stellar_sdk.KeyPair.fromSecretSeed(account.secret);
        secretError = null;
        account.address = kp.accountId;
      } on FormatException {
        secretError = 'Invalid secret';
      }
    }
    notifyListeners();
    var valid = friendlyNameError == null && secretError == null;
    return valid;
  }
}

class AccountAddPage extends StatelessWidget {
  const AccountAddPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createSimpleAppBar(context, 'Add Account'),
      body: Center(
        child: Consumer<AccountAddPageModel>(
            builder: (context, model, child) =>
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 5),
                      child: TextField(
                        decoration: InputDecoration(
                            labelText: 'Name',
                            border: const OutlineInputBorder(),
                            errorText: model.friendlyNameError),
                        autocorrect: false,
                        onChanged: (value) => {model.setFriendlyName(value)},
                      )),
                  ListTile(
                    title: const Text('Create new'),
                    leading: Radio(
                      value: true,
                      groupValue: model.createNew,
                      onChanged: (value) => model.setCreateNew(true),
                    ),
                  ),
                  ListTile(
                    title: const Text('Import existing'),
                    leading: Radio(
                      value: false,
                      groupValue: model.createNew,
                      onChanged: (value) => model.setCreateNew(false),
                    ),
                  ),
                  if (!model.createNew)
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 5),
                        child: TextField(
                          decoration: InputDecoration(
                              labelText: 'Secret',
                              border: const OutlineInputBorder(),
                              errorText: model.secretError),
                          autocorrect: false,
                          onChanged: (value) => {model.setSecret(value)},
                        ))
                ])),
      ),
      floatingActionButton: Consumer<AccountAddPageModel>(
          builder: (context, model, child) => FloatingActionButton(
                tooltip: 'Add',
                onPressed: () {
                  model.createNewAccountIfNeeded();
                  if (model.validate()) {
                    context.read<AppState>().addAccount(model.account);
                    Navigator.of(context).pop();
                  }
                },
                child: const Icon(Icons.add),
              )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const BottomAppBar(),
    );
  }
}
