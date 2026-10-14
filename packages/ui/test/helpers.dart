import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_ui/pos_ui.dart';

/// Vidjetni POS mavzusi bilan ekranga chiqaradi.
Future<void> pumpPos(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  Size size = const Size(1024, 768),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? PosTheme.dark() : PosTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}
