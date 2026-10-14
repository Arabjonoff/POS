import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/locale.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/core/time/store_time_zone.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';

const String _sp = ' ';

AppFormat _fmt(Locale locale) => AppFormat(lookupAppLocalizations(locale));

void main() {
  group('money', () {
    test("Uzbek Latin: 125 000 so'm", () {
      expect(_fmt(AppLocales.uzLatn).money(12500000), "125${_sp}000${_sp}so'm");
    });

    test('Uzbek Cyrillic and Russian currency names', () {
      expect(_fmt(AppLocales.uzCyrl).money(12500000), '125${_sp}000$_spсўм');
      expect(_fmt(AppLocales.ru).money(12500000), '125${_sp}000$_spсум');
    });

    test('tiyin and amount without currency', () {
      final fmt = _fmt(AppLocales.uzLatn);
      expect(fmt.money(12500050), "125${_sp}000,50${_sp}so'm");
      expect(fmt.moneyAmount(990000), '9${_sp}900');
      expect(fmt.currency, "so'm");
    });
  });

  group('qty', () {
    test('pieces and weight', () {
      final fmt = _fmt(AppLocales.uzLatn);
      expect(fmt.qty(3000, UnitCode.pcs), '3${_sp}dona');
      expect(fmt.qty(1250, UnitCode.kg), '1,250${_sp}kg');
      expect(fmt.qty(250, UnitCode.kg), '0,250${_sp}kg');
      expect(fmt.qty(2000, UnitCode.l), '2,000${_sp}l');
      expect(fmt.qtyValue(1250, UnitCode.kg), '1,250');
      expect(fmt.qtyValue(4000, UnitCode.pack), '4');
    });

    test('unit names per language', () {
      expect(_fmt(AppLocales.ru).qty(3000, UnitCode.pcs), '3$_spшт');
      expect(_fmt(AppLocales.uzCyrl).qty(1500, UnitCode.kg), '1,500$_spкг');
    });

    test('unknown unit code falls back to pieces', () {
      expect(UnitCode.fromCode('kg'), UnitCode.kg);
      expect(UnitCode.fromCode('box'), UnitCode.pcs);
      expect(UnitCode.fromCode(null), UnitCode.pcs);
    });
  });

  group('date and time (Asia/Tashkent, UTC+5)', () {
    final fmt = _fmt(AppLocales.uzLatn);

    test('formats in store time zone regardless of device zone', () {
      final instant = DateTime.utc(2026, 10, 13, 15, 15);
      expect(fmt.date(instant), '13.10.2026');
      expect(fmt.time(instant), '20:15');
      expect(fmt.dateTime(instant), '13.10.2026 20:15');
    });

    test('day boundary: 19:00 UTC is next day 00:00 in Tashkent', () {
      expect(
        fmt.dateTime(DateTime.utc(2026, 12, 31, 18, 59)),
        '31.12.2026 23:59',
      );
      expect(fmt.dateTime(DateTime.utc(2026, 12, 31, 19)), '01.01.2027 00:00');
    });

    test('local DateTime is converted via UTC', () {
      final local = DateTime.utc(2026, 1, 5, 4, 7).toLocal();
      expect(fmt.dateTime(local), '05.01.2026 09:07');
    });

    test('store "today"', () {
      expect(
        StoreTimeZone.tashkent.today(DateTime.utc(2026, 3, 1, 20)),
        DateTime.utc(2026, 3, 2),
      );
    });

    test('time zone lookup', () {
      expect(StoreTimeZone.fromName('Asia/Samarkand'), StoreTimeZone.samarkand);
      expect(StoreTimeZone.fromName('Europe/Moscow'), StoreTimeZone.tashkent);
      expect(StoreTimeZone.fromName(null), StoreTimeZone.tashkent);
    });
  });

  group('plurals', () {
    test('queued records', () {
      final uz = lookupAppLocalizations(AppLocales.uzLatn);
      expect(uz.statusQueued(0), 'Hammasi yuborilgan');
      expect(uz.statusQueued(12), '12 ta yozuv navbatda');

      final ru = lookupAppLocalizations(AppLocales.ru);
      expect(ru.statusQueued(1), '1 запись в очереди');
      expect(ru.statusQueued(3), '3 записи в очереди');
      expect(ru.statusQueued(12), '12 записей в очереди');
      expect(ru.statusQueued(21), '21 запись в очереди');

      final cyrl = lookupAppLocalizations(AppLocales.uzCyrl);
      expect(cyrl.statusQueued(5), '5 та ёзув навбатда');
    });
  });
}
