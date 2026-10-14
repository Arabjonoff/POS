import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const Map<String, LogicalKeyboardKey> _keys = {
  '0': LogicalKeyboardKey.digit0,
  '1': LogicalKeyboardKey.digit1,
  '2': LogicalKeyboardKey.digit2,
  '3': LogicalKeyboardKey.digit3,
  '4': LogicalKeyboardKey.digit4,
  '5': LogicalKeyboardKey.digit5,
  '6': LogicalKeyboardKey.digit6,
  '7': LogicalKeyboardKey.digit7,
  '8': LogicalKeyboardKey.digit8,
  '9': LogicalKeyboardKey.digit9,
  ',': LogicalKeyboardKey.comma,
  '-': LogicalKeyboardKey.minus,
  ' ': LogicalKeyboardKey.space,
  'a': LogicalKeyboardKey.keyA,
  'b': LogicalKeyboardKey.keyB,
  'c': LogicalKeyboardKey.keyC,
  'd': LogicalKeyboardKey.keyD,
  'e': LogicalKeyboardKey.keyE,
  'f': LogicalKeyboardKey.keyF,
  'g': LogicalKeyboardKey.keyG,
  'h': LogicalKeyboardKey.keyH,
  'i': LogicalKeyboardKey.keyI,
  'j': LogicalKeyboardKey.keyJ,
  'k': LogicalKeyboardKey.keyK,
  'l': LogicalKeyboardKey.keyL,
  'm': LogicalKeyboardKey.keyM,
  'n': LogicalKeyboardKey.keyN,
  'o': LogicalKeyboardKey.keyO,
  'p': LogicalKeyboardKey.keyP,
  'q': LogicalKeyboardKey.keyQ,
  'r': LogicalKeyboardKey.keyR,
  's': LogicalKeyboardKey.keyS,
  't': LogicalKeyboardKey.keyT,
  'u': LogicalKeyboardKey.keyU,
  'v': LogicalKeyboardKey.keyV,
  'x': LogicalKeyboardKey.keyX,
  'y': LogicalKeyboardKey.keyY,
  'z': LogicalKeyboardKey.keyZ,
};

/// HID skaner: belgilar 10 ms oraliqda + Enter (`barcode.md`).
Future<void> scanCode(WidgetTester tester, String code) async {
  for (final ch in code.split('')) {
    await tester.sendKeyEvent(_keys[ch]!);
    await tester.pump(const Duration(milliseconds: 10));
  }
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}

/// Inson yozuvi: 150 ms oraliq (skaner buferi uni matn sifatida qaytaradi).
Future<void> typeSlowly(WidgetTester tester, String text) async {
  for (final ch in text.split('')) {
    await tester.sendKeyEvent(_keys[ch]!);
    await tester.pump(const Duration(milliseconds: 150));
  }
  await tester.pumpAndSettle();
}

/// Tezkor tugma.
Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}
