import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/customers/customer_directory.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets(
    'list read error: message and retry instead of an endless spinner',
    (tester) async {
      var attempts = 0;
      await pumpPosApp(
        tester,
        overrides: [
          customersProvider.overrideWith((ref) {
            attempts++;
            return attempts == 1
                ? Stream.error(StateError('disk'))
                : Stream.value(const []);
          }),
        ],
      );
      await tapNav(tester, 'Mijozlar');
      expect(find.text("Ma'lumotni o'qib bo'lmadi"), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('Qayta urinish'));
      await tester.pumpAndSettle();
      expect(find.text("Ma'lumotni o'qib bo'lmadi"), findsNothing);
      expect(attempts, 2);
    },
  );
}
