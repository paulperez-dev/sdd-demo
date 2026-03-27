import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:sdd_demo/db/database.dart';
import 'package:sdd_demo/server/handlers/shorten_handler.dart';

void main() {
  late AppDatabase db;
  late Handler handler;
  const testPort = 9999;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    handler = makeShortenHandler(db.urlDao, testPort);
  });

  tearDown(() async {
    await db.close();
  });

  group('POST /shorten', () {
    test('valid URL returns 200 with JSON shortUrl', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost:$testPort/shorten'),
        body: 'https://example.com/long/path',
      );

      final response = await handler(request);
      expect(response.statusCode, equals(200));

      final body = jsonDecode(await response.readAsString());
      expect(body['shortUrl'], startsWith('http://localhost:$testPort/'));
      expect(body['shortUrl'], isNot(contains('_t'))); // no temp slug
    });

    test('empty body returns 400', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost:$testPort/shorten'),
        body: '',
      );

      final response = await handler(request);
      expect(response.statusCode, equals(400));
      expect(await response.readAsString(), equals('URL is required'));
    });

    test('URL without scheme gets https:// prepended', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost:$testPort/shorten'),
        body: 'example.com',
      );

      final response = await handler(request);
      expect(response.statusCode, equals(200));

      // Verify the stored URL has https://
      final body = jsonDecode(await response.readAsString());
      final slug = (body['shortUrl'] as String).split('/').last;
      final url = await db.urlDao.findBySlug(slug);
      expect(url!.originalUrl, equals('https://example.com'));
    });

    test('ftp:// scheme is rejected with 400', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost:$testPort/shorten'),
        body: 'ftp://example.com/file.zip',
      );

      final response = await handler(request);
      expect(response.statusCode, equals(400));
      expect(await response.readAsString(),
          equals('Only http:// and https:// URLs are accepted'));
    });

    test('JSON body with url field also works', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost:$testPort/shorten'),
        body: jsonEncode({'url': 'https://example.com'}),
        headers: {'content-type': 'application/json'},
      );

      final response = await handler(request);
      expect(response.statusCode, equals(200));

      final body = jsonDecode(await response.readAsString());
      expect(body['shortUrl'], startsWith('http://localhost:$testPort/'));
    });
  });
}
