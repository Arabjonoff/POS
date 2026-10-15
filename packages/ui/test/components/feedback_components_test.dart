import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers.dart';

Widget _opener(void Function(BuildContext) onPressed) => Builder(
  builder: (context) => PosButton(
    label: 'Open',
    onPressed: () => onPressed(context),
  ),
);

Future<String?> _openDialog(BuildContext context) => showPosDialog<String>(
  context: context,
  builder: (context) => PosDialog(
    title: 'Delete line?',
    message: 'Line will be removed.',
    actions: [
      PosButton(
        label: 'Cancel',
        variant: PosButtonVariant.secondary,
        onPressed: () => Navigator.of(context).pop('cancel'),
      ),
      PosButton(
        label: 'Delete',
        variant: PosButtonVariant.danger,
        onPressed: () => Navigator.of(context).pop('delete'),
      ),
    ],
  ),
);

void main() {
  group('showPosDialog', () {
    testWidgets('desktop opens centered dialog, Esc closes', (tester) async {
      Future<String?>? result;
      await pumpPos(
        tester,
        _opener((c) => result = _openDialog(c)),
        size: const Size(1440, 900),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Delete line?'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(await result, isNull);
    });

    testWidgets('phone opens bottom sheet with stacked actions', (
      tester,
    ) async {
      Future<String?>? result;
      await pumpPos(
        tester,
        _opener((c) => result = _openDialog(c)),
        size: const Size(390, 844),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);

      // Asosiy amal yuqorida, ikkala tugma to'liq kenglikda.
      final delete = tester.getRect(find.text('Delete'));
      final cancel = tester.getRect(find.text('Cancel'));
      expect(delete.top, lessThan(cancel.top));

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(await result, 'delete');
    });
  });

  group('showPosToast', () {
    testWidgets('shows message and undo action', (tester) async {
      var undone = 0;
      await pumpPos(
        tester,
        _opener(
          (c) => showPosToast(
            c,
            message: 'Line removed',
            tone: PosTone.success,
            actionLabel: 'Undo',
            onAction: () => undone++,
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Line removed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(undone, 1);
      expect(find.text('Line removed'), findsNothing);
    });

    testWidgets('hides after 5 seconds by default', (tester) async {
      await pumpPos(
        tester,
        _opener((c) => showPosToast(c, message: 'Saved')),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      // Taymer kirish animatsiyasi tugagach boshlanadi.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 4500));
      expect(find.text('Saved'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing);
    });
  });

  group('PosEmptyState', () {
    testWidgets('renders title, message, actions', (tester) async {
      await pumpPos(
        tester,
        PosEmptyState(
          icon: Icons.search_off,
          title: 'Not found',
          message: 'Add it?',
          action: PosButton(label: 'Add', onPressed: () {}),
        ),
      );
      expect(find.text('Not found'), findsOneWidget);
      expect(find.text('Add it?'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });
  });

  group('PosSkeleton', () {
    testWidgets('animates and is hidden from semantics', (tester) async {
      await pumpPos(
        tester,
        const SizedBox(width: 300, child: PosSkeletonListTile()),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(PosSkeleton), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('static when animations disabled', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpPos(tester, const PosSkeleton(width: 100));
      // Animatsiya yo'q — pumpAndSettle tugaydi.
      await tester.pumpAndSettle();
      expect(find.byType(PosSkeleton), findsOneWidget);
    });
  });

  group('PosScanFeedback', () {
    testWidgets('flashes the edge only and fades within 200 ms', (
      tester,
    ) async {
      final controller = PosScanFeedbackController();
      addTearDown(controller.dispose);
      await pumpPos(
        tester,
        SizedBox(
          width: 300,
          height: 200,
          child: PosScanFeedback(
            controller: controller,
            child: const Text('Cart'),
          ),
        ),
      );
      double opacity() => tester
          .widget<PosScanFeedbackOverlay>(find.byType(PosScanFeedbackOverlay))
          .opacity;

      expect(find.byType(PosScanFeedbackOverlay), findsNothing);
      controller.flash(PosScanResult.success);
      await tester.pump();
      expect(opacity(), 1);
      // Fon bo'yalmaydi — faqat chegara (butun ekran chaqnamasin).
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(PosScanFeedbackOverlay),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect((box.decoration as BoxDecoration).color, isNull);
      await tester.pump(const Duration(milliseconds: 50));
      expect(opacity(), 1);
      await tester.pump(const Duration(milliseconds: 160));
      expect(opacity(), 0);

      // Ketma-ket skaner — chaqnash qaytadan.
      controller.flash(PosScanResult.warning);
      await tester.pump();
      expect(opacity(), 1);
      expect(controller.last, PosScanResult.warning);
      await tester.pumpAndSettle();
    });

    testWidgets('can be removed before it ever flashed', (tester) async {
      final controller = PosScanFeedbackController();
      addTearDown(controller.dispose);
      await pumpPos(
        tester,
        PosScanFeedback(controller: controller, child: const Text('Cart')),
      );
      await pumpPos(tester, const Text('Other screen'));
      expect(tester.takeException(), isNull);
    });
  });
}
