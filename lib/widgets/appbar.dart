import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../appmodel.dart';

AppBar createAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    title: Consumer<AppState>(
        builder: (context, appstate, child) =>
            Text('$title${appstate.testnet ? ' - Testnet' : ''}')),
  );
}
