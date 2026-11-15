import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/inventory_database.dart';
import 'screens/home_screen.dart';
import 'state/inventory_store.dart';
import 'theme.dart';
import 'widgets/empty_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InventoryApp());
}

class InventoryApp extends StatefulWidget {
  const InventoryApp({super.key});

  @override
  State<InventoryApp> createState() => _InventoryAppState();
}

class _InventoryAppState extends State<InventoryApp> {
  final _store = InventoryStore(InventoryDatabase());
  late Future<void> _initialLoad;

  @override
  void initState() {
    super.initState();
    _initialLoad = _store.load();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store.settingsListenable,
      builder: (context, child) => MaterialApp(
        title: _store.settings.title,
        debugShowCheckedModeBanner: false,
        locale: const Locale('es', 'AR'),
        supportedLocales: const [Locale('es', 'AR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: buildTheme(_store.settings, Brightness.light),
        darkTheme: buildTheme(_store.settings, Brightness.dark),
        themeMode: _store.settings.themeMode,
        home: FutureBuilder<void>(
          future: _initialLoad,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Scaffold(
                body: EmptyState(
                  icon: Icons.storage_outlined,
                  title: 'No pudimos abrir el inventario',
                  message:
                      'Ocurrió un error al leer los datos del dispositivo.',
                  action: FilledButton(
                    onPressed: () {
                      setState(() => _initialLoad = _store.load());
                    },
                    child: const Text('Reintentar'),
                  ),
                ),
              );
            }
            return HomeScreen(store: _store);
          },
        ),
      ),
    );
  }
}
