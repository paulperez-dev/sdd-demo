import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'url_dao.dart';

part 'database.g.dart';

/// The urls table schema.
/// slug has a UNIQUE constraint — prevents duplicate short codes.
/// Use auto-increment id and encode to base62 for collision-free slug generation.
class Urls extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get slug => text().withLength(min: 5, max: 10).unique()();
  TextColumn get originalUrl => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Resolves the stable database path using path_provider.
/// MUST use getApplicationSupportDirectory(), NOT getDatabasesPath() —
/// getDatabasesPath() resolves to CWD on desktop, which differs between
/// debug and release builds (see PITFALLS.md Pitfall 6).
Future<File> getDatabaseFile() async {
  final dir = await getApplicationSupportDirectory();
  return File(p.join(dir.path, 'urls.db'));
}

@DriftDatabase(tables: [Urls], daos: [UrlDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final file = await getDatabaseFile();
    // WAL mode: allows concurrent reads from server and UI isolates
    // without readers blocking writers.
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        db.execute('PRAGMA journal_mode=WAL;');
      },
    );
  });
}
