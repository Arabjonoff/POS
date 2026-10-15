import 'package:drift/drift.dart';

// Kassa hujjatlari: qurilmada yaratiladi (UUIDv7), o'zgarmas — tahrir yo'q,
// faqat teskari yozuv (CLAUDE.md, 3-qoida). Istisno: smena yopilishi va
// `Sale.status` (qaytarishda), kirim/inventarizatsiya qoralamasi.
// Bitta hujjat ichida FK bor (qatorlar → hujjat); ma'lumotnomalarga FK yo'q.

/// Bir qurilmada bir vaqtda bitta ochiq smena.
@TableIndex.sql('''
  CREATE UNIQUE INDEX shifts_one_open_per_device ON shifts (device_id)
    WHERE closed_at IS NULL;
''')
class Shifts extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get deviceId => text()();
  TextColumn get openedBy => text()();
  DateTimeColumn get openedAt => dateTime()();
  IntColumn get openingCashTiyin => integer()();
  TextColumn get closedBy => text().nullable()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  IntColumn get countedCashTiyin => integer().nullable()();
  IntColumn get expectedCashTiyin => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(name: 'sales_shift', columns: {#shiftId})
@TableIndex(name: 'sales_sold_at', columns: {#soldAt})
class Sales extends Table {
  TextColumn get id => text()();
  TextColumn get shiftId => text().references(Shifts, #id)();
  TextColumn get cashierId => text()();
  TextColumn get customerId => text().nullable()();

  /// Menejer ruxsati (qarz limiti, narx o'zgarishi).
  TextColumn get approvedBy => text().nullable()();

  /// Qurilma ichida ketma-ket: `D3-000123`.
  TextColumn get number => text().unique()();
  IntColumn get subtotalTiyin => integer()();
  IntColumn get discountTiyin => integer()();
  IntColumn get totalTiyin => integer()();

  /// `completed` / `partially_refunded` / `refunded`.
  TextColumn get status => text().withDefault(const Constant('completed'))();
  TextColumn get debtEntryId => text().nullable()();
  DateTimeColumn get soldAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(name: 'sale_items_sale', columns: {#saleId})
class SaleItems extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text().references(Sales, #id)();

  /// Chekdagi tartib (0 dan).
  IntColumn get position => integer()();
  TextColumn get productId => text()();
  TextColumn get nameSnapshot => text()();
  TextColumn get barcodeSnapshot => text().nullable()();
  IntColumn get qtyMilli => integer()();
  IntColumn get priceTiyin => integer()();
  IntColumn get costTiyin => integer()();
  IntColumn get discountTiyin => integer()();
  IntColumn get totalTiyin => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(name: 'sale_payments_sale', columns: {#saleId})
class SalePayments extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text().references(Sales, #id)();

  /// `cash` / `card` / `debt`.
  TextColumn get method => text()();
  IntColumn get amountTiyin => integer()();

  /// Naqd: olingan pul; karta/nasiya — `null`.
  IntColumn get receivedTiyin => integer().nullable()();
  IntColumn get changeTiyin => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Qaytarish. Savdo boshqa qurilmada bo'lishi mumkin — `sale_id` ga FK yo'q.
@TableIndex(name: 'refunds_sale', columns: {#saleId})
class Refunds extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text()();
  TextColumn get shiftId => text().references(Shifts, #id)();
  TextColumn get cashierId => text()();
  TextColumn get approvedBy => text().nullable()();
  TextColumn get reason => text().withDefault(const Constant(''))();

  /// `cash` / `debt`.
  TextColumn get method => text()();
  IntColumn get totalTiyin => integer()();
  TextColumn get debtEntryId => text().nullable()();
  DateTimeColumn get at => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class RefundItems extends Table {
  TextColumn get id => text()();
  TextColumn get refundId => text().references(Refunds, #id)();
  TextColumn get saleItemId => text()();
  IntColumn get qtyMilli => integer()();
  IntColumn get totalTiyin => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Kassaga pul kiritish/chiqarish.
class CashMovements extends Table {
  TextColumn get id => text()();
  TextColumn get shiftId => text().references(Shifts, #id)();

  /// `in` / `out`.
  TextColumn get type => text()();
  IntColumn get amountTiyin => integer()();
  TextColumn get reason => text().withDefault(const Constant(''))();
  TextColumn get byUserId => text()();
  DateTimeColumn get at => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Kirim (tovar qabul qilish). Qoralama tahrirlanadi, tasdiqlangani o'zgarmas.
class StockReceipts extends Table {
  TextColumn get id => text()();
  TextColumn get supplierId => text().nullable()();
  TextColumn get storeId => text().nullable()();

  /// Tartib raqami — server beradi (pull'dan keyin).
  IntColumn get number => integer().nullable()();

  /// `draft` / `posted`.
  TextColumn get status => text().withDefault(const Constant('draft'))();
  IntColumn get totalCostTiyin => integer().withDefault(const Constant(0))();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get postedAt => dateTime().nullable()();
  TextColumn get postedBy => text().nullable()();

  /// Tuzatish (T-102): bu kirim qaysi kirimning yangi versiyasi. Asl kirim
  /// o'zgarmaydi — "tuzatilgan" holati shu ustundan topiladi.
  TextColumn get correctsId => text().nullable()();

  /// Teskari yozuv: qaysi kirimni bekor qiladi (manfiy qatorlar).
  TextColumn get reversesId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StockReceiptItems extends Table {
  TextColumn get id => text()();
  TextColumn get receiptId => text().references(StockReceipts, #id)();
  IntColumn get position => integer()();
  TextColumn get productId => text()();
  IntColumn get qtyMilli => integer()();
  IntColumn get costPriceTiyin => integer()();
  IntColumn get newSellPriceTiyin => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class InventoryCounts extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text().nullable()();

  /// `draft` / `posted`.
  TextColumn get status => text().withDefault(const Constant('draft'))();

  /// `all` / `category`.
  TextColumn get scope => text().withDefault(const Constant('all'))();
  TextColumn get categoryId => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get postedAt => dateTime().nullable()();
  TextColumn get postedBy => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(
  name: 'inventory_count_items_unique_product',
  columns: {#countId, #productId},
  unique: true,
)
class InventoryCountItems extends Table {
  TextColumn get id => text()();
  TextColumn get countId => text().references(InventoryCounts, #id)();
  TextColumn get productId => text()();

  /// Tasdiqlash paytidagi qoldiq; qoralamada `null`.
  IntColumn get expectedMilli => integer().nullable()();
  IntColumn get countedMilli => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Lokal qoldiq harakatlari (o'zgarmas). Qoldiq = server qoldig'i + hali
/// server tasdiqlamagan harakatlar (`outbox_event_id` orqali, T-035).
@TableIndex(name: 'stock_movements_product', columns: {#productId})
@TableIndex(name: 'stock_movements_event', columns: {#outboxEventId})
class StockMovements extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get storeId => text().nullable()();

  /// + kirim/qaytarish, − savdo.
  IntColumn get qtyMilli => integer()();

  /// `receipt` / `sale` / `refund` / `adjustment` / `inventory`.
  TextColumn get type => text()();
  TextColumn get refType => text()();
  TextColumn get refId => text()();
  TextColumn get outboxEventId => text().nullable()();
  DateTimeColumn get at => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
