import 'package:drift/drift.dart';

/// Lokal sozlamalar (kalit → qiymat): til, qurilma raqami va h.k.
class LocalSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Serverga yuboriladigan hodisalar (`docs/specs/sync.md`). Hujjat bilan
/// **bitta tranzaksiyada** yoziladi.
@TableIndex(name: 'outbox_events_queue', columns: {#status, #createdAt})
class OutboxEvents extends Table {
  /// Hodisa UUIDv7 (server shu bo'yicha idempotent).
  TextColumn get id => text()();

  /// `sale.completed`, `shift.opened`, ...
  TextColumn get type => text()();

  /// JSON.
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();

  /// `pending` — yuborilmagan; `sent` — applied/duplicate/pending;
  /// `rejected` — server rad etdi, qayta yuborilmaydi.
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  DateTimeColumn get sentAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Sinxron holati — bitta qator (`id = 1`).
class SyncState extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// Pull kursori (ochiq bo'lmagan satr, boshida `"0"`).
  TextColumn get pullCursor => text().withDefault(const Constant('0'))();
  DateTimeColumn get lastPushAt => dateTime().nullable()();
  DateTimeColumn get lastPullAt => dateTime().nullable()();

  /// Oxirgi pull'dagi `subscription` (JSON).
  TextColumn get subscriptionJson => text().nullable()();

  /// Shu vaqtdan keyin oflayn savdo to'xtaydi (`server_time + offline_days`).
  DateTimeColumn get offlineGraceUntil => dateTime().nullable()();

  /// `server_time − qurilma vaqti` (ms).
  IntColumn get serverTimeOffsetMs =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Ochiq savatlar (kechiktirilgan cheklar, ≤ 5): har o'zgarishda saqlanadi,
/// ilova qayta ochilganda tiklanadi.
class CartDrafts extends Table {
  TextColumn get id => text()();

  /// Tab tartibi (0..4).
  IntColumn get slot => integer().unique()();
  TextColumn get customerId => text().nullable()();

  /// Savat qatorlari (JSON).
  TextColumn get linesJson => text().withDefault(const Constant('[]'))();

  /// Chek chegirmasi (JSON: `percent_bp` yoki `amount_tiyin`), v3.
  TextColumn get discountJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Hujjat raqamlari hisoblagichi (masalan, `sale` → chek raqami).
class DocCounters extends Table {
  TextColumn get name => text()();
  IntColumn get value => integer()();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

/// Tovar rasmlari (T-105): yuklash navbati va lokal kesh ro'yxati. Rasm JSON
/// outbox'dan o'tmaydi (outbox kichik va tez qolsin). Holat:
/// `local` — yuklanishi kerak, `uploaded` — serverda, `remote` — serverdan
/// yuklab olingan, `delete` — serverdan o'chirilishi kerak, `failed` — server
/// qabul qilmadi (rasm buzuq).
class ProductImages extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get state => text()();

  /// Yuklagan ega/menejer (server huquqni tekshiradi).
  TextColumn get byUserId => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
