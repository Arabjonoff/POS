import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/locale.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Til tanlash ro'yxati. Har til o'z nomi bilan ko'rsatiladi ("O'zbekcha",
/// "Ўзбекча", "Русский") — kassir boshqa tilda ham o'z tilini topadi.
class LanguagePicker extends ConsumerWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final p = PosPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final locale in AppLocales.all)
          PosListTile(
            leading: Icon(
              locale == current
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: locale == current ? p.primaryText : null,
            ),
            title: lookupAppLocalizations(locale).languageName,
            selected: locale == current,
            onTap: () =>
                unawaited(ref.read(localeProvider.notifier).select(locale)),
          ),
      ],
    );
  }
}
