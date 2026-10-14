import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/session/auto_lock.dart';
import 'package:pos_app/app/session/pin_gate.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/device/device_info.dart';
import 'package:pos_app/data/remote/api.dart';

import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';

const String emptyCart = 'Tovarni skanerlang yoki qidiring';

Map<String, Object?> loginOk({String role = 'owner'}) => {
  'access': 'jwt',
  'refresh': 'r',
  'user': {
    'id': 'owner-1',
    'phone': '+998901234567',
    'full_name': 'Aziz',
    'role': role,
    'tenant': {'id': 't1', 'name': 'Baraka'},
  },
};

Map<String, Object?> registered(Object? id) => {
  'device': {
    'id': id,
    'number': 2,
    'code': 'D2',
    'name': 'Kassa 1',
    'platform': 'windows',
    'app_version': '0.1.0',
    'store': 'store-1',
    'is_blocked': false,
    'last_sync_at': null,
    'last_seen_at': null,
    'created_at': '2026-10-14T09:00:00Z',
  },
  'token': 'dev_token',
};

Map<String, Object?> pullPage() => {
  'changes': [
    {
      'entity': 'user',
      'op': 'upsert',
      'id': 'cashier-1',
      'data': {
        'id': 'cashier-1',
        'phone': null,
        'full_name': 'Aziza',
        'role': 'cashier',
        'is_active': true,
        'pin_hash': 'hash-1234',
      },
    },
    {
      'entity': 'user',
      'op': 'upsert',
      'id': 'manager-1',
      'data': {
        'id': 'manager-1',
        'phone': '+998900000000',
        'full_name': 'Bobur',
        'role': 'manager',
        'is_active': true,
        'pin_hash': null,
      },
    },
  ],
  'next_cursor': '5:1',
  'has_more': false,
  'subscription': {
    'status': 'active',
    'paid_until': null,
    'days_left': null,
    'offline_days': 7,
  },
  'server_time': '2026-10-14T10:00:00Z',
};

/// Testda PIN tekshiruvi tez: to'g'ri PIN — `1234`.
Future<bool> fakeVerify(String pin, String hash) async => pin == '1234';

Future<void> typePin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.text(d).last);
  }
  await tester.tap(find.bySemanticsLabel('Kirish'));
  await tester.pumpAndSettle();
}

Future<void> seedStaff(AppDatabase db) async {
  await db
      .into(db.staffUsers)
      .insert(
        StaffUsersCompanion.insert(
          id: 'cashier-1',
          fullName: 'Aziza',
          role: 'cashier',
          pinHash: const Value('hash-1234'),
        ),
      );
}

