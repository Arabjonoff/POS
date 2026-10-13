import 'package:flutter_test/flutter_test.dart';
import 'package:pos_ui_widgetbook/catalog.dart';
import 'package:pos_ui_widgetbook/main.dart';

void main() {
  test('catalog is not empty', () {
    expect(catalog, isNotEmpty);
  });

  testWidgets('widgetbook app builds', (tester) async {
    await tester.pumpWidget(const PosWidgetbook());
    await tester.pump();
    expect(find.byType(PosWidgetbook), findsOneWidget);
  });
}
