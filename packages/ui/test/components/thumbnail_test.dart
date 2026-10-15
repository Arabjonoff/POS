import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers.dart';

void main() {
  testWidgets('no image → placeholder icon at the requested size', (
    tester,
  ) async {
    await pumpPos(tester, const PosThumbnail(size: PosSizes.thumbM));
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(tester.getSize(find.byType(PosThumbnail)), const Size(56, 56));
  });

  testWidgets('unreadable image → placeholder, no crash', (tester) async {
    await pumpPos(
      tester,
      PosThumbnail(image: MemoryImage(Uint8List.fromList([1, 2, 3]))),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
