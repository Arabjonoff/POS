import 'package:drift/drift.dart';

// Ma'lumotnoma jadvallari: serverdan pull orqali keladi, konfliktda server
// g'olib (`docs/specs/sync.md`). Pull tartibi kafolatlanmagani uchun bu
// jadvallar orasida tashqi kalit (FK) yo'q — yaxlitlikni server ta'minlaydi.
// O'chirish — faqat yumshoq (`deleted_at`).

class Stores extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get receiptHeader => text().withDefault(const Constant(''))();
  TextColumn get receiptFooter => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Do'kon xodimlari (pull: `user`). PIN tekshiruvi oflaynda — `pin_hash`.
class StaffUsers extends Table {
  TextColumn get id => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get fullName => text()();

  /// `owner` / `manager` / `cashier`.
  TextColumn get role => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get pinHash => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Units extends Table {
  TextColumn get id => text()();

  /// `pcs` / `kg` / `g` / `l` / `m` / `pack` yoki o'z kodi.
  TextColumn get code => text()();

  /// Standart birliklarda bo'sh — nom tarjimadan (`UnitCode`).
  TextColumn get name => text().withDefault(const Constant(''))();
  BoolColumn get isFractional => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();
  IntColumn get sort => integer().withDefault(const Constant(0))();

  /// Dizayn palitrasi kaliti (masalan, `green`).
  TextColumn get color => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(name: 'products_plu', columns: {#pluCode})
@TableIndex(name: 'products_search', columns: {#searchKey})
@TableIndex(name: 'products_quick', columns: {#quickButton})
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Qidiruv kaliti: kichik harf, lotin/kirill transliteratsiyasi (T-042).
  TextColumn get searchKey => text().withDefault(const Constant(''))();
  TextColumn get categoryId => text().nullable()();
  TextColumn get unitId => text()();
  IntColumn get sellPriceTiyin => integer()();
  IntColumn get costPriceTiyin => integer().withDefault(const Constant(0))();
  BoolColumn get isWeighted => boolean().withDefault(const Constant(false))();

  /// Vaznli tovar uchun tarozi kodi (5 raqam).
  TextColumn get pluCode => text().nullable()();
  IntColumn get minStockMilli => integer().withDefault(const Constant(0))();
  TextColumn get ikpuCode => text().nullable()();
  BoolColumn get quickButton => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Shtrix-kodlar: tovar upsert'ida shu tovarniki to'liq almashtiriladi.
@TableIndex(name: 'product_barcodes_product', columns: {#productId})
class ProductBarcodes extends Table {
  /// Matn (boshidagi nollar saqlanadi), tenant ichida yagona.
  TextColumn get barcode => text()();
  TextColumn get productId => text()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {barcode};
}

class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text()();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();

  /// `null` — cheklovsiz.
  IntColumn get debtLimitTiyin => integer().nullable()();

  /// Serverdagi qarz (pull paytidagi holat); lokal yozuvlar alohida qo'shiladi.
  IntColumn get balanceTiyin => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Suppliers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Serverdagi qoldiq (pull: `stock`). Kassadagi qoldiq = shu + hali
/// yuborilmagan lokal harakatlar (`stock_movements`).
class ProductStock extends Table {
  TextColumn get productId => text()();
  TextColumn get storeId => text()();
  IntColumn get qtyMilli => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {productId};
}

/// Qarz daftari (o'zgarmas): + qarz, − to'lov. Lokal va pull'dan kelganlar
/// bir jadvalda (`id` bir xil — upsert).
@TableIndex(name: 'debt_entries_customer', columns: {#customerId})
class DebtEntries extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text()();
  IntColumn get amountTiyin => integer()();

  /// `sale` / `payment` / `refund` / `adjustment`.
  TextColumn get type => text()();
  TextColumn get saleId => text().nullable()();
  TextColumn get refundId => text().nullable()();
  TextColumn get shiftId => text().nullable()();

  /// To'lov usuli (`cash` / `card`), faqat `payment` da.
  TextColumn get method => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get byUserId => text().nullable()();
  DateTimeColumn get at => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
