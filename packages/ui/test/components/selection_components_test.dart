import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers.dart';

void main() {
  testWidgets('segmented control: one selected, tap changes it', (
    tester,
  ) async {
    var selected = 'none';
    await pumpPos(
      tester,
      StatefulBuilder(
        builder: (context, setState) => PosSegmentedControl<String>(
          label: 'Balans',
          helper: 'Izoh: $selected',
          segments: const [
            PosSegment(value: 'none', label: "Yo'q"),
            PosSegment(value: 'debt', label: 'Qarz'),
          ],
          selected: selected,
          onChanged: (v) => setState(() => selected = v),
        ),
      ),
    );
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.text("Yo'q")),
      isSemantics(
        label: "Yo'q",
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    await tester.tap(find.text('Qarz'));
    await tester.pumpAndSettle();
    expect(selected, 'debt');
    expect(find.text('Izoh: debt'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('date field: read-only, picks a date within the range', (
    tester,
  ) async {
    var value = DateTime(2026, 10, 15);
    await pumpPos(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 320,
          child: PosDateField(
            label: 'Sana',
            value: value,
            firstDate: DateTime(2000),
            lastDate: DateTime(2026, 10, 15),
            format: (d) => '${d.day}.${d.month}.${d.year}',
            onChanged: (d) => setState(() => value = d),
          ),
        ),
      ),
    );
    expect(find.text('15.10.2026'), findsOneWidget);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('3'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(value, DateTime(2026, 10, 3));
    expect(find.text('3.10.2026'), findsOneWidget);
  });
}
