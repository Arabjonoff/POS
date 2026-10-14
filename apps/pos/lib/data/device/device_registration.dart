import 'package:flutter/foundation.dart';
import 'package:pos_api_client/pos_api_client.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/device/device_info.dart';
import 'package:pos_app/data/ids.dart';
import 'package:pos_app/data/remote/api.dart';

/// Kassani ulashdagi xato (ekranda tarjima qilingan matn bilan).
enum SetupError {
  /// Telefon yoki parol noto'g'ri.
  invalidCredentials,

  /// Faqat do'kon egasi kassani ulay oladi.
  notOwner,

  /// Tarifdagi qurilmalar soni tugagan.
  deviceLimit,

  /// Obuna yo'q.
  noSubscription,

  /// Qurilma bloklangan.
  deviceBlocked,

  /// Internet yoki server bilan aloqa yo'q.
  network,

  /// Boshqa xato (server).
  unknown,
}

class SetupException implements Exception {
  const SetupException(this.error);

  factory SetupException.fromApi(Object error) {
    final failure = ApiFailure.from(error);
    return SetupException(switch ((failure.kind, failure.code)) {
      (ApiFailureKind.network, _) => SetupError.network,
      (ApiFailureKind.unauthorized, _) => SetupError.invalidCredentials,
      (_, 'device_blocked') => SetupError.deviceBlocked,
      (_, 'device_limit_reached') => SetupError.deviceLimit,
      (_, 'no_subscription') => SetupError.noSubscription,
      (ApiFailureKind.forbidden, _) => SetupError.notOwner,
      _ => SetupError.unknown,
    });
  }

  final SetupError error;

  @override
  String toString() => 'SetupException($error)';
}

/// Birinchi ishga tushishda: ega telefon + parol → qurilma ro'yxatdan
/// o'tadi → qurilma tokeni xavfsiz joyga, qurilma ma'lumoti bazaga.
class DeviceRegistration {
  DeviceRegistration({
    required AppDatabase db,
    required DeviceTokenStore tokens,
    required DioFactory dio,
    IdGenerator? newId,
    PlatformEnum? platform,
    String appVersion = ApiConfig.appVersion,
  }) : _db = db,
       _tokens = tokens,
       _dio = dio,
       _newId = newId ?? _defaultId,
       _platform = platform ?? currentPlatform(),
       _appVersion = appVersion;

  static String _defaultId() => newId();

  final AppDatabase _db;
  final DeviceTokenStore _tokens;
  final DioFactory _dio;
  final IdGenerator _newId;
  final PlatformEnum _platform;
  final String _appVersion;

  static PlatformEnum currentPlatform() => switch (defaultTargetPlatform) {
    TargetPlatform.android => PlatformEnum.android,
    TargetPlatform.iOS => PlatformEnum.ios,
    _ => PlatformEnum.windows,
  };

  Future<DeviceInfo> register({
    required String phone,
    required String password,
    required String deviceName,
  }) async {
    final LoginResponse login;
    try {
      login = await PosApi(_dio(null)).auth.authLoginCreate(
        body: LoginRequest(phone: phone, password: password),
      );
    } on Object catch (e) {
      throw SetupException.fromApi(e);
    }
    if (login.user.role != RoleEnum.owner) {
      throw const SetupException(SetupError.notOwner);
    }

    // Javob kelmay qolsa — qayta urinishda shu ID (yangi qurilma emas).
    var deviceId = await _db.readSetting(SettingKeys.pendingDeviceId);
    if (deviceId == null) {
      deviceId = _newId();
      await _db.writeSetting(SettingKeys.pendingDeviceId, deviceId);
    }

    final DeviceRegisterResponse response;
    try {
      response = await PosApi(_dio('Bearer ${login.access}')).devices
          .devicesRegisterCreate(
            body: DeviceRegisterRequest(
              id: deviceId,
              name: deviceName.trim(),
              platform: _platform,
              appVersion: _appVersion,
            ),
          );
    } on Object catch (e) {
      throw SetupException.fromApi(e);
    }

    final device = response.device;
    final info = DeviceInfo(
      id: device.id,
      number: device.number,
      name: device.name,
      storeId: device.store,
    );
    await _tokens.write(response.token);
    await info.save(_db);
    return info;
  }
}
