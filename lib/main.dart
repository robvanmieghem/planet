import 'package:flutter/material.dart';
import 'package:planet/appmodel.dart';
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
      appBar: createAppBar(context, title),
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
