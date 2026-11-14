import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/access_context.dart';
import '../domain/station_record.dart';
import 'metra_api_client.dart';

class StationDirectoryService {
  StationDirectoryService(this._client);
  final SupabaseClient _client;

  MetraApiClient get _api => MetraApiClient(_client);

  Future<List<StationRecord>> fetchStations() async {
    final data = await _api.get(
      '/api/v1/stations',
      query: const {'page': '1', 'page_size': '200'},
    );
    return parseStationRows(data['stations']);
  }

  Future<AccessContext> fetchAccessContext() async {
    final data = await _api.get('/api/v1/me');
    final roleCodes = <String>{};
    final memberships = data['memberships'];
    if (memberships is List) {
      for (final membership in memberships.whereType<Map>()) {
        final roles = membership['roles'];
        if (roles is! List) continue;
        for (final role in roles.whereType<Map>()) {
          final code = role['roleCode']?.toString().trim();
          if (code != null && code.isNotEmpty) roleCodes.add(code);
        }
      }
    }

    final permissionCodes = <String>{};
    final permissions = data['permissions'];
    if (permissions is List) {
      for (final permission in permissions.whereType<Map>()) {
        final code = permission['permissionCode']?.toString().trim();
        if (code != null && code.isNotEmpty) permissionCodes.add(code);
      }
    }

    return AccessContext(
      roleCodes: roleCodes.toList()..sort(),
      permissionCodes: permissionCodes.toList()..sort(),
    );
  }
}

List<StationRecord> parseStationRows(Object? value) {
  if (value is! List) {
    throw const StationDirectoryException('استجابة دليل المحطات غير صالحة.');
  }
  final stations = <StationRecord>[];
  for (var index = 0; index < value.length; index++) {
    final row = value[index];
    if (row is! Map) {
      throw StationDirectoryException('سجل المحطة رقم ${index + 1} غير صالح.');
    }
    final json = Map<String, dynamic>.from(row);
    final id = json['id']?.toString().trim() ?? '';
    if (id.isEmpty) {
      throw StationDirectoryException('سجل المحطة رقم ${index + 1} لا يحتوي على معرّف.');
    }
    stations.add(StationRecord.fromJson(json));
  }
  return List<StationRecord>.unmodifiable(stations);
}

class StationDirectoryException implements Exception {
  const StationDirectoryException(this.message);
  final String message;
  @override
  String toString() => message;
}
