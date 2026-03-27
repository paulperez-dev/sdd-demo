import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../db/url_dao.dart';

/// GET /[slug]
///
/// Looks up the slug in the database.
/// Found    → HTTP 302 redirect to original URL, Cache-Control: no-store
/// Not found → HTTP 404 plain text "Not found"
///
/// Uses 302 (not 301) to prevent browser caching — if a mapping is updated
/// or deleted, the browser must re-request the short URL (Pitfall 5).
Handler makeRedirectHandler(UrlDao urlDao) {
  return (Request request) async {
    final slug = request.params['slug'] ?? '';

    if (slug.isEmpty) {
      return Response.notFound('Not found');
    }

    final url = await urlDao.findBySlug(slug);

    if (url == null) {
      return Response.notFound('Not found');
    }

    // HTTP 302 + Cache-Control: no-store (Pitfall 5).
    return Response.found(
      url.originalUrl,
      headers: {'cache-control': 'no-store'},
    );
  };
}
