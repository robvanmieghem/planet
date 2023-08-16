import 'package:flutter/material.dart';
import 'package:planet/widgets/icons.dart';
import 'package:provider/provider.dart';
import '../appmodel.dart';
import '../stellar/stellar.dart';
import '../widgets/appbar.dart';
import 'accountlist.dart';
import 'assetpage.dart';

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
              DrawerHeader(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.inversePrimary),
                  child: Consumer<Account>(
                      builder: (context, account, child) => Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .listTileTheme
                                        .subtitleTextStyle,
                                    softWrap: false,
                                    textWidthBasis: TextWidthBasis.parent,
                                    '${account.address}'),
                                FilledButton.tonal(
                                    onPressed: () {},
                                    child: const Row(children: [
                                      Text('Send'),
                                      Spacer(),
                                      Icon(Icons.arrow_upward),
                                    ])),
                                FilledButton.tonal(
                                    onPressed: () {},
                                    child: const Row(children: [
                                      Text('Receive'),
                                      Spacer(),
                                      Icon(Icons.arrow_downward)
                                    ]))
                              ]))),
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
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ChangeNotifierProvider<Asset>.value(
                                              value: asset,
                                              child: const AssetPage())));
                            },
                            title: Text(asset.info.name ?? asset.code),
                            subtitle: Text(
                                '${asset.code}${asset.info.domain != null ? " ( ${asset.info.domain} )" : ""}'),
                            trailing: Text('${asset.amount} ${asset.code}'),
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
