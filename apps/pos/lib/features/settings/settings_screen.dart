import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/scanner/scanner_settings.dart';
import 'package:pos_app/app/session/auto_lock.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/features/common/section_page.dart';
import 'package:pos_app/features/printing/printer_settings_panel.dart';
import 'package:pos_app/features/settings/language_picker.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Sozlamalar: til, avtomatik qulflash, skaner, chek printeri, qulflash.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final compact = PosWindowSize.of(context).isCompact;
    final padding = compact ? PosSpacing.l : PosSpacing.xl;
    return SectionPage(
      title: l10n.navSettings,
      child: ListView(
        padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
        children: [
          _SettingsCard(
            title: l10n.settingsLanguage,
            child: const LanguagePicker(),
          ),
          const SizedBox(height: PosSpacing.l),
          _SettingsCard(
            title: l10n.settingsAutoLock,
            subtitle: l10n.settingsAutoLockHelper,
            child: const _AutoLockPicker(),
          ),
          const SizedBox(height: PosSpacing.l),
          _SettingsCard(
            title: l10n.settingsScanner,
            child: const _ScannerSettingsPicker(),
          ),
          const SizedBox(height: PosSpacing.l),
          _SettingsCard(
            title: l10n.settingsPrinter,
            subtitle: l10n.settingsPrinterHelper,
            child: const PrinterSettingsPanel(),
          ),
          const SizedBox(height: PosSpacing.l),
          Align(
            alignment: Alignment.centerLeft,
            child: PosButton(
              label: l10n.actionLock,
              icon: Icons.lock_outline,
              variant: PosButtonVariant.secondary,
              onPressed: () => ref.read(sessionProvider.notifier).lock(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: PosCard(
          padding: const EdgeInsets.all(PosSpacing.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PosSpacing.s,
                  PosSpacing.s,
                  PosSpacing.s,
                  PosSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: PosTypography.h3.copyWith(color: p.text),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: PosTypography.small.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _AutoLockPicker extends ConsumerWidget {
  const _AutoLockPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(autoLockMinutesProvider);
    final p = PosPalette.of(context);
    return Column(
      children: [
        for (final minutes in autoLockOptions)
          PosListTile(
            leading: Icon(
              minutes == current
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: minutes == current ? p.primaryText : null,
            ),
            title: minutes == 0
                ? l10n.settingsAutoLockOff
                : l10n.settingsAutoLockMinutes(minutes),
            selected: minutes == current,
            onTap: () => unawaited(
              ref.read(autoLockMinutesProvider.notifier).select(minutes),
            ),
          ),
      ],
    );
  }
}

class _ScannerSettingsPicker extends ConsumerWidget {
  const _ScannerSettingsPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    final settings = ref.watch(scannerSettingsProvider);
    final controller = ref.read(scannerSettingsProvider.notifier);
    String speedLabel(int ms) => switch (ms) {
      35 => l10n.settingsScannerSpeedNormal,
      60 => l10n.settingsScannerSpeedSlow,
      _ => l10n.settingsScannerSpeedVerySlow,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PosListTile(
          leading: const Icon(Icons.volume_up_outlined),
          title: l10n.settingsScannerSound,
          trailing: Switch(
            value: settings.sound,
            onChanged: (v) => unawaited(controller.setSound(enabled: v)),
          ),
          onTap: () => unawaited(controller.setSound(enabled: !settings.sound)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PosSpacing.l,
            PosSpacing.s,
            PosSpacing.l,
            0,
          ),
          child: Text(
            l10n.settingsScannerSpeed,
            style: PosTypography.smallStrong.copyWith(color: p.textSecondary),
          ),
        ),
        for (final ms in ScannerSettings.intervalOptions)
          PosListTile(
            leading: Icon(
              ms == settings.intervalMs
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: ms == settings.intervalMs ? p.primaryText : null,
            ),
            title: speedLabel(ms),
            selected: ms == settings.intervalMs,
            onTap: () => unawaited(controller.setInterval(ms)),
          ),
      ],
    );
  }
}
