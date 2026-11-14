import 'package:supabase_flutter/supabase_flutter.dart';

import 'metra_api_client.dart';

/// Authenticated application-facing API for METRA operational workflows.
///
/// All reads and writes go through the ASP.NET API. The Flutter client never
/// receives database credentials or writes directly to operational tables.
class MetraOperationsService {
  MetraOperationsService(this._api);

  factory MetraOperationsService.fromSupabase(SupabaseClient client) =>
      MetraOperationsService(MetraApiClient(client));

  final MetraApiClient _api;

  Future<List<Map<String, dynamic>>> fetchAllPages(
    String path, {
    String listKey = 'items',
    int pageSize = 100,
  }) async {
    if (pageSize < 1 || pageSize > 200) {
      throw ArgumentError.value(pageSize, 'pageSize', 'Must be between 1 and 200.');
    }

    var page = 1;
    var total = 0;
    final items = <Map<String, dynamic>>[];
    do {
      final response = await _api.get(
        path,
        query: {'page': '$page', 'page_size': '$pageSize'},
      );
      final rows = response[listKey];
      if (rows is! List) {
        throw const MetraOperationsException('استجابة القائمة من خدمة METRA غير صالحة.');
      }
      for (var index = 0; index < rows.length; index++) {
        final row = rows[index];
        if (row is! Map) {
          throw MetraOperationsException(
            'السجل رقم ${index + 1} في قائمة METRA غير صالح.',
          );
        }
        items.add(Map<String, dynamic>.from(row));
      }

      final rawTotal = response['total'];
      total = rawTotal is num ? rawTotal.toInt() : items.length;
      if (rows.isEmpty || items.length >= total) break;
      page++;
    } while (true);

    return List<Map<String, dynamic>>.unmodifiable(items);
  }

  Future<Map<String, dynamic>> fetchRegistrationStatus() =>
      _api.get('/api/v1/registration/status');

  Future<Map<String, dynamic>> fetchRegistrationCatalog() =>
      _api.get('/api/v1/registration/catalog');

  Future<Map<String, dynamic>> submitRegistration(
    Map<String, dynamic> request,
  ) =>
      _api.post('/api/v1/registration', body: request);

  Future<List<Map<String, dynamic>>> fetchRegistrationApprovals({
    int pageSize = 100,
  }) =>
      fetchAllPages(
        '/api/v1/registration/approvals',
        pageSize: pageSize,
      );

  Future<Map<String, dynamic>> decideRegistration(
    String requestId,
    Map<String, dynamic> request,
  ) =>
      _api.post('/api/v1/registration/${_requireId(requestId)}/decisions', body: request);

  Future<List<Map<String, dynamic>>> fetchObservationStations() =>
      fetchAllPages(
        '/api/v1/observations/stations',
        listKey: 'stations',
        pageSize: 200,
      );

  Future<List<Map<String, dynamic>>> fetchOwnObservations({
    int pageSize = 50,
  }) =>
      fetchAllPages('/api/v1/observations/mine', pageSize: pageSize);

  Future<List<Map<String, dynamic>>> fetchObservationReviewQueue({
    int pageSize = 50,
  }) =>
      fetchAllPages('/api/v1/observations/review-queue', pageSize: pageSize);

  Future<Map<String, dynamic>> fetchObservationTypes() =>
      _api.get('/api/v1/reference/observation-types');

  Future<Map<String, dynamic>> fetchObservationParameters() =>
      _api.get('/api/v1/reference/parameters');

  Future<Map<String, dynamic>> submitObservation(
    Map<String, dynamic> request,
  ) =>
      _api.post('/api/v1/observations', body: request);

  Future<Map<String, dynamic>> decideObservation(
    String submissionId,
    Map<String, dynamic> request,
  ) =>
      _api.post('/api/v1/observations/${_requireId(submissionId)}/decisions', body: request);

  Future<List<Map<String, dynamic>>> fetchStationReviewQueue() =>
      fetchAllPages(
        '/api/v1/stations/review-queue',
        listKey: 'stations',
        pageSize: 200,
      );

  Future<Map<String, dynamic>> decideStation(
    String stationId,
    Map<String, dynamic> request,
  ) =>
      _api.post('/api/v1/stations/${_requireId(stationId)}/decisions', body: request);

  Future<List<Map<String, dynamic>>> fetchAlerts({
    int pageSize = 50,
  }) =>
      fetchAllPages('/api/v1/alerts', pageSize: pageSize);
}

String _requireId(String value) {
  final id = value.trim();
  if (id.isEmpty ||
      id.contains('/') ||
      id.contains('?') ||
      id.contains('#') ||
      id.contains('\\')) {
    throw ArgumentError.value(value, 'id', 'A non-empty path-safe identifier is required.');
  }
  return id;
}

class MetraOperationsException implements Exception {
  const MetraOperationsException(this.message);
  final String message;

  @override
  String toString() => message;
}
