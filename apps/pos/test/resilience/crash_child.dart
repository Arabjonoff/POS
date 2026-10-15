// Alohida jarayon: savdo tranzaksiyasini yozadi va jarayonni o'ldiradi
// (`exit`, ulanish yopilmaydi). `crash_test.dart` ishga tushiradi:
//   dart run test/resilience/crash_child.dart <db> <commit|crash> <saleId>
// Faqat `package:sqlite3` (Flutter'siz) — haqiqiy jarayon o'limi sinovi.
import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  final [path, mode, saleId] = args;
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('winsqlite3.dll'),
    );
  }
  final db = sqlite3.open(path)
    ..execute('PRAGMA journal_mode = WAL')
    ..execute('PRAGMA synchronous = FULL')
    ..execute('BEGIN IMMEDIATE');
  const at = '2026-10-15T05:00:00.000Z';
  db
    ..execute(
      'INSERT INTO sales (id, shift_id, cashier_id, number, subtotal_tiyin, '
      'discount_tiyin, total_tiyin, status, sold_at) '
      "VALUES (?, 'shift-1', 'u', ?, 500000, 0, 500000, 'completed', ?)",
      [saleId, 'C-$saleId', at],
    )
    ..execute(
      'INSERT INTO sale_items (id, sale_id, position, product_id, '
      'name_snapshot, qty_milli, price_tiyin, cost_tiyin, discount_tiyin, '
      "total_tiyin) VALUES (?, ?, 0, 'bread', 'Non', 1000, 500000, 400000, 0, "
      '500000)',
      ['$saleId-i', saleId],
    )
    ..execute(
      'INSERT INTO stock_movements (id, product_id, qty_milli, type, '
      "ref_type, ref_id, at) VALUES (?, 'bread', -1000, 'sale', 'sale', ?, ?)",
      ['$saleId-m', saleId, at],
    )
    ..execute(
      'INSERT INTO outbox_events (id, type, payload, created_at, status, '
      "attempts) VALUES (?, 'sale.completed', '{}', ?, 'pending', 0)",
      ['$saleId-e', at],
    );
  if (mode == 'commit') db.execute('COMMIT');
  stdout.writeln('written');
  // Jarayon shu yerda o'ladi: `crash` rejimida COMMIT yo'q, ulanish yopilmagan.
  exit(3);
}
