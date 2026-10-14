import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pos_app/data/remote/api.dart';

/// Yozib olingan so'rov.
class RecordedRequest {
  RecordedRequest(this.method, this.path, this.query, this.headers, this.body);

  final String method;
  final String path;
  final Map<String, dynamic> query;
  final Map<String, dynamic> headers;
  final Object? body;

  String? get authorization => headers['Authorization'] as String?;
}

/// Javob: status + JSON. `null` — tarmoq xatosi (javob yo'q).
typedef FakeHandler = (int, Object?)? Function(RecordedRequest request);

/// Testlar uchun soxta server: `"POST /api/v1/auth/login/"` → handler.
class FakeServer implements HttpClientAdapter {
  final Map<String, FakeHandler> routes = {};
  final List<RecordedRequest> requests = [];

  void on(String route, FakeHandler handler) => routes[route] = handler;

  /// Dio fabrikasi — ilova kodiga beriladi.
  DioFactory get dio =>
      (authorization) =>
          createDio(authorization, baseUrl: 'http://test')
            ..httpClientAdapter = this;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? body;
    if (requestStream != null) {
      final bytes = await requestStream.fold<List<int>>(
        [],
        (all, chunk) => all..addAll(chunk),
      );
      if (bytes.isNotEmpty) body = jsonDecode(utf8.decode(bytes));
    } else if (options.data != null) {
      body = options.data is String
          ? jsonDecode(options.data as String)
          : options.data;
    }
    final request = RecordedRequest(
      options.method,
      options.uri.path,
      options.uri.queryParameters,
      options.headers,
      body,
    );
    requests.add(request);
    final handler = routes['${options.method} ${options.uri.path}'];
    final result = handler == null
        ? (
            404,
            {
              'error': {'code': 'not_found'},
            },
          )
        : handler(request);
    if (result == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    final (status, json) = result;
    return ResponseBody.fromString(
      jsonEncode(json),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> apiError(String code) => {
  'error': {'code': code, 'message': code, 'details': <String, Object?>{}},
};
