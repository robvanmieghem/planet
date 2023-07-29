import 'package:flutter/material.dart';
import 'package:planet/appmodel.dart';
import 'package:provider/provider.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: () {
                Navigator.of(context).pop();
              }),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: const Text('Settings'),
        ),
        body: Center(
          child: Column(children: [
            Row(
              children: [
                const Text('Testnet'),
                Consumer<AppState>(
                    builder: (context, appstate, child) => Switch(
                        value: appstate.testnet,
                        onChanged: (newvalue) {
                          context.read<AppState>().setNetwork(newvalue);
                        }))
              ],
            )
          ]),
        ));
  }
}
