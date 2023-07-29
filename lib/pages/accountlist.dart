import 'package:flutter/material.dart';
import 'appsettings.dart';

class AccountListPage extends StatelessWidget {
  const AccountListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text('Accounts'),
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              const ListTile(
                leading: Icon(Icons.account_balance),
                title: Text('Assets'),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const AppSettingsPage()));
                },
              )
            ],
          ),
        ),
        body: Center(
            child: Column(
          children: [],
        )));
  }
}
