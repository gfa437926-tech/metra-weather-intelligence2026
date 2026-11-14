import 'package:flutter_test/flutter_test.dart';
import 'package:metra_weather_intelligence/data/metra_api_client.dart';

void main() {
  group('parseMetraApiBaseUri', () {
    test('accepts HTTPS endpoints and removes trailing path separators', () {
      final uri = parseMetraApiBaseUri('  https://api.example.test/metra///  ');

      expect(uri.scheme, 'https');
      expect(uri.host, 'api.example.test');
      expect(uri.path, '/metra');
    });

    test('rejects plaintext HTTP endpoints', () {
      expect(
        () => parseMetraApiBaseUri('http://api.example.test'),
        throwsA(isA<MetraApiException>().having((error) => error.statusCode, 'statusCode', 0)),
      );
    });

    test('rejects URLs with embedded credentials, query strings or fragments', () {
      for (final value in [
        'https://user:password@api.example.test',
        'https://api.example.test?token=secret',
        'https://api.example.test#fragment',
      ]) {
        expect(
          () => parseMetraApiBaseUri(value),
          throwsA(isA<MetraApiException>()),
          reason: 'Unsafe endpoint must be rejected: $value',
        );
      }
    });

    test('rejects malformed or hostless endpoint values', () {
      for (final value in ['', 'not a URL', '/api', 'https:///missing-host']) {
        expect(
          () => parseMetraApiBaseUri(value),
          throwsA(isA<MetraApiException>()),
        );
      }
    });
  });

  group('buildMetraApiUri', () {
    final base = parseMetraApiBaseUri('https://api.example.test/metra/');

    test('keeps the configured base path and encodes query parameters', () {
      final uri = buildMetraApiUri(
        base,
        '/api/v1/stations',
        {'page': '2', 'station_name': 'محطة دمشق'},
      );

      expect(uri.toString(), contains('/metra/api/v1/stations?'));
      expect(uri.queryParameters['page'], '2');
      expect(uri.queryParameters['station_name'], 'محطة دمشق');
      expect(uri.host, 'api.example.test');
    });

    test('rejects absolute or authority-bearing request paths', () {
      for (final path in [
        'https://attacker.example/steal',
        '//attacker.example/steal',
        'api/v1/stations',
      ]) {
        expect(
          () => buildMetraApiUri(base, path, const {}),
          throwsA(isA<MetraApiException>()),
          reason: 'Non-relative API path must be rejected: $path',
        );
      }
    });

    test('rejects path traversal and inline query or fragment components', () {
      for (final path in [
        '/../admin',
        '/api/../admin',
        '/api/v1/stations?token=secret',
        '/api/v1/stations#fragment',
        '/%2e%2e/admin',
        '/%252e%252e/admin',
        '/api/%2fadmin',
        r'/api\\admin',
        '/api/%5cadmin',
      ]) {
        expect(
          () => buildMetraApiUri(base, path, const {}),
          throwsA(isA<MetraApiException>()),
          reason: 'Invalid API path must be rejected: $path',
        );
      }
    });
  });
}
