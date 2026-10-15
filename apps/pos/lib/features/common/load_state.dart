import 'package:flutter/material.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Ro'yxat hali yuklanmoqda ([failed] `false`) yoki o'qishda xato. Xatoda
/// cheksiz aylanadigan belgi o'rniga tushunarli xabar va "Qayta urinish"
/// (audit UI-P2: lokal bazadan o'qish xatosi jim qolardi).
class LoadState extends StatelessWidget {
  const LoadState({required this.failed, required this.onRetry, super.key});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!failed) return const Center(child: CircularProgressIndicator());
    final l10n = AppLocalizations.of(context);
    return PosEmptyState(
      icon: Icons.error_outline,
      tone: PosTone.danger,
      title: l10n.loadFailedTitle,
      message: l10n.loadFailedMessage,
      action: PosButton(label: l10n.actionRetry, onPressed: onRetry),
    );
  }
}
