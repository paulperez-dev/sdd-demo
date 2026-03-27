import 'package:flutter/material.dart';
import 'server/server_controller.dart';
import 'db/database.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database (creates SQLite file at application support directory).
  final database = AppDatabase();

  // Start the embedded HTTP server before showing the UI.
  // Port-scan fallback is handled inside ServerController.start().
  final serverController = ServerController(database: database);
  try {
    await serverController.start();
  } catch (e) {
    // Server failed to bind any port — app still launches, UI will show error.
    debugPrint('ServerController.start() failed: $e');
  }

  runApp(App(
    serverController: serverController,
    database: database,
  ));
}
