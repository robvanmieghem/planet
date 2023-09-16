import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../appmodel.dart';
import '../widgets/appbar.dart';

class ReceivePage extends StatelessWidget {
  const ReceivePage({super.key});

  @override
  Widget build(BuildContext context) {
    var account = context.read<AppState>().currentAccount!;
    return Scaffold(
      appBar: createSimpleAppBar(context, 'Receive on ${account.friendlyName}'),
      body: Center(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Padding(
            padding: const EdgeInsets.all(10.0), child: Text(account.address)),
        FilledButton.tonal(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: account.address));
            },
            child: const Text('Copy')),
      ])),
    );
  }
}
