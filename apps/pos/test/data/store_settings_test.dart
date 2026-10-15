import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/store/store_settings.dart';
import 'package:pos_app/data/sync/outbox.dart';
import 'package:pos_app/features/printing/mono_bitmap.dart';
import 'package:pos_app/features/printing/receipt.dart';
import 'package:pos_app/features/printing/receipt_loader.dart';

import '../helpers/sqlite.dart';

void main() {
  late AppDatabase db;
  late StoreSettingsStore store;

  setUp(() async {
    db = openTestDatabase();
    await db
        .into(db.stores)
        .insert(StoresCompanion.insert(id: 'store-1', name: 'Eski nom'));
    store = StoreSettingsStore(db, now: () => DateTime.utc(2026, 10, 15, 9));
  });
  tearDown(() => db.close());

  StoreDraft draft({
    String name = ' Baraka   market ',
    String tin = '123456789',
    String phone = '71 200 00 00',
    GrayImage? logo,
  }) => StoreDraft(
    id: 'store-1',
    name: name,
    legalName: '"Baraka" MChJ',
    tin: tin,
    address: 'Chilonzor 7',
    phone: phone,
    footer: 'Rahmat!\nYana keling',
    logo: logo,
    options: const ReceiptOptions(showCashier: false),
  );

  test('save: local row and store.upserted in one transaction', () async {
    final logo = GrayImage(8, 2, Uint8List(16));
    await store.save(draft(logo: logo), by: 'owner-1');
    final row = await db.select(db.stores).getSingle();
    expect(row.name, 'Baraka market');
    expect((row.tin, row.phone), ('123456789', '+998712000000'));
    expect(decodeStoreLogo(row.receiptLogo)!.width, 8);
    expect(decodeReceiptOptions(row.receiptOptions).showCashier, isFalse);

    final event = await db.select(db.outboxEvents).getSingle();
    expect(event.type, OutboxEventType.storeUpserted);
    final payload = jsonDecode(event.payload) as Map<String, Object?>;
    expect(payload['id'], 'store-1');
    expect(payload['by'], 'owner-1');
    expect(payload['tin'], '123456789');
    expect(payload['receipt_logo'], row.receiptLogo);
    expect((payload['receipt_options']! as Map)['show_cashier'], isFalse);
  });

  test('invalid draft is not saved (name, STIR, phone)', () async {
    expect(StoreSettingsStore.validate(draft(name: '  ')), [
      StoreProblem.nameRequired,
    ]);
    for (final tin in ['12345', '1234567890', '12345678a']) {
      expect(StoreSettingsStore.validate(draft(tin: tin)), [
        StoreProblem.tinFormat,
      ]);
    }
    expect(StoreSettingsStore.validate(draft(tin: '')), isEmpty);
    expect(StoreSettingsStore.validate(draft(tin: '12345678901234')), isEmpty);
    expect(StoreSettingsStore.validate(draft(phone: '12')), [
      StoreProblem.phoneFormat,
    ]);
    await expectLater(
      store.save(draft(tin: '12'), by: 'owner-1'),
      throwsArgumentError,
    );
    expect(await db.select(db.outboxEvents).get(), isEmpty);
    expect((await db.select(db.stores).getSingle()).name, 'Eski nom');
  });
}
