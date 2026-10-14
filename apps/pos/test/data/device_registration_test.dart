import 'package:flutter_test/flutter_test.dart';
import 'package:pos_api_client/pos_api_client.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/device/device_info.dart';
import 'package:pos_app/data/device/device_registration.dart';
import 'package:pos_app/data/remote/api.dart';

import '../helpers/fake_server.dart';
import '../helpers/sqlite.dart';

Map<String, Object?> loginOk({String role = 'owner'}) => {
  'access': 'jwt-access',
  'refresh': 'jwt-refresh',
  'user': {
    'id': 'u1',
    'phone': '+998901234567',
    'full_name': 'Aziz',
    'role': role,
    'tenant': {'id': 't1', 'name': "Baraka do'koni"},
  },
};

Map<String, Object?> registered(String id) => {
  'device': {
    'id': id,
    'number': 3,
    'code': 'D3',
    'name': 'Kassa 1',
    'platform': 'windows',
    'app_version': '0.1.0',
    'store': 'store-1',
    'is_blocked': false,
    'last_sync_at': null,
    'last_seen_at': null,
    'created_at': '2026-10-14T09:00:00Z',
  },
  'token': 'dev_secret',
};

void main() {
  late AppDatabase db;
  late FakeServer server;
  late MemoryDeviceTokenStore tokens;
  late DeviceRegistration registration;
  var ids = 0;

  setUp(() {
    db = openTestDatabase();
    server = FakeServer();
    tokens = MemoryDeviceTokenStore();
    ids = 0;
    registration = DeviceRegistration(
      db: db,
      tokens: tokens,
      dio: server.dio,
      newId: () => 'device-${++ids}',
      platform: PlatformEnum.windows,
    );
  });
  tearDown(() => db.close());

  Future<DeviceInfo> register() => registration.register(
    phone: '90 123 45 67',
    password: 'secret',
    deviceName: ' Kassa 1 ',
  );

  test('owner login registers the device and stores the token', () async {
    server
      ..on('POST /api/v1/auth/login/', (_) => (200, loginOk()))
      ..on(
        'POST /api/v1/devices/register/',
        (r) => (201, registered((r.body! as Map)['id'] as String)),
      );

    final info = await register();
    expect(info.number, 3);
    expect(info.storeId, 'store-1');
    expect(tokens.token, 'dev_secret');
    expect((await DeviceInfo.load(db))!.id, 'device-1');

    final login = server.requests.first;
    expect(login.body, {'phone': '90 123 45 67', 'password': 'secret'});
    expect(login.authorization, isNull);

    final reg = server.requests.last;
    expect(reg.authorization, 'Bearer jwt-access');
    expect(reg.body, {
      'id': 'device-1',
      'name': 'Kassa 1',
      'platform': 'windows',
      'app_version': '0.1.0',
    });
    expect(await db.readSetting(SettingKeys.pendingDeviceId), isNull);
  });

  test('retry after a lost response reuses the same device id', () async {
    var attempt = 0;
    server
      ..on('POST /api/v1/auth/login/', (_) => (200, loginOk()))
      ..on('POST /api/v1/devices/register/', (r) {
        attempt++;
        // 1-urinish: server yaratdi, lekin javob yetib kelmadi.
        if (attempt == 1) return null;
        return (200, registered((r.body! as Map)['id'] as String));
      });

    await expectLater(
      register(),
      throwsA(
        isA<SetupException>().having(
          (e) => e.error,
          'error',
          SetupError.network,
        ),
      ),
    );
    final info = await register();
    final ids = server.requests
        .where((r) => r.path == '/api/v1/devices/register/')
        .map((r) => (r.body! as Map)['id']);
    expect(ids, ['device-1', 'device-1']);
    expect(info.id, 'device-1');
  });

  group('errors are mapped for the screen', () {
    Future<void> expectError(SetupError error) => expectLater(
      register(),
      throwsA(isA<SetupException>().having((e) => e.error, 'error', error)),
    );

    test('wrong phone or password', () async {
      server.on(
        'POST /api/v1/auth/login/',
        (_) => (401, apiError('invalid_credentials')),
      );
      await expectError(SetupError.invalidCredentials);
      expect(tokens.token, isNull);
    });

    test('manager cannot connect a device', () async {
      server.on(
        'POST /api/v1/auth/login/',
        (_) => (200, loginOk(role: 'manager')),
      );
      await expectError(SetupError.notOwner);
      expect(server.requests, hasLength(1));
    });

    test('device limit, subscription, blocked', () async {
      server.on('POST /api/v1/auth/login/', (_) => (200, loginOk()));
      for (final (status, code, error) in [
        (409, 'device_limit_reached', SetupError.deviceLimit),
        (409, 'no_subscription', SetupError.noSubscription),
        (403, 'device_blocked', SetupError.deviceBlocked),
        (500, 'boom', SetupError.unknown),
      ]) {
        server.on(
          'POST /api/v1/devices/register/',
          (_) => (status, apiError(code)),
        );
        await expectError(error);
      }
      expect(tokens.token, isNull);
      expect(await DeviceInfo.load(db), isNull);
    });

    test('offline', () async {
      server.on('POST /api/v1/auth/login/', (_) => null);
      await expectError(SetupError.network);
    });
  });
}
