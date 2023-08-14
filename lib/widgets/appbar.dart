import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../appmodel.dart';

AppBar createSimpleAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: getAppBarColor(context),
    title: Consumer<AppState>(
        builder: (context, appstate, child) =>
            Text('$title${appstate.testnet ? ' - Testnet' : ''}')),
  );
}

Color getAppBarColor(BuildContext context) {
  return Theme.of(context).colorScheme.inversePrimary;
}
