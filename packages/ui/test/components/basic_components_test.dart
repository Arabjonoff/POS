import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers.dart';

void main() {
  group('PosButton', () {
    testWidgets('sizes meet touch targets', (tester) async {
      for (final size in PosButtonSize.values) {
        await pumpPos(
          tester,
          PosButton(label: 'OK', size: size, onPressed: () {}),
        );
        final height = tester.getSize(find.byType(TextButton)).height;
        expect(height, greaterThanOrEqualTo(PosSizes.touchMin));
        expect(height, size.height);
      }
      expect(PosButtonSize.m.height, greaterThanOrEqualTo(56));
    });

    testWidgets('tap calls onPressed', (tester) async {
      var taps = 0;
      await pumpPos(tester, PosButton(label: 'Pay', onPressed: () => taps++));
      await tester.tap(find.text('Pay'));
      expect(taps, 1);
    });

    testWidgets('loading swallows taps and shows spinner', (tester) async {
      var taps = 0;
      await pumpPos(
        tester,
        PosButton(label: 'Pay', loading: true, onPressed: () => taps++),
      );
      await tester.tap(find.text('Pay'), warnIfMissed: false);
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disabled when onPressed is null', (tester) async {
      await pumpPos(tester, const PosButton(label: 'Pay', onPressed: null));
      final button = tester.widget<TextButton>(find.byType(TextButton));
      expect(button.enabled, isFalse);
    });

    testWidgets('shows shortcut keycap and activates by keyboard', (
      tester,
    ) async {
      var taps = 0;
      await pumpPos(
        tester,
        PosButton(
          label: 'Pay',
          shortcut: 'F12',
          autofocus: true,
          onPressed: () => taps++,
        ),
      );
      expect(find.text('F12'), findsOneWidget);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('expand fills width', (tester) async {
      await pumpPos(
        tester,
        SizedBox(
          width: 300,
          child: PosButton(label: 'Pay', expand: true, onPressed: () {}),
        ),
      );
      expect(tester.getSize(find.byType(TextButton)).width, 300);
    });
  });

  group('PosIconButton', () {
    testWidgets('has tooltip semantics and min size', (tester) async {
      await pumpPos(
        tester,
        PosIconButton(icon: Icons.add, tooltip: 'Add', onPressed: () {}),
      );
      expect(find.byTooltip('Add'), findsOneWidget);
      final size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('PosTextField', () {
    testWidgets('label, error with icon, input', (tester) async {
      String? changed;
      await pumpPos(
        tester,
        SizedBox(
          width: 320,
          child: PosTextField(
            label: 'Name',
            errorText: 'Required',
            onChanged: (v) => changed = v,
          ),
        ),
      );
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Non');
      expect(changed, 'Non');
      expect(
        tester.getSize(find.byType(TextField)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('helper hidden while error shown', (tester) async {
      await pumpPos(
        tester,
        const SizedBox(
          width: 320,
          child: PosTextField(helper: 'Hint', errorText: 'Bad'),
        ),
      );
      expect(find.text('Hint'), findsNothing);
      expect(find.text('Bad'), findsOneWidget);
    });
  });

  group('PosSearchField', () {
    testWidgets('shows shortcut when empty, clear button when filled', (
      tester,
    ) async {
      final values = <String>[];
      await pumpPos(
        tester,
        SizedBox(
          width: 360,
          child: PosSearchField(
            hint: 'Search',
            clearTooltip: 'Clear',
            shortcut: 'F1',
            onChanged: values.add,
          ),
        ),
      );
      expect(find.text('F1'), findsOneWidget);
      expect(find.byTooltip('Clear'), findsNothing);

      await tester.enterText(find.byType(TextField), 'non');
      await tester.pump();
      expect(find.text('F1'), findsNothing);
      expect(find.byTooltip('Clear'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear'));
      await tester.pump();
      expect(find.text('non'), findsNothing);
      expect(values.last, '');
    });

    testWidgets('works with external controller', (tester) async {
      final controller = TextEditingController(text: 'abc');
      addTearDown(controller.dispose);
      await pumpPos(
        tester,
        SizedBox(
          width: 360,
          child: PosSearchField(
            hint: 'Search',
            clearTooltip: 'Clear',
            controller: controller,
          ),
        ),
      );
      expect(find.byTooltip('Clear'), findsOneWidget);
      controller.clear();
      await tester.pump();
      expect(find.byTooltip('Clear'), findsNothing);
    });
  });

  group('PosCard and PosListTile', () {
    testWidgets('card tap', (tester) async {
      var taps = 0;
      await pumpPos(
        tester,
        PosCard(onTap: () => taps++, child: const Text('Card')),
      );
      await tester.tap(find.text('Card'));
      expect(taps, 1);
    });

    testWidgets('list tile min height and disabled', (tester) async {
      var taps = 0;
      await pumpPos(
        tester,
        SizedBox(
          width: 400,
          child: PosListTile(
            title: 'Non',
            subtitle: '3 dona',
            enabled: false,
            onTap: () => taps++,
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(PosListTile)).height,
        greaterThanOrEqualTo(56),
      );
      await tester.tap(find.text('Non'));
      expect(taps, 0);
    });
  });

  group('PosBadge and PosStatusDot', () {
    testWidgets('badge renders label and icon', (tester) async {
      await pumpPos(
        tester,
        const PosBadge(
          label: 'Paid',
          tone: PosTone.success,
          icon: Icons.check,
        ),
      );
      expect(find.text('Paid'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('status dot without label keeps semantics', (tester) async {
      await pumpPos(
        tester,
        const PosStatusDot(label: 'Online', showLabel: false),
      );
      expect(find.text('Online'), findsNothing);
      expect(find.bySemanticsLabel('Online'), findsOneWidget);
    });
  });
}
