import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:sdd_demo/db/database.dart';
import 'package:sdd_demo/server/handlers/redirect_handler.dart';
import 'package:sdd_demo/utils/slug_generator.dart';

void main() {
  late AppDatabase db;
  late Handler handler;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    handler = makeRedirectHandler(db.urlDao);
  });

  tearDown(() async {
    await db.close();
  });

  /// Helper: insert a URL and return its real slug.
  Future<String> insertUrl(String originalUrl) async {
    final tempSlug = '_t${DateTime.now().millisecondsSinceEpoch % 100000}';
    final rowId =
        await db.urlDao.insertUrl(slug: tempSlug, originalUrl: originalUrl);
    final slug = SlugGenerator.generate(rowId);
    await db.urlDao.updateSlug(rowId: rowId, slug: slug);
    return slug;
  }

  /// Build a GET request with shelf_router/params context injected,
  /// matching how ServerController dispatches to the handler.
  Request makeSlugRequest(String slug) {
    return Request(
      'GET',
      Uri.parse('http://localhost:8080/$slug'),
    ).change(context: {
      'shelf_router/params': <String, String>{'slug': slug},
    });
  }

  group('GET /<slug>', () {
    test('known slug returns 302 with Location header', () async {
      final slug = await insertUrl('https://example.com');
      final response = await handler(makeSlugRequest(slug));

      expect(response.statusCode, equals(302));
      expect(response.headers['location'], equals('https://example.com'));
    });

    test('unknown slug returns 404', () async {
      final response = await handler(makeSlugRequest('ZZZZZZ'));

      expect(response.statusCode, equals(404));
      expect(await response.readAsString(), equals('Not found'));
    });

    test('empty slug returns 404', () async {
      final response = await handler(makeSlugRequest(''));

      expect(response.statusCode, equals(404));
    });

    test('response includes Cache-Control: no-store', () async {
      final slug = await insertUrl('https://example.com');
      final response = await handler(makeSlugRequest(slug));

      expect(response.headers['cache-control'], equals('no-store'));
    });
  });
}
