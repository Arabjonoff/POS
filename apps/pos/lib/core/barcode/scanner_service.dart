import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ScanSource { hid, camera }

class ScanEvent {
  const ScanEvent({required this.code, required this.source, required this.at});

  final String code;
  final ScanSource source;
  final DateTime at;

  @override
  String toString() => 'ScanEvent($code, $source)';
}

/// Ro'yxatdan o'tgan ekran (stack: faqat eng yuqorisi hodisani oladi).
class ScanRegistration {
  ScanRegistration._(this._service, this.onScan, this.onTyping);

  final BarcodeScannerService _service;
  final ValueChanged<ScanEvent> onScan;

  /// Matn maydoni fokusda bo'lmaganda inson yozgan matn (masalan, kassa
  /// ekrani uni qidiruvga yo'naltiradi).
  final ValueChanged<String>? onTyping;

  void dispose() => _service._registrations.remove(this);
}

/// HID (klaviatura emulyatsiyasi) skanerini oddiy yozishdan ajratadi
/// (`docs/specs/barcode.md`):
///
/// - global klaviatura tinglovchisi — fokus qayerda bo'lishidan qat'i nazar;
/// - belgilar orasidagi interval ≤ [maxInterval], uzunlik ≥ [minLength],
///   oxiri Enter (yoki Tab) → [ScanEvent]; bu belgilar fokusdagi matn
///   maydoniga **tushmaydi**;
/// - sekin yozilgan matn (inson) bufer orqali fokusdagi matn maydoniga
///   qaytariladi (yoki [ScanRegistration.onTyping] ga);
/// - hech bir ekran ro'yxatdan o'tmagan bo'lsa (masalan, PIN ekrani) —
///   klaviaturaga umuman aralashmaydi.
class BarcodeScannerService {
  BarcodeScannerService({
    this.maxInterval = const Duration(milliseconds: 35),
    this.minLength = 4,
  });

  Duration maxInterval;
  final int minLength;

  final List<ScanRegistration> _registrations = [];
  final StreamController<ScanEvent> _events =
      StreamController<ScanEvent>.broadcast();
  final StringBuffer _buffer = StringBuffer();
  DateTime? _last;
  Timer? _flushTimer;
  bool _attached = false;

  /// Barcha shtrix-kod hodisalari (log, test).
  Stream<ScanEvent> get events => _events.stream;

  bool get hasListeners => _registrations.isNotEmpty;

  void attach() {
    if (_attached) return;
    HardwareKeyboard.instance.addHandler(handleKeyEvent);
    _attached = true;
  }

  void detach() {
    if (!_attached) return;
    HardwareKeyboard.instance.removeHandler(handleKeyEvent);
    _attached = false;
    _flushTimer?.cancel();
  }

  void dispose() {
    detach();
    unawaited(_events.close());
  }

  ScanRegistration register(
    ValueChanged<ScanEvent> onScan, {
    ValueChanged<String>? onTyping,
  }) {
    final registration = ScanRegistration._(this, onScan, onTyping);
    _registrations.add(registration);
    return registration;
  }

  /// Kamera skaneri (yoki boshqa manba) topgan kod.
  void emit(String code, {ScanSource source = ScanSource.camera}) =>
      _dispatch(ScanEvent(code: code.trim(), source: source, at: clock.now()));

  bool handleKeyEvent(KeyEvent event) {
    if (_registrations.isEmpty || event is KeyUpEvent) return false;
    final now = clock.now();
    final key = event.logicalKey;
    final last = _last;
    final fast = last != null && now.difference(last) <= maxInterval;

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.tab) {
      if (_buffer.isEmpty) return false;
      if (fast && _buffer.length >= minLength) {
        final code = _buffer.toString();
        _reset();
        _dispatch(ScanEvent(code: code, source: ScanSource.hid, at: now));
        return true;
      }
      // Qisqa yoki sekin — inson: matn qaytadi, Enter o'z ishini qiladi.
      _flushAsText();
      return false;
    }

    final char = event.character;
    final keyboard = HardwareKeyboard.instance;
    final printable =
        char != null &&
        char.isNotEmpty &&
        char.codeUnitAt(0) >= 0x20 &&
        char.codeUnitAt(0) != 0x7f;
    if (!printable ||
        keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed) {
      // Tezkor tugmalar, strelkalar, F-tugmalar — o'tib ketadi.
      if (_buffer.isNotEmpty) _flushAsText();
      return false;
    }

    if (_buffer.isNotEmpty && !fast) _flushAsText();
    _buffer.write(char);
    _last = now;
    _flushTimer?.cancel();
    // Skaner tugash belgisini interval ichida yuboradi; kelmasa — inson.
    _flushTimer = Timer(maxInterval * 2, () {
      if (_buffer.isNotEmpty) _flushAsText();
    });
    return true;
  }

  void _reset() {
    _buffer.clear();
    _last = null;
    _flushTimer?.cancel();
  }

  void _dispatch(ScanEvent event) {
    if (event.code.isEmpty) return;
    _events.add(event);
    if (_registrations.isNotEmpty) _registrations.last.onScan(event);
  }

  /// Bufer — inson yozuvi: fokusdagi matn maydoniga (kursor o'rniga) yoki
  /// ekranning [ScanRegistration.onTyping] iga.
  void _flushAsText() {
    final text = _buffer.toString();
    _reset();
    if (text.isEmpty) return;
    final context = FocusManager.instance.primaryFocus?.context;
    final editable = context?.findAncestorStateOfType<EditableTextState>();
    if (editable != null && !editable.widget.readOnly) {
      final value = editable.textEditingValue;
      final selection = value.selection.isValid
          ? value.selection
          : TextSelection.collapsed(offset: value.text.length);
      editable.userUpdateTextEditingValue(
        TextEditingValue(
          text: value.text.replaceRange(selection.start, selection.end, text),
          selection: TextSelection.collapsed(
            offset: selection.start + text.length,
          ),
        ),
        SelectionChangedCause.keyboard,
      );
      return;
    }
    if (_registrations.isNotEmpty) _registrations.last.onTyping?.call(text);
  }
}

final scannerServiceProvider = Provider<BarcodeScannerService>((ref) {
  final service = BarcodeScannerService()..attach();
  ref.onDispose(service.dispose);
  return service;
});

/// Ekran skaner hodisalarini oladi — faqat ko'rinib turganda (yashirin
/// bo'limlar `TickerMode` o'chiq), [enabled] bo'lsa va eng yuqori bo'lsa.
/// Ekran o'z oynasini ochganda [enabled] = false — oyna klaviaturani o'zi
/// oladi (raqamlar skaner buferiga tushmaydi).
class ScanListener extends ConsumerStatefulWidget {
  const ScanListener({
    required this.onScan,
    required this.child,
    this.onTyping,
    this.enabled = true,
    super.key,
  });

  final ValueChanged<ScanEvent> onScan;
  final ValueChanged<String>? onTyping;
  final bool enabled;
  final Widget child;

  @override
  ConsumerState<ScanListener> createState() => _ScanListenerState();
}

class _ScanListenerState extends ConsumerState<ScanListener> {
  ScanRegistration? _registration;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ScanListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _sync();
  }

  void _sync() {
    final active = widget.enabled && TickerMode.valuesOf(context).enabled;
    if (active && _registration == null) {
      _registration = ref
          .read(scannerServiceProvider)
          .register(
            (e) => widget.onScan(e),
            onTyping: (t) => widget.onTyping?.call(t),
          );
    } else if (!active && _registration != null) {
      _registration!.dispose();
      _registration = null;
    }
  }

  @override
  void dispose() {
    _registration?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
