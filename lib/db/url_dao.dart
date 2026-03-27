import 'package:drift/drift.dart';

import 'database.dart';

part 'url_dao.g.dart';

@DriftAccessor(tables: [Urls])
class UrlDao extends DatabaseAccessor<AppDatabase> with _$UrlDaoMixin {
  UrlDao(super.db);

  /// Insert a new URL mapping. Returns the auto-generated row id.
  Future<int> insertUrl({
    required String slug,
    required String originalUrl,
  }) {
    return into(urls).insert(
      UrlsCompanion.insert(
        slug: slug,
        originalUrl: originalUrl,
      ),
    );
  }

  /// Find a URL by its slug. Returns null if not found.
  Future<Url?> findBySlug(String slug) {
    return (select(urls)..where((tbl) => tbl.slug.equals(slug)))
        .getSingleOrNull();
  }

  /// Update the slug for a row by its primary key id.
  /// Used by the shorten handler after inserting with a temporary placeholder.
  Future<void> updateSlug({required int rowId, required String slug}) {
    return (update(urls)..where((tbl) => tbl.id.equals(rowId))).write(
      UrlsCompanion(slug: Value(slug)),
    );
  }
}
