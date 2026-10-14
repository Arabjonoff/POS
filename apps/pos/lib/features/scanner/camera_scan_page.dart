import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos_app/core/barcode/scanner_service.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Kamera skaneri faqat telefon/planshetda (Windows — HID skaner).
bool get cameraScanAvailable =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Kamera bilan skanerlash: topilgan kod skaner xizmati orqali hozirgi
/// ekranga boradi (HID bilan bir xil yo'l), sahifa yopiladi.
Future<void> openCameraScanner(BuildContext context) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const CameraScanPage()),
    );

class CameraScanPage extends ConsumerStatefulWidget {
  const CameraScanPage({super.key});

  @override
  ConsumerState<CameraScanPage> createState() => _CameraScanPageState();
}

class _CameraScanPageState extends ConsumerState<CameraScanPage> {
  final _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.itf14,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (code == null || code.isEmpty) return;
    _done = true;
    final service = ref.read(scannerServiceProvider);
    Navigator.of(context).pop();
    // Sahifa yopilgach — hodisa ekranning o'ziga (u stack tepasiga qaytdi).
    WidgetsBinding.instance.addPostFrameCallback((_) => service.emit(code));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanCamera)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => PosEmptyState(
              icon: Icons.no_photography_outlined,
              title: l10n.scanCameraDenied,
              tone: PosTone.danger,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(PosSpacing.xl),
              child: PosToast(message: l10n.scanCameraHint),
            ),
          ),
          Center(
            child: Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: PosRadius.controlAll,
                border: Border.all(color: p.onPrimary, width: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
