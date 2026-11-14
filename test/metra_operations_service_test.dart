import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:metra_weather_intelligence/data/metra_api_client.dart';
import 'package:metra_weather_intelligence/data/metra_operations_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  SupabaseClient authClient() =>
      SupabaseClient('https://auth.example.test', 'public-test-key');

  MetraOperationsService service(
    MockClient transport, {
    String? token = 'test-token',
  }) =>
      MetraOperationsService(
        MetraApiClient(
          authClient(),
          baseUrl: 'https://api.example.test',
          httpClient: transport,
          accessTokenProvider: () => token,
        ),
      );

  test('fetchAllPages reads every page and returns immutable records', () async {
    final pages = <String>[];
    final transport = MockClient((request) async {
      pages.add(request.url.queryParameters['page']!);
      expect(request.url.path, '/api/v1/observations/mine');
      expect(request.headers['authorization'], 'Bearer test-token');
      if (request.url.queryParameters['page'] == '1') {
        return http.Response(jsonEncode({
          'items': [{'id': 'first'}],
          'total': 2,
        }), 200);
      }
      return http.Response(jsonEncode({
        'items': [{'id': 'second'}],
        'total': 2,
      }), 200);
    });

    final items = await service(transport).fetchAllPages(
      '/api/v1/observations/mine',
      pageSize: 1,
    );

    expect(items.map((item) => item['id']), ['first', 'second']);
    expect(pages, ['1', '2']);
    expect(() => (items as List).add({'id': 'third'}), throwsUnsupportedError);
    transport.close();
  });

  test('fetchAllPages rejects malformed collections and rows', () async {
    for (final payload in [
      {'items': 'not-a-list', 'total': 1},
      {'items': [null], 'total': 1},
    ]) {
      final transport = MockClient((_) async => http.Response(jsonEncode(payload), 200));
      await expectLater(
        service(transport).fetchAllPages('/api/v1/observations/mine'),
        throwsA(isA<MetraOperationsException>()),
      );
      transport.close();
    }
  });

  test('fetchAllPages validates page size before making a request', () async {
    var requests = 0;
    final transport = MockClient((_) async {
      requests++;
      return http.Response('{}', 200);
    });
    await expectLater(
      service(transport).fetchAllPages('/api/v1/alerts', pageSize: 201),
      throwsArgumentError,
    );
    expect(requests, 0);
    transport.close();
  });

  test('loads observation reference data through the secured API routes', () async {
    final paths = <String>[];
    final transport = MockClient((request) async {
      paths.add(request.url.path);
      return http.Response(jsonEncode({'items': []}), 200);
    });
    final api = service(transport);

    await api.fetchObservationTypes();
    await api.fetchObservationParameters();

    expect(paths, [
      '/api/v1/reference/observation-types',
      '/api/v1/reference/parameters',
    ]);
    transport.close();
  });

  test('submits observations with the backend contract and idempotency key', () async {
    final transport = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/observations');
      expect(request.headers['authorization'], 'Bearer test-token');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['station_id'], 'station-guid');
      expect(body['idempotency_key'], 'request-123');
      expect(body['submit'], isTrue);
      return http.Response(jsonEncode({
        'id': 'submission-guid',
        'status': 'submitted',
        'replayed': false,
      }), 200);
    });

    final result = await service(transport).submitObservation({
      'station_id': 'station-guid',
      'observation_type': 'hourly',
      'observed_at': '2026-11-15T12:00:00Z',
      'timezone_name': 'Asia/Damascus',
      'idempotency_key': 'request-123',
      'payload': [],
      'submit': true,
    });

    expect(result['status'], 'submitted');
    transport.close();
  });

  test('rejects unsafe identifiers before building decision routes', () async {
    var requests = 0;
    final transport = MockClient((_) async {
      requests++;
      return http.Response('{}', 200);
    });
    final api = service(transport);

    for (final id in ['', '  ', '../other', 'id?x=1', 'id#fragment', r'id\other']) {
      expect(
        () => api.decideObservation(id, {'decision': 'approved', 'reason': 'checked'}),
        throwsArgumentError,
      );
    }
    expect(requests, 0);
    transport.close();
  });

  test('uses station-specific route and preserves decision body', () async {
    final transport = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/stations/station-guid/decisions');
      expect(jsonDecode(request.body), {
        'decision': 'approved',
        'reason': 'coordinates verified',
      });
      return http.Response(jsonEncode({
        'id': 'station-guid',
        'result_status': 'updated',
        'resulting_status': 'approved',
      }), 200);
    });

    final result = await service(transport).decideStation(
      'station-guid',
      {'decision': 'approved', 'reason': 'coordinates verified'},
    );

    expect(result['resulting_status'], 'approved');
    transport.close();
  });

  test('uses registration endpoint and exact request payload', () async {
    final transport = MockClient((request) async {
      expect(request.url.path, '/api/v1/registration');
      expect(jsonDecode(request.body), {
        'station_id': 'station-guid',
        'role_code': 'station_observer',
        'first_name': 'Test',
        'father_name': 'Parent',
        'last_name': 'User',
        'phone': null,
        'terms_version': 'metra-terms-2026-11',
        'idempotency_key': 'registration-123',
      });
      return http.Response(jsonEncode({
        'result_status': 'created',
        'request_id': 'request-guid',
        'request_state': 'pending',
      }), 200);
    });

    final result = await service(transport).submitRegistration({
      'station_id': 'station-guid',
      'role_code': 'station_observer',
      'first_name': 'Test',
      'father_name': 'Parent',
      'last_name': 'User',
      'phone': null,
      'terms_version': 'metra-terms-2026-11',
      'idempotency_key': 'registration-123',
    });

    expect(result['result_status'], 'created');
    transport.close();
  });

  test('fetchAllPages stops safely when a later page is empty despite a stale total', () async {
    final pages = <String>[];
    final transport = MockClient((request) async {
      final page = request.url.queryParameters['page']!;
      pages.add(page);
      if (page == '1') {
        return http.Response(jsonEncode({
          'items': [{'id': 'only-record'}],
          'total': 3,
        }), 200);
      }
      return http.Response(jsonEncode({'items': [], 'total': 3}), 200);
    });

    final items = await service(transport).fetchAllPages(
      '/api/v1/observations/mine',
      pageSize: 1,
    );

    expect(items.map((item) => item['id']), ['only-record']);
    expect(pages, ['1', '2']);
    transport.close();
  });

  test('covers scoped queue and alert list routes with their response keys', () async {
    final paths = <String>[];
    final transport = MockClient((request) async {
      paths.add(request.url.path);
      final isStationQueue = request.url.path == '/api/v1/stations/review-queue' ||
          request.url.path == '/api/v1/observations/stations';
      return http.Response(jsonEncode({
        isStationQueue ? 'stations' : 'items': [],
        'total': 0,
      }), 200);
    });
    final api = service(transport);

    await api.fetchRegistrationApprovals();
    await api.fetchObservationStations();
    await api.fetchOwnObservations();
    await api.fetchObservationReviewQueue();
    await api.fetchStationReviewQueue();
    await api.fetchAlerts();

    expect(paths, [
      '/api/v1/registration/approvals',
      '/api/v1/observations/stations',
      '/api/v1/observations/mine',
      '/api/v1/observations/review-queue',
      '/api/v1/stations/review-queue',
      '/api/v1/alerts',
    ]);
    transport.close();
  });

  test('rejects unsafe registration decision identifiers before transport', () async {
    var requests = 0;
    final transport = MockClient((_) async {
      requests++;
      return http.Response('{}', 200);
    });
    final api = service(transport);

    for (final id in ['', '  ', '../other', 'request?next=admin', 'request#fragment']) {
      expect(
        () => api.decideRegistration(id, {'decision': 'approved', 'reason': 'verified'}),
        throwsArgumentError,
      );
    }
    expect(requests, 0);
    transport.close();
  });

}
