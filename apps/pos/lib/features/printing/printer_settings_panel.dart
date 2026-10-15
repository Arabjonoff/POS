import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/printing/escpos.dart';
import 'package:pos_app/features/printing/printer_service.dart';
import 'package:pos_app/features/printing/printer_settings.dart';
import 'package:pos_app/features/printing/receipt.dart';
import 'package:pos_app/features/printing/receipt_sample.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Sozlamalar → Chek printeri: ulanish, manzil, qog'oz, harflar jadvali,
/// avtomatik chek, nusxalar, pul qutisi; test chek va pul qutisini ochish.
class PrinterSettingsPanel extends ConsumerStatefulWidget {
  const PrinterSettingsPanel({super.key});

  @override
  ConsumerState<PrinterSettingsPanel> createState() =>
      _PrinterSettingsPanelState();
}

class _PrinterSettingsPanelState extends ConsumerState<PrinterSettingsPanel> {
  final _address = TextEditingController();
  final _codePage = TextEditingController();
  bool _addressLoaded = false;
  bool _busy = false;
  bool _advanced = false;
  Timer? _addressSave;

  @override
  void dispose() {
    _addressSave?.cancel();
    _address.dispose();
    _codePage.dispose();
    super.dispose();
  }

  /// Manzil har harfda emas, yozish to'xtagach saqlanadi (har saqlash
  /// printerni qayta tekshiradi; audit PRN-B16).
  void _addressChanged(PrinterSettings settings, String value) {
    _addressSave?.cancel();
    _addressSave = Timer(
      const Duration(milliseconds: 600),
      () => unawaited(_save(settings.copyWith(address: value.trim()))),
    );
  }

  Future<void> _save(PrinterSettings settings) =>
      ref.read(printerSettingsProvider.notifier).save(settings);

  Future<void> _run(
    Future<PrintOutcome> Function(PrinterService) action,
  ) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final outcome = await action(ref.read(printerServiceProvider));
    if (!mounted) return;
    setState(() => _busy = false);
    showPosToast(
      context,
      message: switch (outcome) {
        PrintOutcome.printed => l10n.printerSent,
        PrintOutcome.failed => l10n.printerFailed,
        PrintOutcome.notConfigured => l10n.printerNotConfigured,
      },
      tone: outcome == PrintOutcome.printed ? PosTone.success : PosTone.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    final settings = ref.watch(printerSettingsProvider).value;
    if (settings == null) return const SizedBox.shrink();
    if (!_addressLoaded && settings.connection == PrinterConnection.network) {
      _address.text = settings.address;
      _addressLoaded = true;
    }

    Widget label(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        PosSpacing.s,
        PosSpacing.m,
        PosSpacing.s,
        PosSpacing.xs,
      ),
      child: Text(
        text,
        style: PosTypography.smallStrong.copyWith(color: p.textSecondary),
      ),
    );

