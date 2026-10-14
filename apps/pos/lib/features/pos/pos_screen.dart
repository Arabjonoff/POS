import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_app/features/shift/open_shift_card.dart';
import 'package:pos_app/features/shift/shift_providers.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Kassa ekrani. To'liq maket T-042 da (`docs/specs/pos-screen.md`).
/// Smena ochilmaguncha savat o'rnida "Smenani oching" kartasi.
class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shift = ref.watch(currentShiftProvider);
    if (!shift.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (shift.value == null) return const OpenShiftCard();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(PosSpacing.m),
          child: Align(
            alignment: Alignment.centerRight,
            child: PosButton(
              label: l10n.shiftTitle,
              icon: Icons.receipt_long_outlined,
              variant: PosButtonVariant.secondary,
              size: PosButtonSize.s,
              onPressed: () => context.go('/pos/shift'),
            ),
          ),
        ),
        Expanded(
          child: PosEmptyState(
            icon: Icons.qr_code_scanner,
            title: l10n.posEmptyCart,
          ),
        ),
      ],
    );
  }
}
