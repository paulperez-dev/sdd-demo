import 'dart:ui';

import 'package:flutter/material.dart';
import 'server/server_controller.dart';
import 'db/database.dart';
import 'ui/shortener_screen.dart';

class App extends StatefulWidget {
  final ServerController serverController;
  final AppDatabase database;

  const App({
    super.key,
    required this.serverController,
    required this.database,
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    // AppLifecycleListener is the correct hook for desktop window close.
    // widget.dispose() is NOT reliably called on desktop window close
    // (flutter/flutter#113220) — hence AppLifecycleListener here.
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        await widget.serverController.stop();
        await widget.database.close();
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URL Shortener',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: ShortenerScreen(serverController: widget.serverController),
    );
  }
}
