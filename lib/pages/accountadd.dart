import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  String? friendlyNameError;
  String? secretError;

  bool validate() {
    friendlyNameError = account.friendlyName == '' ? 'Required' : null;
    secretError = account.secret == '' ? 'Required' : null;
    notifyListeners();
    return friendlyNameError == '';
  }
}

class AccountAddPage extends StatelessWidget {
  const AccountAddPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createAppBar(context, 'Add Account'),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: Consumer<AccountAddPageModel>(
                  builder: (context, model, child) => TextField(
                        decoration: InputDecoration(
                            labelText: 'Name',
                            border: const OutlineInputBorder(),
                            errorText: model.friendlyNameError),
                        autocorrect: false,
                        onChanged: (value) => {model.setFriendlyName(value)},
                      ))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: Consumer<AccountAddPageModel>(
                  builder: (context, model, child) => TextField(
                        decoration: InputDecoration(
                            labelText: 'Secret',
                            border: const OutlineInputBorder(),
                            errorText: model.secretError),
                        autocorrect: false,
                        onChanged: (value) => {model.setSecret(value)},
                      )))
        ]),
      ),
      floatingActionButton: Consumer<AccountAddPageModel>(
          builder: (context, model, child) => FloatingActionButton(
                tooltip: 'Add',
                onPressed: () => {model.validate()},
                child: const Icon(Icons.add),
              )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const BottomAppBar(),
    );
  }
}
