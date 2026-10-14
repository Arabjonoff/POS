import 'package:flutter/widgets.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/core/time/store_time_zone.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Ekranga chiqariladigan summa, miqdor, sana va vaqt — joriy tilda
/// (`docs/specs/i18n.md`). Pul — tiyin (`int`), miqdor — `qty_milli` (`int`).
///
/// Ekranda: `context.fmt.money(sale.totalTiyin)`.
class AppFormat {
  const AppFormat(this.l10n, {this.timeZone = StoreTimeZone.tashkent});

  final AppLocalizations l10n;
  final StoreTimeZone timeZone;

  /// `125 000 so'm`, tiyin bo'lsa `125 000,50 so'm`.
  String money(int tiyin) => PosFormat.money(tiyin, currency: l10n.currencySom);

  /// Valyutasiz: `125 000`.
  String moneyAmount(int tiyin) => PosFormat.moneyAmount(tiyin);

  /// Valyuta nomi: `so'm` / `сўм` / `сум`.
  String get currency => l10n.currencySom;

  /// Miqdor birlik bilan: `3 dona`, `1,250 kg`.
  String qty(int qtyMilli, UnitCode unit) => PosFormat.qtyWithUnit(
    qtyMilli,
    unit: unit.label(l10n),
    weighted: unit.fractional,
  );

  /// Miqdor birliksiz: `3`, `1,250`.
  String qtyValue(int qtyMilli, UnitCode unit) =>
      PosFormat.qty(qtyMilli, weighted: unit.fractional);

  /// Sana do'kon vaqt zonasida: `13.10.2026`.
  String date(DateTime instant) {
    final t = timeZone.wallClock(instant);
    return '${_two(t.day)}.${_two(t.month)}.${t.year}';
  }

  /// Vaqt do'kon vaqt zonasida: `20:15`.
  String time(DateTime instant) {
    final t = timeZone.wallClock(instant);
    return '${_two(t.hour)}:${_two(t.minute)}';
  }

  /// `13.10.2026 20:15`.
  String dateTime(DateTime instant) => '${date(instant)} ${time(instant)}';

  static String _two(int v) => v.toString().padLeft(2, '0');
}

extension AppFormatContext on BuildContext {
  /// Joriy til bo'yicha formatlash (vaqt zonasi — do'kon sozlamasidan,
  /// hozircha Toshkent; do'kon sozlamalari T-034 sinxronidan keyin).
  AppFormat get fmt => AppFormat(AppLocalizations.of(this));
}
