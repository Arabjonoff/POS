import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers.dart';

typedef _Row = ({String name, int price});

const List<_Row> _rows = [
  (name: 'Non', price: 500000),
  (name: 'Sut', price: 1200000),
];

List<PosTableColumn<_Row>> _columns() => [
  PosTableColumn(
    label: 'Name',
    flex: 3,
    sortable: true,
    cell: (_, r) => Text(r.name),
  ),
  PosTableColumn(
    label: 'Price',
    numeric: true,
    sortable: true,
    cell: (_, r) => Text(PosFormat.money(r.price, currency: "so'm")),
  ),
];

const List<PosDestination> _destinations = [
  PosDestination(icon: Icons.point_of_sale, label: 'Kassa', shortcut: 'F3'),
  PosDestination(icon: Icons.inventory_2_outlined, label: 'Tovarlar'),
  PosDestination(
    icon: Icons.people_outline,
    label: 'Mijozlar',
    badgeCount: 3,
  ),
];

Future<void> _pumpScaffold(
  WidgetTester tester,
  Size size,
  ValueChanged<int> onSelected,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: PosTheme.light(),
      home: PosResponsiveScaffold(
        destinations: _destinations,
        selectedIndex: 0,
        onDestinationSelected: onSelected,
        statusBar: const PosStatusBar(
          items: [PosStatusItem(icon: Icons.wifi, label: 'Online')],
        ),
        body: const Center(child: Text('Body')),
      ),
    ),
  );
}

void main() {
  group('PosDataTable', () {
    testWidgets('renders rows, numeric right aligned, row tap', (
      tester,
    ) async {
      _Row? tapped;
      await pumpPos(
        tester,
        SizedBox(
          width: 600,
          height: 400,
          child: PosDataTable<_Row>(
            columns: _columns(),
            rows: _rows,
            onRowTap: (r) => tapped = r,
          ),
        ),
      );
      expect(find.text('Non'), findsOneWidget);
      final price = tester.getRect(
        find.text("5${PosFormat.nbsp}000${PosFormat.nbsp}so'm"),
      );
      final table = tester.getRect(find.byType(PosDataTable<_Row>));
      expect(table.right - price.right, lessThan(24));

      await tester.tap(find.text('Sut'));
      expect(tapped?.name, 'Sut');
    });

    testWidgets('sort toggles direction on same column', (tester) async {
      final calls = <(int, bool)>[];
      await pumpPos(
        tester,
        SizedBox(
          width: 600,
          height: 400,
          child: PosDataTable<_Row>(
            columns: _columns(),
            rows: _rows,
            sortColumnIndex: 1,
            onSort: (i, {required ascending}) => calls.add((i, ascending)),
          ),
        ),
      );
      await tester.tap(find.text('Price'));
      await tester.tap(find.text('Name'));
      expect(calls, [(1, false), (0, true)]);
    });

    testWidgets('empty and loading states', (tester) async {
      await pumpPos(
        tester,
        SizedBox(
          width: 600,
          height: 400,
          child: PosDataTable<_Row>(
            columns: _columns(),
            rows: const [],
            empty: const Text('Nothing'),
          ),
        ),
      );
      expect(find.text('Nothing'), findsOneWidget);

      await pumpPos(
        tester,
        SizedBox(
          width: 600,
          height: 400,
          child: PosDataTable<_Row>(
            columns: _columns(),
            rows: _rows,
            loading: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Non'), findsNothing);
      expect(find.byType(PosSkeleton), findsNWidgets(15));
    });

    testWidgets('keyboard: focus row and press Enter', (tester) async {
      _Row? tapped;
      await pumpPos(
        tester,
        SizedBox(
          width: 600,
          height: 400,
          child: PosDataTable<_Row>(
            columns: _columns(),
            rows: _rows,
            onRowTap: (r) => tapped = r,
          ),
        ),
      );
      // Tab: Name sarlavhasi, Price sarlavhasi, 1-qator.
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(tapped?.name, 'Non');
    });

    testWidgets('shrinkWrap works inside unbounded height', (tester) async {
      await pumpPos(
        tester,
        SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: PosDataTable<_Row>(
              columns: _columns(),
              rows: _rows,
              shrinkWrap: true,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Sut'), findsOneWidget);
    });
  });

  group('PosStatusBar', () {
    testWidgets('shows icon and label for each item', (tester) async {
      await pumpPos(
        tester,
        const SizedBox(
          width: 800,
          child: PosStatusBar(
            items: [
              PosStatusItem(
                icon: Icons.wifi_off,
                label: 'Offline',
                tone: PosTone.warning,
              ),
              PosStatusItem(icon: Icons.sync, label: '12 queued'),
            ],
            trailing: Text('Ali'),
          ),
        ),
      );
      expect(find.text('Offline'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('12 queued'), findsOneWidget);
      expect(find.text('Ali'), findsOneWidget);
    });

    testWidgets('does not overflow on phone', (tester) async {
      await pumpPos(
        tester,
        const SizedBox(
          width: 390,
          child: PosStatusBar(
            items: [
              PosStatusItem(icon: Icons.wifi, label: 'Internet bor'),
              PosStatusItem(icon: Icons.print, label: 'Printer ulangan'),
              PosStatusItem(icon: Icons.schedule, label: 'Smena ochiq'),
              PosStatusItem(icon: Icons.sync, label: '12 ta yozuv navbatda'),
            ],
          ),
        ),
        size: const Size(390, 844),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('PosResponsiveScaffold', () {
    testWidgets('phone: bottom navigation, status bar on top', (tester) async {
      final selected = <int>[];
      await _pumpScaffold(tester, const Size(390, 844), selected.add);
      expect(find.byType(NavigationBar), findsOneWidget);
      final status = tester.getRect(find.byType(PosStatusBar));
      final body = tester.getRect(find.text('Body'));
      expect(status.top, lessThan(body.top));
      await tester.tap(find.text('Tovarlar'));
      expect(selected, [1]);
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('tablet portrait: rail, status bar at bottom', (tester) async {
      final selected = <int>[];
      await _pumpScaffold(tester, const Size(768, 1024), selected.add);
      expect(find.byType(NavigationBar), findsNothing);
      final nav = tester.getRect(find.text('Mijozlar'));
      expect(nav.left, lessThan(PosSizes.railWidth));
      final status = tester.getRect(find.byType(PosStatusBar));
      expect(status.bottom, 1024);
      await tester.tap(find.text('Mijozlar'));
      expect(selected, [2]);
    });

    testWidgets('desktop: side nav with shortcut and count', (tester) async {
      final selected = <int>[];
      await _pumpScaffold(tester, const Size(1440, 900), selected.add);
      expect(find.text('F3'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      final body = tester.getRect(find.text('Body'));
      expect(body.center.dx, greaterThan(PosSizes.sideNavWidth));
      await tester.tap(find.text('Tovarlar'));
      expect(selected, [1]);
    });

    testWidgets('desktop: navigate with keyboard', (tester) async {
      final selected = <int>[];
      await _pumpScaffold(tester, const Size(1440, 900), selected.add);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, [1]);
    });

    testWidgets('toast works inside scaffold', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: PosTheme.dark(),
          home: PosResponsiveScaffold(
            destinations: _destinations,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            body: Builder(
              builder: (context) => PosButton(
                label: 'Go',
                onPressed: () => showPosToast(context, message: 'Hi'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Hi'), findsOneWidget);
    });
  });
}
