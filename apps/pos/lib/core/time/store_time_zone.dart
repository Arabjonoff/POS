/// Do'kon vaqt zonasi (`Tenant.timezone`, standart `Asia/Tashkent`).
///
/// O'zbekistonda yozgi vaqt yo'q (1992 yildan beri UTC+5), shuning uchun
/// to'liq IANA bazasi o'rniga qat'iy siljish ishlatiladi (qaror 0007).
/// Noma'lum zona — Toshkent.
enum StoreTimeZone {
  tashkent('Asia/Tashkent', Duration(hours: 5)),
  samarkand('Asia/Samarkand', Duration(hours: 5))
  ;

  const StoreTimeZone(this.zoneName, this.offset);

  /// IANA nomi.
  final String zoneName;
  final Duration offset;

  /// IANA nomi bo'yicha; qo'llab-quvvatlanmasa — [tashkent].
  static StoreTimeZone fromName(String? name) =>
      values.firstWhere((z) => z.zoneName == name, orElse: () => tashkent);

  /// Vaqt momentini do'kon soatiga o'tkazadi. Natija — UTC `DateTime`, lekin
  /// maydonlari (yil, oy, kun, soat) do'kondagi devor soatini bildiradi.
  DateTime wallClock(DateTime instant) => instant.toUtc().add(offset);

  /// Do'kon bo'yicha "bugun" (soat 00:00, devor soati).
  DateTime today(DateTime now) {
    final wall = wallClock(now);
    return DateTime.utc(wall.year, wall.month, wall.day);
  }
}
