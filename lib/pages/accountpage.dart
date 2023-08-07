import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../appmodel.dart';
import 'accountlist.dart';

class AccountPageModel extends ChangeNotifier {
  Account account;

  AccountPageModel({required this.account});
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Consumer<AppState>(
              builder: (context, appstate, child) => Text(
                  '${appstate.currentAccount?.friendlyName}${appstate.testnet ? ' - Testnet' : ''}')),
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('Accounts'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AccountListPage()));
                },
              )
            ],
          ),
        ),
        body: Center(
            child: Consumer<AppState>(
                builder: (context, appstate, child) => Column(
                      children: [
                        const Row(
                          children: [Text('Assets')],
                        ),
                        for (var asset in appstate.currentAccount!.assets) ...[
                          Card(
                              child: ListTile(
                            title: Text(asset.code),
                          ))
                        ],
                      ],
                    ))));
  }
}
