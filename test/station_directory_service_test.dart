import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:metra_weather_intelligence/data/metra_api_client.dart';
import 'package:metra_weather_intelligence/data/station_directory_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  SupabaseClient createAuthClient() =>
      SupabaseClient('https://auth.example.test', 'public-test-key');

  Map<String, dynamic> station(String id) => {
        'id': id,
        'local_station_code': 'ST-${id.substring(0, 3)}',
        'name_ar': 'محطة اختبار',
        'name_en': 'Test station',
        'station_type': 'automatic',
        'approval_status': 'approved',
        'operational_status': 'active',
        'latitude': 33.5,
        'longitude': 36.2,
      };

  test('fetchStations authenticates and follows all API pages', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      expect(request.headers['authorization'], 'Bearer test-access-token');
      expect(request.headers['accept'], 'application/json');
      final page = request.url.queryParameters['page'];
      expect(request.url.path, '/api/v1/stations');
      expect(request.url.queryParameters['page_size'], '200');
      if (page == '1') {
        return http.Response(jsonEncode({
          'stations': [station('one001')],
          'total': 2,
          'page': 1,
          'page_size': 200,
        }), 200);
      }
      return http.Response(jsonEncode({
        'stations': [station('two002')],
        'total': 2,
        'page': 2,
        'page_size': 200,
      }), 200);
    });
    final api = MetraApiClient(
      createAuthClient(),
      baseUrl: 'https://api.example.test',
      httpClient: client,
      accessTokenProvider: () => 'test-access-token',
    );
    final service = StationDirectoryService(createAuthClient(), apiClient: api);

    final result = await service.fetchStations();

    expect(result.map((item) => item.id), ['one001', 'two002']);
    expect(requests, hasLength(2));
    expect(requests.map((r) => r.url.queryParameters['page']), ['1', '2']);
    client.close();
  });

  test('fetchStations returns an immutable empty catalogue', () async {
    final client = MockClient((_) async => http.Response(
          jsonEncode({'stations': [], 'total': 0, 'page': 1, 'page_size': 200}),
          200,
        ));
    final service = StationDirectoryService(
      createAuthClient(),
      apiClient: MetraApiClient(
        createAuthClient(),
        baseUrl: 'https://api.example.test',
        httpClient: client,
        accessTokenProvider: () => 'token',
      ),
    );

    final result = await service.fetchStations();

    expect(result, isEmpty);
    expect(() => (result as List).add('not-a-station'), throwsUnsupportedError);
    client.close();
  });

  test('fetchAccessContext reads only explicit role and permission codes', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/me');
      return http.Response(jsonEncode({
        'memberships': [
          {
            'roles': [
              {'roleCode': 'station_observer'},
              {'roleCode': ' station_manager '},
              {'roleCode': ''},
            ],
          },
        ],
        'permissions': [
          {'permissionCode': 'observations.create'},
          {'permissionCode': ' stations.read '},
          {'permissionCode': ''},
        ],
      }), 200);
    });
    final service = StationDirectoryService(
      createAuthClient(),
      apiClient: MetraApiClient(
        createAuthClient(),
        baseUrl: 'https://api.example.test',
        httpClient: client,
        accessTokenProvider: () => 'token',
      ),
    );

    final access = await service.fetchAccessContext();

    expect(access.roleCodes, ['station_manager', 'station_observer']);
    expect(access.permissionCodes, ['observations.create', 'stations.read']);
    client.close();
  });

  test('maps forbidden API responses to a permission failure', () async {
    final client = MockClient((_) async => http.Response(
          jsonEncode({'title': 'Forbidden'}),
          403,
        ));
    final service = StationDirectoryService(
      createAuthClient(),
      apiClient: MetraApiClient(
        createAuthClient(),
        baseUrl: 'https://api.example.test',
        httpClient: client,
        accessTokenProvider: () => 'token',
      ),
    );

    await expectLater(
      service.fetchStations(),
      throwsA(isA<MetraApiException>().having((e) => e.statusCode, 'statusCode', 403)),
    );
    client.close();
  });

  test('does not issue API requests without an access token', () async {
    var requestCount = 0;
    final client = MockClient((_) async {
      requestCount++;
      return http.Response('{}', 200);
    });
    final service = StationDirectoryService(
      createAuthClient(),
      apiClient: MetraApiClient(
        createAuthClient(),
        baseUrl: 'https://api.example.test',
        httpClient: client,
        accessTokenProvider: () => null,
      ),
    );

    await expectLater(
      service.fetchStations(),
      throwsA(isA<MetraApiException>().having((e) => e.statusCode, 'statusCode', 401)),
    );
    expect(requestCount, 0);
    client.close();
  });
  test('parseStationRows rejects invalid collection and malformed rows', () {
    expect(() => parseStationRows(null), throwsA(isA<StationDirectoryException>()));
    expect(() => parseStationRows({'id': 'station-1'}), throwsA(isA<StationDirectoryException>()));
    expect(
      () => parseStationRows([station('one001'), 'corrupt-row']),
      throwsA(isA<StationDirectoryException>()),
    );
    expect(
      () => parseStationRows([{'id': '  '}]),
      throwsA(isA<StationDirectoryException>()),
    );
  });

  test('parseStationRows returns an immutable station list', () {
    final parsed = parseStationRows([station('one001')]);
    expect(parsed, hasLength(1));
    expect(() => (parsed as List).add('invalid'), throwsUnsupportedError);
  });

}
