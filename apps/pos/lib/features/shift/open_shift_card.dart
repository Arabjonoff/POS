import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/features/common/money_input.dart';
import 'package:pos_app/features/shift/shift_providers.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Smena yopiq: savat o'rnida "Smenani oching" kartasi (`pos-screen.md`).
/// Boshlang'ich naqd — oldingi smenada sanalgan summa taklif qilinadi.
class OpenShiftCard extends ConsumerStatefulWidget {
  const OpenShiftCard({super.key});

  @override
  ConsumerState<OpenShiftCard> createState() => _OpenShiftCardState();
}

class _OpenShiftCardState extends ConsumerState<OpenShiftCard> {
  int _cash = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_suggest());
  }

  Future<void> _suggest() async {
    final device = ref.read(sessionProvider).device;
    if (device == null) return;
    final cash = await ref
        .read(shiftServiceProvider)
        .suggestedOpeningCash(device.id);
    if (mounted) setState(() => _cash = cash);
  }

  Future<void> _open() async {
    final session = ref.read(sessionProvider);
    final device = session.device;
    final user = session.user;
    if (device == null || user == null || _busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(shiftServiceProvider)
          .open(
            deviceId: device.id,
            storeId: device.storeId,
            cashierId: user.id,
            openingCashTiyin: _cash,
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(PosSpacing.l),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: PosCard(
            padding: const EdgeInsets.all(PosSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_clock_outlined,
                  size: PosSizes.iconXl + 8,
                  color: p.primaryText,
                ),
                const SizedBox(height: PosSpacing.m),
                Text(
                  l10n.shiftOpenTitle,
                  textAlign: TextAlign.center,
                  style: PosTypography.h2.copyWith(color: p.text),
                ),
                const SizedBox(height: PosSpacing.xs),
                Text(
                  l10n.shiftOpenMessage,
                  textAlign: TextAlign.center,
                  style: PosTypography.body.copyWith(color: p.textSecondary),
                ),
                const SizedBox(height: PosSpacing.l),
                Text(
                  l10n.shiftOpeningCash,
                  style: PosTypography.smallStrong.copyWith(color: p.text),
                ),
                const SizedBox(height: PosSpacing.xs),
                MoneyInput(
                  valueTiyin: _cash,
                  onChanged: (v) => setState(() => _cash = v),
                  onSubmit: () => unawaited(_open()),
                ),
                const SizedBox(height: PosSpacing.l),
                PosButton(
                  label: l10n.shiftOpenAction,
                  icon: Icons.play_arrow_rounded,
                  size: PosButtonSize.l,
                  expand: true,
                  loading: _busy,
                  shortcut: 'Enter',
                  onPressed: () => unawaited(_open()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
