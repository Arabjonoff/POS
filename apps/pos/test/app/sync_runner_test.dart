import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/remote/api.dart';
import 'package:pos_app/data/sync/outbox.dart';

import '../helpers/fake_sync_server.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';

void main() {
  late FakeSyncServer server;

  setUp(() => server = FakeSyncServer());

  Future<AppDatabase> open(WidgetTester tester, {Session? session}) async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await pumpPosApp(
      tester,
      db: db,
      session: session ?? unlockedSession,
      tokens: MemoryDeviceTokenStore('dev_token'),
      syncEnabled: true,
      overrides: [dioFactoryProvider.overrideWithValue(server.http.dio)],
    );
    return db;
  }

  Future<void> addEvent(AppDatabase db, String id) => db.enqueueEvent(
    id: id,
    type: OutboxEventType.cashMoved,
    payload: const {},
    createdAt: DateTime.utc(2026, 10, 14, 10),
  );

  testWidgets('first tick pushes and pulls; status shows online', (
    tester,
  ) async {
    await open(tester);
    expect(server.pulls, 1);
    expect(find.text('Internet bor'), findsOneWidget);
    expect(find.text('Hammasi yuborilgan'), findsOneWidget);
  });

  testWidgets('a new outbox event is pushed within a second', (tester) async {
    final db = await open(tester);
    await addEvent(db, 'e1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();
    expect(server.applied.keys, ['e1']);
    expect(find.text('Hammasi yuborilgan'), findsOneWidget);
  });

  testWidgets('every 10 s push, pull at most every 60 s', (tester) async {
    await open(tester);
    expect(server.pulls, 1);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 10));
    }
    await tester.pumpAndSettle();
    expect(server.pulls, 1);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(server.pulls, 2);
  });

  testWidgets('offline: records wait, status says so', (tester) async {
    server.offline = true;
    final db = await open(tester);
    await addEvent(db, 'e1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();
    expect(
      find.text("Internet yo'q — oflayn rejimda ishlayapti"),
      findsOneWidget,
    );
    expect(find.text('1 ta yozuv navbatda'), findsOneWidget);
    expect(server.applied, isEmpty);

    server.offline = false;
    // Kutish (5 s) o'tgach, navbatdagi 10 s tsiklda yuboriladi.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(server.applied.keys, ['e1']);
    expect(find.text('Internet bor'), findsOneWidget);
  });

  testWidgets('sync also runs on the PIN screen', (tester) async {
    await open(
      tester,
      session: const Session(stage: SessionStage.locked, device: testDevice),
    );
    expect(server.pulls, 1);
  });

  testWidgets('no sync before the device is connected', (tester) async {
    await open(tester, session: const Session(stage: SessionStage.setup));
    await tester.pump(const Duration(seconds: 30));
    expect(server.http.requests, isEmpty);
  });
}
