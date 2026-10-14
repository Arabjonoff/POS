import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers.dart';

const String _sp = PosFormat.nbsp;

void main() {
  group('PosMoneyText', () {
    testWidgets('formats tiyin as som', (tester) async {
      await pumpPos(
        tester,
        const PosMoneyText(amount: 12500000, currency: "so'm"),
      );
      expect(find.text("125${_sp}000${_sp}so'm"), findsOneWidget);
    });

    testWidgets('total size depends on window size', (tester) async {
      Future<double> fontSizeAt(Size size) async {
        await pumpPos(
          tester,
          const PosMoneyText(
            amount: 100,
            currency: "so'm",
            size: PosMoneySize.total,
          ),
          size: size,
        );
        return tester.widget<Text>(find.byType(Text)).style!.fontSize!;
      }

      expect(await fontSizeAt(const Size(390, 844)), 32);
      expect(await fontSizeAt(const Size(700, 900)), 40);
      expect(await fontSizeAt(const Size(1440, 900)), 48);
    });

    testWidgets('total is the largest text and scales down to fit', (
      tester,
    ) async {
      await pumpPos(
        tester,
        const SizedBox(
          width: 120,
          child: PosMoneyText(
            amount: 99999999999900,
            currency: "so'm",
            size: PosMoneySize.total,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(FittedBox)).width,
        lessThanOrEqualTo(120),
      );
    });

    testWidgets('tone colors text', (tester) async {
      await pumpPos(
        tester,
        const PosMoneyText(
          amount: 500,
          currency: "so'm",
          tone: PosTone.success,
        ),
      );
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style!.color, PosPalette.light.successText);
    });
  });

  group('PosQtyStepper', () {
    testWidgets('increments and decrements by step', (tester) async {
      final values = <int>[];
      await pumpPos(
        tester,
        PosQtyStepper(
          valueMilli: 2000,
          onChanged: values.add,
          decrementTooltip: 'Less',
          incrementTooltip: 'More',
        ),
      );
      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.byTooltip('More'));
      await tester.tap(find.byTooltip('Less'));
      expect(values, [3000, 1000]);
    });

    testWidgets('respects min and max', (tester) async {
      final values = <int>[];
      await pumpPos(
        tester,
        PosQtyStepper(
          valueMilli: 1000,
          minMilli: 1000,
          maxMilli: 1000,
          onChanged: values.add,
          decrementTooltip: 'Less',
          incrementTooltip: 'More',
        ),
      );
      await tester.tap(find.byTooltip('More'));
      await tester.tap(find.byTooltip('Less'));
      expect(values, isEmpty);
    });

    testWidgets('weighted with unit', (tester) async {
      await pumpPos(
        tester,
        PosQtyStepper(
          valueMilli: 1250,
          stepMilli: 250,
          weighted: true,
          unit: 'kg',
          onChanged: (_) {},
          decrementTooltip: 'Less',
          incrementTooltip: 'More',
          large: true,
        ),
      );
      expect(find.text('1,250${_sp}kg'), findsOneWidget);
      expect(
        tester.getSize(find.byType(PosQtyStepper)).height,
        greaterThanOrEqualTo(56),
      );
    });

    testWidgets('value tap', (tester) async {
      var taps = 0;
      await pumpPos(
        tester,
        PosQtyStepper(
          valueMilli: 1000,
          onChanged: (_) {},
          onValueTap: () => taps++,
          decrementTooltip: 'Less',
          incrementTooltip: 'More',
        ),
      );
      await tester.tap(find.text('1'));
      expect(taps, 1);
    });
  });

  group('PosNumericKeypad', () {
    testWidgets('emits keys, backspace and clear', (tester) async {
      final keys = <String>[];
      var back = 0;
      var cleared = 0;
      await pumpPos(
        tester,
        SizedBox(
          width: 320,
          child: PosNumericKeypad(
            onKey: keys.add,
            onBackspace: () => back++,
            onClear: () => cleared++,
            backspaceTooltip: 'Erase',
            extraKey: '00',
          ),
        ),
      );
      for (final d in ['1', '5', '0', '00', '9']) {
        await tester.tap(find.text(d));
      }
      expect(keys, ['1', '5', '0', '00', '9']);
      await tester.tap(find.bySemanticsLabel('Erase'));
      expect(back, 1);
      await tester.longPress(find.bySemanticsLabel('Erase'));
      expect(cleared, 1);
    });

    testWidgets('keys are at least 64 dp', (tester) async {
      await pumpPos(
        tester,
        SizedBox(
          width: 320,
          child: PosNumericKeypad(
            onKey: (_) {},
            onBackspace: () {},
            backspaceTooltip: 'Erase',
          ),
        ),
      );
      final key = find.ancestor(
        of: find.text('5'),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(key).height, greaterThanOrEqualTo(64));
      expect(tester.getSize(key).width, greaterThanOrEqualTo(64));
    });

    testWidgets('disabled ignores taps', (tester) async {
      final keys = <String>[];
      await pumpPos(
        tester,
        SizedBox(
          width: 320,
          child: PosNumericKeypad(
            onKey: keys.add,
            onBackspace: () {},
            backspaceTooltip: 'Erase',
            enabled: false,
          ),
        ),
      );
      await tester.tap(find.text('7'));
      expect(keys, isEmpty);
    });
  });

  group('PosPinPad', () {
    testWidgets('variable length: submit by ✓ and Enter, dots grow', (
      tester,
    ) async {
      var submits = 0;
      await pumpPos(
        tester,
        PosPinPad(
          filled: 5,
          onDigit: (_) {},
          onBackspace: () {},
          onSubmit: () => submits++,
          backspaceTooltip: 'Erase',
          submitTooltip: 'Enter PIN',
        ),
      );
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Enter PIN'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(submits, 2);
      // 5 ta kiritilgan — 5 ta nuqta (standart 4 dan ko'p).
      expect(
        find.descendant(
          of: find.bySemanticsLabel('5'),
          matching: find.byType(AnimatedContainer),
        ),
        findsNWidgets(5),
      );
    });

    testWidgets('submit key is disabled with the pad', (tester) async {
      var submits = 0;
      await pumpPos(
        tester,
        PosPinPad(
          filled: 4,
          onDigit: (_) {},
          onBackspace: () {},
          onSubmit: () => submits++,
          backspaceTooltip: 'Erase',
          submitTooltip: 'Enter PIN',
          enabled: false,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Enter PIN'));
      expect(submits, 0);
    });

    testWidgets('on-screen and physical keyboard input', (tester) async {
      final digits = <String>[];
      var back = 0;
      await pumpPos(
        tester,
        PosPinPad(
          filled: 2,
          onDigit: digits.add,
          onBackspace: () => back++,
          backspaceTooltip: 'Erase',
        ),
      );
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad4);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      expect(digits, ['3', '7', '4']);
      expect(back, 1);
    });

    testWidgets('error text and disabled state', (tester) async {
      final digits = <String>[];
      await pumpPos(
        tester,
        PosPinPad(
          filled: 4,
          onDigit: digits.add,
          onBackspace: () {},
          backspaceTooltip: 'Erase',
          errorText: 'Wrong PIN',
          enabled: false,
        ),
      );
      await tester.pump();
      expect(find.text('Wrong PIN'), findsOneWidget);
      await tester.tap(find.text('1'));
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      expect(digits, isEmpty);
    });
  });
}
