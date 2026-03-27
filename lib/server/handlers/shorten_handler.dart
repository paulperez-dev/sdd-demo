import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../../db/url_dao.dart';
import '../../utils/slug_generator.dart';

/// POST /shorten
///
/// Accepts a plain-text or JSON body containing the original URL.
/// Supports two body formats:
///   - Plain text: the raw URL string
///   - JSON: {"url": "https://..."}
///
/// Returns 200 JSON: {"shortUrl": "http://localhost:PORT/SLUG"}
/// Returns 400 if the URL is missing, blank, or has an invalid scheme.
///
/// URL normalisation (Pitfall 7):
/// - Trims whitespace
/// - If no scheme present, prepends "https://"
/// - Rejects non-http(s) schemes (javascript:, data:, etc.)
Handler makeShortenHandler(UrlDao urlDao, int serverPort) {
  return (Request request) async {
    final body = await request.readAsString();

    // Parse body — support both plain text and JSON {"url": "..."}.
    String rawUrl;
    final contentType = request.headers['content-type'] ?? '';
    if (contentType.contains('application/json')) {
      try {
        final json = jsonDecode(body) as Map<String, dynamic>;
        rawUrl = (json['url'] as String? ?? '').trim();
      } catch (_) {
        return Response(400, body: 'Invalid JSON body');
      }
    } else {
      rawUrl = body.trim();
    }

    if (rawUrl.isEmpty) {
      return Response(400, body: 'URL is required');
    }

    // Normalise: prepend https:// if no scheme present.
    if (!rawUrl.contains('://')) {
      rawUrl = 'https://$rawUrl';
    }

    // Validate scheme — only http and https are allowed (Pitfall 7 + security).
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme) {
      return Response(400, body: 'Invalid URL');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return Response(400,
          body: 'Only http:// and https:// URLs are accepted');
    }

    // Step 1: Insert with a temporary placeholder slug to reserve the row id.
    // Step 2: Encode the auto-increment id as base62 → real slug (Pitfall 4).
    // Step 3: Update the row with the real slug.
    // This avoids any SELECT-before-INSERT and guarantees uniqueness.
    final tempSlug = '_t${DateTime.now().millisecondsSinceEpoch % 100000000}';
    final rowId = await urlDao.insertUrl(slug: tempSlug, originalUrl: rawUrl);
    final slug = SlugGenerator.generate(rowId);
    await urlDao.updateSlug(rowId: rowId, slug: slug);

    final shortUrl = 'http://localhost:$serverPort/$slug';
    return Response.ok(
      jsonEncode({'shortUrl': shortUrl}),
      headers: {'content-type': 'application/json'},
    );
  };
}
