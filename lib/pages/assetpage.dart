import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../appmodel.dart';
import '../widgets/appbar.dart';

class AssetPage extends StatelessWidget {
  const AssetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: createSimpleAppBar(context, context.read<Asset>().code),
        body: Center(
            child: Consumer<Asset>(
                builder: (context, asset, child) => const Column())));
  }
}
