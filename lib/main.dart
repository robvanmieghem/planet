import 'package:flutter/material.dart';
import 'package:planet/appmodel.dart';
import 'package:planet/pages/accountpage.dart';
import 'package:planet/widgets/appbar.dart';
import 'package:provider/provider.dart';
import 'pages/accountlist.dart';
import 'pages/appsettings.dart';

void main() {
  runApp(ChangeNotifierProvider(
      create: (context) {
        var p = AppStatePersistency();
        var appstate = AppState();
        p.load().then((value) {
          appstate.setState(value);
          appstate.setCurrentAccountByCurrentAccountAddress();
        }).whenComplete(() {
          appstate.addListener(() {
            p.save(appstate);
          });
        });

        return appstate;
      },
      //lazy: true,
      child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planet Stellar wallet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Loading'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;
  @override
  Widget build(BuildContext context) {
    var appstate = context.read<AppState>();
    void appstateListener() {
      if (appstate.loaded) {
        appstate.removeListener(appstateListener);
        Navigator.pop(context);
        if (appstate.currentAccount != null) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider<Account>(
                      create: (context) => appstate.currentAccount!,
                      child: const AccountPage())));
        } else {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AccountListPage()));
        }
      }
    }

    appstate.addListener(appstateListener);
    return Scaffold(
      appBar: createSimpleAppBar(context, title),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.inversePrimary),
                child: const Text('Current account Info')),
            const ListTile(
              leading: Icon(Icons.toll),
              title: Text('Assets'),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Accounts'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const AccountListPage()));
              },
            ),
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
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
