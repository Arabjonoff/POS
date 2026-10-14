import 'package:flutter/material.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Kassa ekrani. To'liq maket T-042 da (`docs/specs/pos-screen.md`).
class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PosEmptyState(
      icon: Icons.qr_code_scanner,
      title: l10n.posEmptyCart,
    );
  }
}
