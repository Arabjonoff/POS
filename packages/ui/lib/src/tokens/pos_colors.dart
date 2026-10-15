import 'package:flutter/painting.dart';

/// Boshlang'ich (primitiv) ranglar — `docs/specs/design-system.md`.
///
/// Ekranlar bu ranglarni to'g'ridan-to'g'ri ishlatmaydi: semantik ranglar
/// `PosPalette` orqali olinadi (`PosPalette.of(context)`). Kodning boshqa
/// joyida rang yozilmaydi.
abstract final class PosColors {
  // Chek qog'ozi — qorong'i mavzuda ham oq (haqiqiy chekdek ko'rinsin).
  static const Color receiptPaper = Color(0xFFFFFFFF);
  static const Color receiptInk = Color(0xFF111827);

  // Neytral (slate)
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color white = Color(0xFFFFFFFF);

  // Qorong'i mavzu fonlari
  static const Color night950 = Color(0xFF0B1220);
  static const Color night900 = Color(0xFF111827);
  static const Color night800 = Color(0xFF1F2937);
  static const Color night700 = Color(0xFF374151);

  // Asosiy (ko'k)
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue300 = Color(0xFF93C5FD);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue950 = Color(0xFF172554);

  // Muvaffaqiyat (yashil)
  static const Color green100 = Color(0xFFDCFCE7);
  static const Color green400 = Color(0xFF4ADE80);
  static const Color green500 = Color(0xFF22C55E);
  static const Color green700 = Color(0xFF15803D);
  static const Color green800 = Color(0xFF166534);
  static const Color green900 = Color(0xFF14532D);

  // Ogohlantirish (sariq)
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber700 = Color(0xFFB45309);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber950 = Color(0xFF451A03);

  // Xavf (qizil)
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red300 = Color(0xFFFCA5A5);
  static const Color red400 = Color(0xFFF87171);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red700 = Color(0xFFB91C1C);
  static const Color red950 = Color(0xFF450A0A);

  // Soya asosi
  static const Color shadow = Color(0xFF0F172A);
  static const Color shadowDark = Color(0xFF000000);
}
