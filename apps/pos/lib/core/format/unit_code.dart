import 'package:pos_app/l10n/gen/app_localizations.dart';

/// O'lchov birligi kodi (`Unit.code`, `docs/specs/data-model.md`).
enum UnitCode {
  pcs('pcs'),
  kg('kg', fractional: true),
  g('g'),
  l('l', fractional: true),
  m('m', fractional: true),
  pack('pack')
  ;

  const UnitCode(this.code, {this.fractional = false});

  /// Serverdagi kod.
  final String code;

  /// Kasr miqdor (vaznli/hajmli) — har doim 3 kasr xonasi: `1,250 kg`.
  final bool fractional;

  /// Noma'lum kod — dona (eski kassa yangi server birligini ko'rsa ham ishlaydi).
  static UnitCode fromCode(String? code) =>
      values.firstWhere((u) => u.code == code, orElse: () => pcs);

  /// Qisqa nomi joriy tilda.
  String label(AppLocalizations l10n) => switch (this) {
    pcs => l10n.unitPcs,
    kg => l10n.unitKg,
    g => l10n.unitG,
    l => l10n.unitL,
    m => l10n.unitM,
    pack => l10n.unitPack,
  };
}
