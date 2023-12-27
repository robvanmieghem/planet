import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:planet/pages/sendpage.dart';
import 'package:planet/pages/swappage.dart';
import 'package:provider/provider.dart';
import '../appmodel.dart';
import '../widgets/appbar.dart';
import '../widgets/icons.dart';

class AssetPage extends StatelessWidget {
  const AssetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: createSimpleAppBar(context, context.read<Asset>().code),
        body: Center(
            child: Consumer<Asset>(
                builder: (context, asset, child) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: ListTile(
                                  title: Text(asset.info.name ?? asset.code),
                                  subtitle: Text(asset.info.domain ?? ''),
                                  leading: asset.isNative()
                                      ? const Icon(PlanetIcon.xlmIcon)
                                      : asset.info.image != null
                                          ? Image(
                                              image: NetworkImage(
                                                  asset.info.image!))
                                          : null,
                                  trailing: Text('${asset.amount}'))),
                          if (!asset.isNative())
                            Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text('Issuer: ${asset.issuer}')),
                          if (asset.info.description != null)
                            Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text(asset.info.description!)),
                          Row(children: [
                            FilledButton.tonal(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ChangeNotifierProvider<
                                                      SendPageModel>(
                                                  create: (_) => SendPageModel(
                                                      asset: asset),
                                                  child: SendPage()))).then(
                                      (result) {
                                    //TODO: No clue why but the result is always null
                                    print(result);
                                    if (!context.mounted) return;
                                    if (result == 'sent') {
                                      Navigator.pop(context);
                                    }
                                  });
                                },
                                child: const Row(children: [
                                  Text('Send'),
                                  Icon(Icons.arrow_upward)
                                ])),
                            FilledButton.tonal(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ChangeNotifierProvider<
                                                      SwapPageModel>(
                                                  create: (_) => SwapPageModel(
                                                      fromAsset: asset,
                                                      toAsset: Asset(
                                                          code: "XLM",
                                                          issuer: "",
                                                          amount: Decimal.one)),
                                                  child: SwapPage()))).then(
                                      (result) {
                                    print(result);
                                    if (!context.mounted) return;
                                    if (result == 'swapped') {
                                      Navigator.pop(context);
                                    }
                                  });
                                },
                                child: const Row(children: [
                                  Text('Swap'),
                                  Icon(Icons.swap_horiz)
                                ])),
                          ]),
                        ]))));
  }
}
