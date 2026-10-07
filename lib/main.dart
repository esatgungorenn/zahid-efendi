import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';
import 'screens/charts_screen.dart';
import 'screens/exams_screen.dart';
import 'screens/home_screen.dart';
import 'screens/schools_screen.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  final table = SchoolTable.fromJson(
      jsonDecode(await rootBundle.loadString('assets/schools.json'))
          as Map<String, dynamic>);
  final store = AppStore(File('${dir.path}/data.json'), table);
  await store.load();
  runApp(ZahitEfendiApp(store: store));
}

class ZahitEfendiApp extends StatelessWidget {
  final AppStore store;
  const ZahitEfendiApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Zahit Efendi',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('tr', 'TR'),
        supportedLocales: const [Locale('tr', 'TR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const Shell(),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  void _go(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenSchools: () => _go(3)),
      const ExamsScreen(),
      const ChartsScreen(),
      const SchoolsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _go,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Ana sayfa'),
          NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Denemeler'),
          NavigationDestination(
              icon: Icon(Icons.show_chart), label: 'Grafikler'),
          NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: 'Liseler'),
        ],
      ),
    );
  }
}