void main() {
  group('first launch: connect the device', () {
    late FakeServer server;
    late MemoryDeviceTokenStore tokens;

    setUp(() {
      server = FakeServer();
      tokens = MemoryDeviceTokenStore();
    });

    Future<AppDatabase> open(WidgetTester tester) async {
      final db = openTestDatabase();
      addTearDown(db.close);
      await pumpPosApp(
        tester,
        db: db,
        tokens: tokens,
        session: const Session(stage: SessionStage.setup),
        overrides: [
          dioFactoryProvider.overrideWithValue(server.dio),
          pinGateProvider.overrideWith(
            (ref) => PinGate(db, verify: fakeVerify),
          ),
        ],
      );
      return db;
    }

    testWidgets('phone + password → device name → sync → PIN screen', (
      tester,
    ) async {
      server
        ..on('POST /api/v1/auth/login/', (_) => (200, loginOk()))
        ..on(
          'POST /api/v1/devices/register/',
          (r) => (201, registered((r.body! as Map)['id'])),
        )
        ..on('GET /api/v1/sync/pull/', (_) => (200, pullPage()));
      final db = await open(tester);

      expect(find.text('Kassani ulash'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), '90 123 45 67');
      await tester.enterText(find.byType(TextField).at(1), 'secret');
      await tester.tap(find.text('Davom etish'));
      await tester.pumpAndSettle();

      expect(find.text('Bu kassaga nom bering'), findsOneWidget);
      expect(find.text('Kassa 1'), findsOneWidget);
      await tester.tap(find.text('Ulash'));
      await tester.pumpAndSettle();

      // Sinxrondan keyin — xodim tanlash.
      expect(find.text('Kim ishlaydi?'), findsOneWidget);
      expect(find.text('Aziza'), findsOneWidget);
      expect(find.text("PIN o'rnatilmagan"), findsOneWidget);
      expect(tokens.token, 'dev_token');
      expect((await DeviceInfo.load(db))!.number, 2);
      expect(await db.readSetting('initial_sync_done'), '1');
      expect(
        server.requests.last.authorization,
        'Device dev_token',
      );
    });

    testWidgets('empty fields are highlighted', (tester) async {
      await open(tester);
      await tester.tap(find.text('Davom etish'));
      await tester.pumpAndSettle();
      expect(find.text("To'ldiring"), findsNWidgets(2));
      expect(server.requests, isEmpty);
    });

    testWidgets('wrong password: message and back to credentials', (
      tester,
    ) async {
      server.on(
        'POST /api/v1/auth/login/',
        (_) => (401, apiError('invalid_credentials')),
      );
      await open(tester);
      await tester.enterText(find.byType(TextField).at(0), '901234567');
      await tester.enterText(find.byType(TextField).at(1), 'bad');
      await tester.tap(find.text('Davom etish'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ulash'));
      await tester.pumpAndSettle();
      expect(find.text("Telefon raqami yoki parol noto'g'ri"), findsOneWidget);
      expect(find.text('Kassani ulash'), findsOneWidget);
    });

    testWidgets('sync failure offers retry', (tester) async {
      var pulls = 0;
      server
        ..on('POST /api/v1/auth/login/', (_) => (200, loginOk()))
        ..on(
          'POST /api/v1/devices/register/',
          (r) => (201, registered((r.body! as Map)['id'])),
        )
        ..on('GET /api/v1/sync/pull/', (_) {
          pulls++;
          return pulls == 1 ? null : (200, pullPage());
        });
      await open(tester);
      await tester.enterText(find.byType(TextField).at(0), '901234567');
      await tester.enterText(find.byType(TextField).at(1), 'secret');
      await tester.tap(find.text('Davom etish'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ulash'));
      await tester.pumpAndSettle();

      expect(
        find.text("Ma'lumotlarni yuklab bo'lmadi. Internetni tekshiring."),
        findsOneWidget,
      );
      await tester.tap(find.text('Qayta urinish'));
      await tester.pumpAndSettle();
      expect(find.text('Kim ishlaydi?'), findsOneWidget);
    });

    testWidgets('restart during the first sync resumes the sync', (
      tester,
    ) async {
      server.on('GET /api/v1/sync/pull/', (_) => (200, pullPage()));
      tokens.token = 'dev_token';
      final db = openTestDatabase();
      addTearDown(db.close);
      await testDevice.save(db);
      await pumpPosApp(
        tester,
        db: db,
        tokens: tokens,
        session: const Session(
          stage: SessionStage.initialSync,
          device: testDevice,
        ),
        overrides: [
          dioFactoryProvider.overrideWithValue(server.dio),
        ],
      );
      expect(find.text('Kim ishlaydi?'), findsOneWidget);
      expect(server.requests.single.path, '/api/v1/sync/pull/');
    });
  });

  group('daily login with PIN (offline)', () {
    Future<AppDatabase> openLocked(WidgetTester tester) async {
      final db = openTestDatabase();
      addTearDown(db.close);
      await seedStaff(db);
      await pumpPosApp(
        tester,
        db: db,
        session: const Session(stage: SessionStage.locked, device: testDevice),
        overrides: [
          pinGateProvider.overrideWith(
            (ref) => PinGate(db, verify: fakeVerify),
          ),
        ],
      );
      return db;
    }

    testWidgets('pick cashier, correct PIN opens the POS screen', (
      tester,
    ) async {
      await openLocked(tester);
      expect(find.text('Kim ishlaydi?'), findsOneWidget);
      await tester.tap(find.text('Aziza'));
      await tester.pumpAndSettle();
      expect(find.text('PIN kodni kiriting'), findsOneWidget);
      await typePin(tester, '1234');
      expect(find.text(emptyCart), findsOneWidget);
      // Yon panelda kirgan xodim.
      expect(find.text('Aziza'), findsOneWidget);
    });

    testWidgets('physical keyboard: digits + Enter, Esc goes back', (
      tester,
    ) async {
      await openLocked(tester);
      await tester.tap(find.text('Aziza'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Kim ishlaydi?'), findsOneWidget);

      await tester.tap(find.text('Aziza'));
      await tester.pumpAndSettle();
      for (final key in [
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.numpad3,
        LogicalKeyboardKey.digit4,
      ]) {
        await tester.sendKeyEvent(key);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text(emptyCart), findsOneWidget);
    });

    testWidgets('wrong PIN 5 times → 1 minute wait', (tester) async {
      await openLocked(tester);
      await tester.tap(find.text('Aziza'));
      await tester.pumpAndSettle();

      await typePin(tester, '1111');
      expect(
        find.text("PIN noto'g'ri. Yana 4 ta urinish qoldi"),
        findsOneWidget,
      );
      for (var i = 0; i < 4; i++) {
        await typePin(tester, '1111');
      }
      expect(
        find.text("Juda ko'p xato. 60 soniyadan keyin urinib ko'ring"),
        findsOneWidget,
      );
      // Kutish paytida to'g'ri PIN ham qabul qilinmaydi.
      await typePin(tester, '1234');
      expect(find.text(emptyCart), findsNothing);

      await tester.pump(const Duration(seconds: 30));
      expect(
        find.text("Juda ko'p xato. 30 soniyadan keyin urinib ko'ring"),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(find.textContaining("Juda ko'p xato"), findsNothing);
    });

    testWidgets('PIN shorter than 4 digits is not submitted', (tester) async {
      await openLocked(tester);
      await tester.tap(find.text('Aziza'));
      await tester.pumpAndSettle();
      await typePin(tester, '12');
      expect(find.text('PIN kodni kiriting'), findsOneWidget);
      expect(find.textContaining("noto'g'ri"), findsNothing);
    });
  });

  group('locking', () {
    testWidgets('lock button in the side panel', (tester) async {
      final db = openTestDatabase();
      addTearDown(db.close);
      await seedStaff(db);
      await pumpPosApp(tester, db: db);
      await tester.tap(find.byTooltip('Qulflash'));
      await tester.pumpAndSettle();
      expect(find.text('Kim ishlaydi?'), findsOneWidget);
    });

    testWidgets('auto-lock after inactivity, activity postpones it', (
      tester,
    ) async {
      final db = openTestDatabase();
      addTearDown(db.close);
      await seedStaff(db);
      await pumpPosApp(
        tester,
        db: db,
        overrides: [initialAutoLockMinutesProvider.overrideWithValue(2)],
      );
      await tester.pump(const Duration(seconds: 90));
      // Faollik — taymer qaytadan.
      await tester.tapAt(const Offset(800, 400));
      await tester.pump(const Duration(seconds: 90));
      expect(find.text(emptyCart), findsOneWidget);
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(find.text('Kim ishlaydi?'), findsOneWidget);
    });

    testWidgets('auto-lock setting is saved', (tester) async {
      final db = openTestDatabase();
      addTearDown(db.close);
      await pumpPosApp(tester, db: db);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text("O'chiq"));
      await tester.tap(find.text("O'chiq"));
      await tester.pumpAndSettle();
      expect(await loadAutoLockMinutes(db), 0);
    });
  });

  group('loadSession', () {
    late AppDatabase db;

    setUp(() => db = openTestDatabase());
    tearDown(() => db.close());

    test('no token → setup', () async {
      await testDevice.save(db);
      final s = await loadSession(db, MemoryDeviceTokenStore());
      expect(s.stage, SessionStage.setup);
    });

    test('token and device, first sync unfinished → initialSync', () async {
      await testDevice.save(db);
      final s = await loadSession(db, MemoryDeviceTokenStore('t'));
      expect(s.stage, SessionStage.initialSync);
      expect(s.device!.number, 3);
    });

    test('everything ready → locked (PIN)', () async {
      await testDevice.save(db);
      await db.writeSetting('initial_sync_done', '1');
      final s = await loadSession(db, MemoryDeviceTokenStore('t'));
      expect(s.stage, SessionStage.locked);
    });
  });

  group('PinGate', () {
    late AppDatabase db;
    late DateTime now;
    late PinGate gate;
    const user = testCashier;

    setUp(() {
      db = openTestDatabase();
      now = DateTime.utc(2026, 10, 14, 9);
      gate = PinGate(db, now: () => now, verify: fakeVerify);
    });
    tearDown(() => db.close());

    test('counts failures and resets on success', () async {
      expect(await gate.check(user, '0000'), isA<PinRejected>());
      expect(
        (await gate.check(user, '0000') as PinRejected).attemptsLeft,
        3,
      );
      expect(await gate.check(user, '1234'), isA<PinAccepted>());
      expect(
        (await gate.check(user, '0000') as PinRejected).attemptsLeft,
        4,
      );
    });

    test('lockout survives restart and expires after a minute', () async {
      for (var i = 0; i < 4; i++) {
        await gate.check(user, '0000');
      }
      expect(await gate.check(user, '0000'), isA<PinLockedOut>());

      // "Qayta ochilgan" ilova — yangi PinGate, o'sha baza.
      final restarted = PinGate(db, now: () => now, verify: fakeVerify);
      final locked = await restarted.check(user, '1234');
      expect(locked, isA<PinLockedOut>());
      expect((locked as PinLockedOut).remaining, const Duration(minutes: 1));

      now = now.add(const Duration(seconds: 61));
      expect(await restarted.lockedFor(), isNull);
      expect(await restarted.check(user, '1234'), isA<PinAccepted>());
    });

    test('user without PIN', () async {
      const noPin = StaffUser(
        id: 'x',
        fullName: 'X',
        role: 'manager',
        isActive: true,
      );
      expect(await gate.check(noPin, '1234'), isA<PinNotSet>());
    });
  });
}
