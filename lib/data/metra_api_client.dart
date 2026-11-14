import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class MetraApiClient {
  MetraApiClient(
    SupabaseClient authClient, {
    String? baseUrl,
    http.Client? httpClient,
    String? Function()? accessTokenProvider,
  })  : _baseUrl = (baseUrl ?? const String.fromEnvironment('METRA_API_URL')).trim(),
        _httpClient = httpClient ?? _sharedClient,
        _accessTokenProvider = accessTokenProvider ??
            (() => authClient.auth.currentSession?.accessToken);

  static final http.Client _sharedClient = http.Client();

  final String _baseUrl;
  final String? Function() _accessTokenProvider;
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

    final token = _accessTokenProvider();
    if (token == null || token.isEmpty) {
      throw const MetraApiException(
        statusCode: 401,
        message: 'انتهت جلسة الدخول. سجّل الدخول مجدداً.',
      );
    }

    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final baseUri = parseMetraApiBaseUri(_baseUrl);
      final uri = buildMetraApiUri(baseUri, path, query);
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

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const MetraApiException(
          statusCode: 502,
          message: 'استجابة خدمة METRA غير صالحة.',
        );
      }
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

Uri parseMetraApiBaseUri(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      uri.scheme.toLowerCase() != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw const MetraApiException(
      statusCode: 0,
      message: 'يجب ضبط عنوان خدمة METRA API بعنوان HTTPS صالح وآمن.',
    );
  }

  return uri.replace(path: uri.path.replaceFirst(RegExp(r'/+$'), ''));
}

Uri buildMetraApiUri(
  Uri baseUri,
  String path,
  Map<String, String> query,
) {
  // Validate the original string before Uri.parse: Dart normalizes literal
  // dot segments (for example /../admin) while parsing, hiding traversal.
  final rawSegments = path.split('/');
  final hasUnsafeSegment = rawSegments.any((segment) {
    var decoded = segment;
    try {
      for (var pass = 0; pass < 3; pass++) {
        final next = Uri.decodeComponent(decoded);
        if (next == decoded) break;
        decoded = next;
      }
    } on FormatException {
      return true;
    }
    return decoded == '.' ||
        decoded == '..' ||
        decoded.contains('/') ||
        decoded.contains(String.fromCharCode(92));
  });
  final route = Uri.tryParse(path);
  if (route == null ||
      route.hasScheme ||
      route.hasAuthority ||
      route.hasQuery ||
      route.hasFragment ||
      !path.startsWith('/') ||
      path.startsWith('//') ||
      path.contains(String.fromCharCode(92)) ||
      path.contains('?') ||
      path.contains('#') ||
      hasUnsafeSegment) {
    throw const MetraApiException(
      statusCode: 0,
      message: 'مسار طلب METRA API غير صالح.',
    );
  }

  return baseUri.replace(
    path: '${baseUri.path}${route.path}',
    queryParameters: query.isEmpty ? null : query,
  );
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
