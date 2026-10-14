import 'package:flutter/material.dart';
import 'package:pos_app/features/common/section_page.dart';
import 'package:pos_app/features/settings/language_picker.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Sozlamalar. Hozircha — til; printer, avtomatik qulflash va boshqalar
/// tegishli vazifalarda qo'shiladi.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    final compact = PosWindowSize.of(context).isCompact;
    final padding = compact ? PosSpacing.l : PosSpacing.xl;
    return SectionPage(
      title: l10n.navSettings,
      child: ListView(
        padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
        children: [
          Align(
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
                      child: Text(
                        l10n.settingsLanguage,
                        style: PosTypography.h3.copyWith(color: p.text),
                      ),
                    ),
                    const LanguagePicker(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