    Widget choices<T>(
      List<(T, String)> options,
      T selected,
      ValueChanged<T> onSelect,
    ) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: PosSpacing.s),
      child: Wrap(
        spacing: PosSpacing.s,
        runSpacing: PosSpacing.s,
        children: [
          for (final (value, text) in options)
            PosButton(
              key: ValueKey('printer-$value'),
              label: text,
              size: PosButtonSize.s,
              variant: value == selected
                  ? PosButtonVariant.primary
                  : PosButtonVariant.secondary,
              onPressed: () => onSelect(value),
            ),
        ],
      ),
    );

    Widget toggle(
      String title,
      IconData icon, {
      required bool value,
      required ValueChanged<bool> onChanged,
    }) => PosListTile(
      leading: Icon(icon),
      title: title,
      trailing: Switch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );

    final windows = ref.watch(windowsPrintingProvider);
    final connection = settings.connection;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label(l10n.printerConnection),
        choices(
          [
            (PrinterConnection.none, l10n.printerNone),
            (PrinterConnection.network, l10n.printerNetwork),
            if (windows || connection == PrinterConnection.windows)
              (PrinterConnection.windows, l10n.printerWindows),
          ],
          connection,
          (c) {
            if (c == connection) return;
            _address.clear();
            _addressLoaded = true;
            unawaited(_save(settings.copyWith(connection: c, address: '')));
          },
        ),
        if (connection == PrinterConnection.network) ...[
          const SizedBox(height: PosSpacing.m),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PosSpacing.s),
            child: PosTextField(
              key: const ValueKey('printer-address'),
              controller: _address,
              label: l10n.printerAddress,
              hint: l10n.printerAddressHint,
              keyboardType: TextInputType.url,
              onChanged: (v) => _addressChanged(settings, v),
              onSubmitted: (v) {
                _addressSave?.cancel();
                unawaited(_save(settings.copyWith(address: v.trim())));
              },
            ),
          ),
        ],
        if (connection == PrinterConnection.windows)
          ..._systemPrinters(
            l10n,
            settings,
          ),
        if (connection != PrinterConnection.none) ...[
          label(l10n.printerWidth),
          choices(
            [
              (PaperWidth.mm58, l10n.printerWidthMm(58)),
              (PaperWidth.mm80, l10n.printerWidthMm(80)),
              (PaperWidth.mm80narrow, l10n.printerWidthNarrow),
            ],
            settings.width,
            (w) => unawaited(_save(settings.copyWith(width: w))),
          ),
          label(l10n.printerEncoding),
          choices(
            [
              (PrinterEncoding.cp866, l10n.printerEncodingCp866),
              (PrinterEncoding.utf8, l10n.printerEncodingUtf8),
            ],
            settings.encoding,
            (e) => unawaited(_save(settings.copyWith(encoding: e))),
          ),
          label(l10n.printerCopies),
          choices(
            [
              for (var n = 1; n <= PrinterSettings.maxCopies; n++) (n, '$n'),
            ],
            settings.copies,
            (n) => unawaited(_save(settings.copyWith(copies: n))),
          ),
          const SizedBox(height: PosSpacing.s),
          toggle(
            l10n.printerAutoPrint,
            Icons.receipt_long_outlined,
            value: settings.autoPrint,
            onChanged: (v) => unawaited(_save(settings.copyWith(autoPrint: v))),
          ),
          toggle(
            l10n.printerDrawer,
            Icons.point_of_sale_outlined,
            value: settings.openDrawer,
            onChanged: (v) =>
                unawaited(_save(settings.copyWith(openDrawer: v))),
          ),
          PosListTile(
            key: const ValueKey('printer-advanced'),
            leading: const Icon(Icons.tune),
            title: l10n.printerAdvanced,
            trailing: Icon(_advanced ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _advanced = !_advanced),
          ),
          if (_advanced) ..._advancedSettings(l10n, settings, toggle, choices),
          const SizedBox(height: PosSpacing.s),
          Padding(
            padding: const EdgeInsets.all(PosSpacing.s),
            child: Wrap(
              spacing: PosSpacing.s,
              runSpacing: PosSpacing.s,
              children: [
                PosButton(
                  key: const ValueKey('printer-test'),
                  label: l10n.printerTestReceipt,
                  icon: Icons.print_outlined,
                  loading: _busy,
                  onPressed: settings.configured
                      ? () => unawaited(
                          _run(
                            (s) async => s.printTest(
                              sample: (await ref.read(
                                receiptPreviewDataProvider.future,
                              )).data,
                            ),
                          ),
                        )
                      : null,
                ),
                PosButton(
                  label: l10n.printerOpenDrawer,
                  icon: Icons.point_of_sale_outlined,
                  variant: PosButtonVariant.secondary,
                  onPressed: settings.configured && !_busy
                      ? () => unawaited(_run((s) => s.openDrawer()))
                      : null,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _advancedSettings(
    AppLocalizations l10n,
    PrinterSettings settings,
    Widget Function(
      String title,
      IconData icon, {
      required bool value,
      required ValueChanged<bool> onChanged,
    })
    toggle,
    Widget Function<T>(List<(T, String)>, T, ValueChanged<T>) choices,
  ) {
    if (_codePage.text.isEmpty) _codePage.text = '${settings.codePage}';
    return [
      if (settings.encoding == PrinterEncoding.cp866)
        Padding(
          padding: const EdgeInsets.all(PosSpacing.s),
          child: PosTextField(
            key: const ValueKey('printer-code-page'),
            controller: _codePage,
            label: l10n.printerCodePage,
            helper: l10n.printerCodePageHint,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            onChanged: (v) {
              final n = int.tryParse(v);
              if (n != null && n <= 255) {
                unawaited(_save(settings.copyWith(codePage: n)));
              }
            },
          ),
        ),
      toggle(
        l10n.printerCancelKanji,
        Icons.translate,
        value: settings.cancelKanji,
        onChanged: (v) => unawaited(_save(settings.copyWith(cancelKanji: v))),
      ),
      toggle(
        l10n.printerCut,
        Icons.content_cut,
        value: settings.cut,
        onChanged: (v) => unawaited(_save(settings.copyWith(cut: v))),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          PosSpacing.s,
          PosSpacing.s,
          PosSpacing.s,
          PosSpacing.xs,
        ),
        child: Text(
          l10n.printerFeed,
          style: PosTypography.smallStrong.copyWith(
            color: PosPalette.of(context).textSecondary,
          ),
        ),
      ),
      choices(
        [
          for (final n in const [2, 3, 4, 5, 6]) (n, '$n'),
        ],
        settings.feedLines,
        (n) => unawaited(_save(settings.copyWith(feedLines: n))),
      ),
    ];
  }

  List<Widget> _systemPrinters(
    AppLocalizations l10n,
    PrinterSettings settings,
  ) {
    final p = PosPalette.of(context);
    final printers = ref.watch(systemPrintersProvider);
    if (printers.isEmpty) {
      return [
        PosEmptyState(
          icon: Icons.print_disabled_outlined,
          title: l10n.printerNoSystemPrinters,
        ),
      ];
    }
    return [
      const SizedBox(height: PosSpacing.s),
      for (final name in printers)
        PosListTile(
          leading: Icon(
            name == settings.address
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: name == settings.address ? p.primaryText : null,
          ),
          title: name,
          selected: name == settings.address,
          onTap: () => unawaited(_save(settings.copyWith(address: name))),
        ),
    ];
  }
}
