import 'package:flutter/material.dart';
import 'package:planet/widgets/icons.dart';
import 'package:provider/provider.dart';
import '../appmodel.dart';
import '../stellar/stellar.dart';
import '../widgets/appbar.dart';
import 'accountlist.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    loadAssetsForAccount(context.read<Account>());
    return Scaffold(
        appBar: AppBar(
          backgroundColor: getAppBarColor(context),
          title: Consumer<Account>(
              builder: (context, account, child) => Text(
                  '${account.friendlyName}${account.testnet ? ' - Testnet' : ''}')),
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('Accounts'),
                onTap: () {
                  context.read<AppState>().switchAccount(null);
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
            child: Consumer<Account>(
                builder: (context, account, child) => ListView(
                      children: [
                        for (var asset in account.assets) ...[
                          Card(
                              child: ListTile(
                            title: Text(asset.code),
                            trailing: Text(asset.amount.toString()),
                            leading: asset.isNative()
                                ? const Icon(PlanetIcon.xlmIcon)
                                : const Icon(Icons.radio_button_unchecked),
                          ))
                        ],
                      ],
                    ))));
  }
}
