import 'package:flutter/material.dart';
import 'package:planet/appmodel.dart';
import 'package:provider/provider.dart';
import 'pages/accountlist.dart';
import 'pages/appsettings.dart';

void main() async {
  var p = AppStatePersistency();
  var appstate = await p.load();
  appstate.addListener(() {
    p.save(appstate);
  });
  runApp(ChangeNotifierProvider(
      create: (context) => appstate, child: const MyApp()));
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
      home: const MyHomePage(title: 'Home'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Consumer<AppState>(
            builder: (context, appstate, child) =>
                Text('$title${appstate.testnet ? ' - Testnet' : ''}')),
      ),
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
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Consumer<AppState>(
                builder: (context, appstate, child) => Text(
                      '${appstate.counter}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<AppState>().increment();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
