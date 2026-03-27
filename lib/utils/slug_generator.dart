/// Generates collision-free short slugs by base62-encoding SQLite row IDs.
///
/// Strategy: drift's auto-increment id guarantees uniqueness at the DB level.
/// Encoding the id as base62 produces a 6-character slug for ids up to
/// 62^6 = ~56 billion — more than sufficient for personal use.
///
/// No SELECT-before-INSERT needed. No retry loop. No UNIQUE collision check.
/// (See PITFALLS.md Pitfall 4.)
class SlugGenerator {
  static const String _chars =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  static const int _base = 62;
  static const int _length = 6;

  /// Encode [id] as a zero-padded 6-character base62 string.
  ///
  /// [id] must be a positive integer (SQLite autoincrement row id).
  /// Returns the same string for the same input (deterministic).
  static String generate(int id) {
    assert(id > 0, 'id must be a positive integer');
    var n = id;
    final buffer = StringBuffer();
    while (n > 0) {
      buffer.write(_chars[n % _base]);
      n ~/= _base;
    }
    // Left-pad with '0' to reach _length characters.
    final raw = buffer.toString().split('').reversed.join();
    return raw.padLeft(_length, '0');
  }
}
