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
      // 5 qator × 2 ustun.
      expect(find.byType(PosSkeleton), findsNWidgets(10));
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

    testWidgets('narrow screen scrolls horizontally instead of squeezing', (
      tester,
    ) async {
      await pumpPos(
        tester,
        SizedBox(
          width: 200,
          height: 300,
          child: PosDataTable<_Row>(columns: _columns(), rows: _rows),
        ),
        size: const Size(390, 844),
      );
      expect(tester.takeException(), isNull);
      final scroll = tester.widget<SingleChildScrollView>(
        find.descendant(
          of: find.byType(PosDataTable<_Row>),
          matching: find.byType(SingleChildScrollView),
        ),
      );
      expect(scroll.scrollDirection, Axis.horizontal);
      // Ustun kengligi minWidth dan kichik emas.
      expect(
        tester.getSize(find.text('Name')).width,
        greaterThan(0),
      );
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
      // Pastki panel ekran pastida.
      expect(tester.getRect(find.text('Tovarlar')).top, greaterThan(760));
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
      expect(tester.getRect(find.text('Mijozlar')).top, lessThan(400));
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

    testWidgets('desktop: collapsible 64 dp nav, toggle pins it open', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final selected = <int>[];
      var expanded = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: PosTheme.light(),
          home: StatefulBuilder(
            builder: (context, setState) => PosResponsiveScaffold(
              destinations: _destinations,
              selectedIndex: 0,
              onDestinationSelected: selected.add,
              navExpanded: expanded,
              onNavExpandedChanged: (v) => setState(() => expanded = v),
              expandNavTooltip: 'Open',
              collapseNavTooltip: 'Close',
              railFooter: const Text('A'),
              body: const Center(child: Text('Body')),
            ),
          ),
        ),
      );
      // Yig'ilgan: ikonlar, nom va tezkor tugma — tooltip.
      expect(find.byTooltip('Kassa · F3'), findsOneWidget);
      expect(find.text('Tovarlar'), findsNothing);
      expect(find.byTooltip('Tovarlar'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      final item = tester.getSize(find.byTooltip('Tovarlar'));
      expect(item.width, greaterThanOrEqualTo(PosSizes.touchMin));
      expect(item.height, greaterThanOrEqualTo(PosSizes.touchMin));
      await tester.tap(find.byTooltip('Tovarlar'));
      expect(selected, [1]);
      // Badge yig'ilgan menyuda ham ko'rinadi.
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.byTooltip('Open'));
      await tester.pumpAndSettle();
      expect(expanded, isTrue);
      expect(find.text('Tovarlar'), findsOneWidget);
      expect(
        tester.getRect(find.text('Body')).center.dx,
        greaterThan(PosSizes.sideNavWidth),
      );
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(expanded, isFalse);
      expect(find.text('Tovarlar'), findsNothing);
    });

    testWidgets('desktop status bar: 48 dp tappable items', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: PosTheme.light(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: PosStatusBar(
                items: [
                  PosStatusItem(
                    icon: Icons.wifi_off,
                    label: 'Offline',
                    tone: PosTone.danger,
                    onTap: () => taps++,
                  ),
                  const PosStatusItem(icon: Icons.print, label: 'Printer'),
                ],
              ),
            ),
          ),
        ),
      );
      final target = find.ancestor(
        of: find.text('Offline'),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(target).height, PosSizes.touchMin);
      await tester.tap(find.text('Offline'));
      expect(taps, 1);
      // Bosilmaydigan yozuvda InkWell yo'q.
      expect(
        find.ancestor(of: find.text('Printer'), matching: find.byType(InkWell)),
        findsNothing,
      );
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
