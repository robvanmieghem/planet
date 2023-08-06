import 'package:flutter/material.dart';
import 'package:planet/pages/accountadd.dart';
import 'package:provider/provider.dart';
import '../appmodel.dart';
import '../widgets/appbar.dart';
import 'appsettings.dart';

class AccountListPage extends StatelessWidget {
  const AccountListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: createAppBar(context, 'Accounts'),
        drawer: Drawer(
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AppSettingsPage()));
                },
              )
            ],
          ),
        ),
        body: Center(
            child: Column(
          children: [
            Card(
                child: ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Account'),
              titleAlignment: ListTileTitleAlignment.center,
              onTap: () {
                //Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ChangeNotifierProvider<AccountAddPageModel>(
                                create: (_) => AccountAddPageModel(
                                    context.read<AppState>().testnet),
                                child: AccountAddPage())));
              },
            )),
          ],
        )));
  }
}
