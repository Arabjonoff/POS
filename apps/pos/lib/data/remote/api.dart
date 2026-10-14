import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pos_api_client/pos_api_client.dart';

/// Server manzili va ilova versiyasi (build paytida:
/// `--dart-define=POS_API_URL=https://api.example.uz`).
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'POS_API_URL',
    defaultValue: 'http://127.0.0.1:8100',
  );
  static const String appVersion = String.fromEnvironment(
    'POS_APP_VERSION',
    defaultValue: '0.1.0',
  );
}

/// Qurilma tokeni saqlanadigan joy. Ilovada — `flutter_secure_storage`
/// (Windows: DPAPI, Android: Keystore, iOS: Keychain).
abstract interface class DeviceTokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureDeviceTokenStore implements DeviceTokenStore {
  SecureDeviceTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'pos_device_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Testlar uchun.
class MemoryDeviceTokenStore implements DeviceTokenStore {
  MemoryDeviceTokenStore([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;

  @override
  Future<void> clear() async => token = null;
}

/// `Authorization` sarlavhasi bilan Dio. `null` — sarlavhasiz (login).
typedef DioFactory = Dio Function(String? authorization);

Dio createDio(String? authorization, {String baseUrl = ApiConfig.baseUrl}) =>
    Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        contentType: Headers.jsonContentType,
        headers: {'Authorization': ?authorization},
      ),
    );

/// Server xatosi foydalanuvchiga tushunarli turga keltirilgan.
enum ApiFailureKind {
  /// Internet yo'q, server javob bermadi, vaqt tugadi.
  network,

  /// 401 — login/token noto'g'ri.
  unauthorized,

  /// 403 — ruxsat yo'q yoki qurilma bloklangan.
  forbidden,

  /// 409 va boshqa biznes xatolari (`code` da aniq sabab).
  rejected,

  /// 5xx yoki kutilmagan javob.
  server,
}

class ApiFailure implements Exception {
  const ApiFailure(this.kind, {this.code, this.status});

  /// Dio xatosidan. Server javobi: `{"error": {"code", "message", "details"}}`.
  factory ApiFailure.from(Object error) {
    if (error is ApiFailure) return error;
    if (error is! DioException) return const ApiFailure(ApiFailureKind.server);
    final response = error.response;
    if (response == null) return const ApiFailure(ApiFailureKind.network);
    final status = response.statusCode ?? 0;
    String? code;
    final body = response.data;
    if (body is Map && body['error'] is Map) {
      code = (body['error'] as Map)['code'] as String?;
    }
    final kind = switch (status) {
      401 => ApiFailureKind.unauthorized,
      403 => ApiFailureKind.forbidden,
      >= 500 => ApiFailureKind.server,
      _ => ApiFailureKind.rejected,
    };
    return ApiFailure(kind, code: code, status: status);
  }

  final ApiFailureKind kind;
  final String? code;
  final int? status;

  @override
  String toString() => 'ApiFailure($kind, code: $code, status: $status)';
}

final dioFactoryProvider = Provider<DioFactory>((ref) => createDio);

final deviceTokenStoreProvider = Provider<DeviceTokenStore>(
  (ref) => SecureDeviceTokenStore(),
);

/// Qurilma tokeni bilan API (sinxron, `devices/me`).
PosApi deviceApi(DioFactory dio, String token) => PosApi(dio('Device $token'));
