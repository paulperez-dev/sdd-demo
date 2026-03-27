import 'package:flutter_test/flutter_test.dart';
import 'package:sdd_demo/utils/slug_generator.dart';

void main() {
  group('SlugGenerator.generate', () {
    test('id 1 returns "000001"', () {
      expect(SlugGenerator.generate(1), equals('000001'));
    });

    test('id 62 returns "000010" (first carry into second digit)', () {
      expect(SlugGenerator.generate(62), equals('000010'));
    });

    test('id 62*62 returns "000100" (second carry)', () {
      expect(SlugGenerator.generate(62 * 62), equals('000100'));
    });

    test('large id still produces a 6-character string', () {
      final slug = SlugGenerator.generate(999999);
      expect(slug.length, equals(6));
    });

    test('output is deterministic (same input, same output)', () {
      final a = SlugGenerator.generate(42);
      final b = SlugGenerator.generate(42);
      expect(a, equals(b));
    });
  });
}
