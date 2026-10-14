import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/printing/escpos.dart';
import 'package:pos_app/features/printing/printer_service.dart';
import 'package:pos_app/features/printing/printer_settings.dart';
import 'package:pos_app/features/printing/receipt.dart';
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
  bool _addressLoaded = false;
  bool _busy = false;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
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
              onChanged: (v) =>
                  unawaited(_save(settings.copyWith(address: v.trim()))),
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
              for (final w in PaperWidth.values)
                (w, l10n.printerWidthMm(w == PaperWidth.mm58 ? 58 : 80)),
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
          const SizedBox(height: PosSpacing.s),
          Padding(
            padding: const EdgeInsets.all(PosSpacing.s),
            child: Wrap(
              spacing: PosSpacing.s,
              runSpacing: PosSpacing.s,
              children: [
                PosButton(
                  key: const ValueKey('printer-test'),
                  label: l10n.printerTest,
                  icon: Icons.print_outlined,
                  loading: _busy,
                  onPressed: settings.configured
                      ? () => unawaited(_run((s) => s.printTest()))
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
