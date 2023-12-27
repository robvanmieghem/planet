import 'package:flutter/material.dart';
import 'package:planet/widgets/icons.dart';
import 'package:provider/provider.dart';
import '../appmodel.dart';
import '../widgets/appbar.dart';

class SelectAssetPage extends StatelessWidget {
  const SelectAssetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: createSimpleAppBar(context, 'Select asset'),
        body: Center(
            child: Consumer<Account>(
                builder: (context, account, child) => ListView(
                      children: [
                        for (var asset in account.assets) ...[
                          Card(
                              child: ListTile(
                            onTap: () {
                              Navigator.pop(context, asset);
                            },
                            title: Text(asset.info.name ?? asset.code),
                            subtitle: Text(
                                '${asset.code}${asset.info.domain != null ? " ( ${asset.info.domain} )" : ""}'),
                            trailing: Text('${asset.amount}'),
                            leading: asset.isNative()
                                ? const Icon(PlanetIcon.xlmIcon)
                                : asset.info.image != null
                                    ? Image(
                                        image: NetworkImage(asset.info.image!))
                                    : const Icon(Icons.radio_button_unchecked),
                          ))
                        ],
                      ],
                    ))));
  }
}
