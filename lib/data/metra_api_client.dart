import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class MetraApiClient {
  MetraApiClient(
    this._authClient, {
    String? baseUrl,
    http.Client? httpClient,
  })  : _baseUrl = (baseUrl ?? const String.fromEnvironment('METRA_API_URL')).trim(),
        _httpClient = httpClient ?? _sharedClient;

  static final http.Client _sharedClient = http.Client();

  final SupabaseClient _authClient;
  final String _baseUrl;
  final http.Client _httpClient;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String> query = const {},
  }) => _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
  }) => _send('POST', path, body: body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String> query = const {},
    Map<String, dynamic>? body,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const MetraApiException(
        statusCode: 0,
        message: 'عنوان خدمة METRA API غير مهيأ.',
      );
    }

    final token = _authClient.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw const MetraApiException(
        statusCode: 401,
        message: 'انتهت جلسة الدخول. سجّل الدخول مجدداً.',
      );
    }

    final base = _baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base$path').replace(queryParameters: query.isEmpty ? null : query);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = method == 'GET'
          ? await _httpClient.get(uri, headers: headers).timeout(const Duration(seconds: 15))
          : await _httpClient
              .post(
                uri,
                headers: {...headers, 'Content-Type': 'application/json'},
                body: jsonEncode(body ?? const <String, dynamic>{}),
              )
              .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw MetraApiException(
          statusCode: response.statusCode,
          message: _messageForStatus(response.statusCode),
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const MetraApiException(
        statusCode: 502,
        message: 'استجابة خدمة METRA غير صالحة.',
      );
    } on MetraApiException {
      rethrow;
    } on Object {
      throw const MetraApiException(
        statusCode: 503,
        message: 'تعذر الاتصال بخدمة METRA. تحقق من الاتصال ثم أعد المحاولة.',
      );
    }
  }

  String _messageForStatus(int statusCode) => switch (statusCode) {
        401 => 'يلزم تسجيل الدخول مجدداً.',
        403 => 'الحساب غير معتمد أو لا يملك الصلاحية المطلوبة.',
        404 => 'الخدمة المطلوبة غير متاحة.',
        409 => 'تعارضت العملية مع تحديث آخر. حدّث البيانات وحاول مجدداً.',
        422 => 'البيانات المرسلة غير صالحة.',
        429 => 'تم تجاوز حد الطلبات. انتظر قليلاً ثم أعد المحاولة.',
        >= 500 => 'خدمة METRA غير متاحة مؤقتاً.',
        _ => 'تعذر تنفيذ الطلب إلى خدمة METRA.',
      };
}

class MetraApiException implements Exception {
  const MetraApiException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}
