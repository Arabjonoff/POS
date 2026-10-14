import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/barcode/scanner_service.dart';

const Map<String, LogicalKeyboardKey> _keys = {
  '0': LogicalKeyboardKey.digit0,
  '1': LogicalKeyboardKey.digit1,
  '2': LogicalKeyboardKey.digit2,
  '3': LogicalKeyboardKey.digit3,
  '4': LogicalKeyboardKey.digit4,
  '5': LogicalKeyboardKey.digit5,
  '6': LogicalKeyboardKey.digit6,
  '7': LogicalKeyboardKey.digit7,
  '8': LogicalKeyboardKey.digit8,
  '9': LogicalKeyboardKey.digit9,
  'a': LogicalKeyboardKey.keyA,
  'b': LogicalKeyboardKey.keyB,
  'c': LogicalKeyboardKey.keyC,
};

/// Belgilarni [gap] oraliq bilan "yozadi" (skaner yoki inson).
Future<void> type(
  WidgetTester tester,
  String text, {
  required Duration gap,
  LogicalKeyboardKey? end = LogicalKeyboardKey.enter,
}) async {
  for (final ch in text.split('')) {
    await tester.sendKeyEvent(_keys[ch]!);
    await tester.pump(gap);
  }
  if (end != null) await tester.sendKeyEvent(end);
  await tester.pump(const Duration(milliseconds: 200));
}

const Duration scannerGap = Duration(milliseconds: 10);
const Duration humanGap = Duration(milliseconds: 150);

class _Harness extends StatefulWidget {
  const _Harness({required this.onScan, this.onTyping, this.withField = true});

  final ValueChanged<ScanEvent> onScan;
  final ValueChanged<String>? onTyping;
  final bool withField;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final controller = TextEditingController();
  String? submitted;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: ScanListener(
        onScan: widget.onScan,
        onTyping: widget.onTyping,
        child: widget.withField
            ? TextField(
                controller: controller,
                autofocus: true,
                onSubmitted: (v) => submitted = v,
              )
            : const Focus(autofocus: true, child: SizedBox()),
      ),
    ),
  );
}

void main() {
  late List<ScanEvent> scans;
  late BarcodeScannerService service;

  setUp(() => scans = []);

  Future<_HarnessState> pump(
    WidgetTester tester, {
    bool withField = true,
    ValueChanged<String>? onTyping,
  }) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    service = container.read(scannerServiceProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _Harness(
          onScan: scans.add,
          onTyping: onTyping,
          withField: withField,
        ),
      ),
    );
    await tester.pump();
    return tester.state<_HarnessState>(find.byType(_Harness));
  }

  testWidgets('13 chars 10 ms apart + Enter → one scan, nothing typed', (
    tester,
  ) async {
    final h = await pump(tester);
    await type(tester, '4780001000013', gap: scannerGap);
    expect(scans.map((e) => e.code), ['4780001000013']);
    expect(scans.single.source, ScanSource.hid);
    expect(h.controller.text, isEmpty);
    expect(h.submitted, isNull, reason: 'Enter was the scanner terminator');
  });

  testWidgets('13 chars 150 ms apart → ordinary text in the focused field', (
    tester,
  ) async {
    final h = await pump(tester);
    await type(tester, '4780001000013', gap: humanGap, end: null);
    expect(scans, isEmpty);
    expect(h.controller.text, '4780001000013');
  });

  testWidgets('slow typing then Enter submits the field normally', (
    tester,
  ) async {
    final h = await pump(tester);
    await type(tester, 'abc', gap: humanGap);
    expect(scans, isEmpty);
    expect(h.controller.text, 'abc');
  });

  testWidgets('fast but too short (< 4) is not a scan', (tester) async {
    final h = await pump(tester);
    await type(tester, '123', gap: scannerGap);
    expect(scans, isEmpty);
    expect(h.controller.text, '123');
  });

  testWidgets('Tab also terminates a scan', (tester) async {
    await pump(tester);
    await type(
      tester,
      '96385074',
      gap: scannerGap,
      end: LogicalKeyboardKey.tab,
    );
    expect(scans.map((e) => e.code), ['96385074']);
  });

  testWidgets('scan in the middle of human typing keeps both apart', (
    tester,
  ) async {
    final h = await pump(tester);
    await type(tester, 'ab', gap: humanGap, end: null);
    await type(tester, '12345678', gap: scannerGap);
    expect(scans.map((e) => e.code), ['12345678']);
    expect(h.controller.text, 'ab');
  });

  testWidgets('no text field focused: human typing goes to onTyping', (
    tester,
  ) async {
    final typed = <String>[];
    await pump(tester, withField: false, onTyping: typed.add);
    await type(tester, 'ab', gap: humanGap, end: null);
    expect(typed.join(), 'ab');
    await type(tester, '12345678', gap: scannerGap);
    expect(scans.map((e) => e.code), ['12345678']);
  });

  testWidgets('without registered screens the keyboard is untouched', (
    tester,
  ) async {
    final keys = <String>[];
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(scannerServiceProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Focus(
            autofocus: true,
            onKeyEvent: (_, e) {
              if (e is KeyDownEvent && e.character != null) {
                keys.add(e.character!);
              }
              return KeyEventResult.handled;
            },
            child: const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pump();
    await type(tester, '1234', gap: scannerGap, end: null);
    expect(keys, ['1', '2', '3', '4']);
  });

  testWidgets('Ctrl shortcuts pass through', (tester) async {
    final h = await pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump(const Duration(milliseconds: 100));
    expect(h.controller.text, isEmpty);
    expect(scans, isEmpty);
  });

  testWidgets('only the top screen receives scans; hidden screens none', (
    tester,
  ) async {
    final lower = <String>[];
    final upper = <String>[];
    final container = ProviderContainer();
    addTearDown(container.dispose);
    Widget app({required bool upperVisible}) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ScanListener(
          onScan: (e) => lower.add(e.code),
          child: TickerMode(
            enabled: upperVisible,
            child: ScanListener(
              onScan: (e) => upper.add(e.code),
              child: const Focus(autofocus: true, child: SizedBox()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(app(upperVisible: true));
    await tester.pump();
    await type(tester, '11111111', gap: scannerGap);
    expect(upper, ['11111111']);
    expect(lower, isEmpty);

    await tester.pumpWidget(app(upperVisible: false));
    await type(tester, '22222222', gap: scannerGap);
    expect(lower, ['22222222']);
  });

  testWidgets('camera codes go through the same path', (tester) async {
    await pump(tester);
    service.emit(' 4780001000013 ');
    expect(scans.single.code, '4780001000013');
    expect(scans.single.source, ScanSource.camera);
  });
}
