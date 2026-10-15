import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/app/shell/app_sections.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/app/sync/sales_gate.dart';
import 'package:pos_app/app/update/app_update.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/features/auth/lock_screen.dart';
import 'package:pos_app/features/shift/shift_providers.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Holat qatori: internet, navbatdagi yozuvlar, printer, smena (+ kassir va
/// soat desktopda). Doim ko'rinadi (CLAUDE.md, UI/UX qoidalari). Planshet va
/// desktopda yozuv bosilsa — tegishli joyga (Sozlamalar, smena).
class AppStatusBar extends ConsumerWidget {
  const AppStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final compact = PosWindowSize.of(context).isCompact;
    final connection = ref.watch(connectionStatusProvider);
    final printer = ref.watch(printerStatusProvider);
    final queued = ref.watch(pendingEventsProvider).value ?? 0;
    final shiftOpen = ref.watch(shiftOpenProvider).value ?? false;
    final openedAt = ref.watch(currentShiftProvider).value?.openedAt;
    VoidCallback? go(String path) =>
        compact ? null : () => GoRouter.of(context).go(path);
    final settings = go(AppSection.settings.path);

    final connectionItem = switch (connection) {
      ConnectionStatus.unknown => PosStatusItem(
        icon: Icons.wifi_find,
        label: l10n.statusConnectionUnknown,
        onTap: settings,
      ),
      // Hammasi joyida — neytral (doimiy yashil ko'zni charchatadi).
      ConnectionStatus.online => PosStatusItem(
        icon: Icons.wifi,
        label: l10n.statusOnline,
        onTap: settings,
      ),
      // Qizil, lekin xotirjam: savdo to'xtamaydi (navbat — alohida yozuvda).
      ConnectionStatus.offline => PosStatusItem(
        icon: Icons.wifi_off,
        label: compact ? l10n.statusOffline : l10n.statusOfflineWorking,
        tone: PosTone.danger,
        onTap: settings,
      ),
    };

    final block = ref.watch(salesBlockProvider);
    final rejected = ref.watch(rejectedEventsProvider).value ?? 0;
    final skew = ref.watch(clockSkewProvider);
    final update = ref.watch(appUpdateProvider).value;

    final items = [
      // Eng muhimi — birinchi: savdo to'xtagan bo'lsa, sababi.
      if (block != SalesBlock.none)
        PosStatusItem(
          icon: Icons.block,
          label: salesBlockLabel(l10n, block),
          tone: PosTone.danger,
        ),
      connectionItem,
      PosStatusItem(
        icon: queued > 0 ? Icons.sync : Icons.cloud_done_outlined,
        label: l10n.statusQueued(queued),
        short: queued > 0 ? '$queued' : null,
        // Oflaynda navbat o'sib boradi — sariq; onlaynda bir zumda ketadi.
        tone: queued > 0 && connection == ConnectionStatus.offline
            ? PosTone.warning
            : PosTone.neutral,
        onTap: settings,
      ),
      switch (printer) {
        PrinterStatus.unknown => PosStatusItem(
          icon: Icons.print_outlined,
          label: l10n.statusPrinterUnknown,
          tone: PosTone.warning,
          onTap: settings,
        ),
        PrinterStatus.checking => PosStatusItem(
          icon: Icons.print_outlined,
          label: l10n.statusPrinterChecking,
          onTap: settings,
        ),
        PrinterStatus.ready => PosStatusItem(
          icon: Icons.print_outlined,
          label: l10n.statusPrinterReady,
          onTap: settings,
        ),
        PrinterStatus.missing => PosStatusItem(
          icon: Icons.print_disabled_outlined,
          label: l10n.statusPrinterMissing,
          tone: PosTone.danger,
          onTap: settings,
        ),
      },
      if (rejected > 0)
        PosStatusItem(
          icon: Icons.error_outline,
          label: l10n.statusRejected(rejected),
          tone: PosTone.danger,
        ),
      if (skew)
        PosStatusItem(
          icon: Icons.schedule,
          label: l10n.statusClockSkew,
          tone: PosTone.warning,
        ),
      if (shiftOpen)
        PosStatusItem(
          icon: Icons.work_history_outlined,
          label: openedAt == null || compact
              ? l10n.statusShiftOpen
              : l10n.statusShiftOpenSince(context.fmt.time(openedAt)),
          onTap: go('${AppSection.pos.path}/shift'),
        )
      else
        PosStatusItem(
          icon: Icons.work_history_outlined,
          label: l10n.statusShiftClosed,
          tone: PosTone.warning,
          onTap: go(AppSection.pos.path),
        ),
      // Oxirida: muhim emas, lekin ko'rinib tursin (Sozlamalar → Ilova haqida).
      if (update != null)
        PosStatusItem(
          icon: Icons.system_update_alt,
          label: l10n.statusUpdate(update.latestVersion),
          tone: PosTone.primary,
          onTap: settings,
        ),
    ];

    final user = ref.watch(sessionProvider.select((s) => s.user));
    return PosStatusBar(
      atTop: compact,
      compact: compact,
      items: items,
      trailing: compact
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user != null) ...[
                  const Icon(Icons.person_outline, size: PosSizes.iconM),
                  const SizedBox(width: PosSpacing.s),
                  Text(
                    '${user.fullName} · ${roleLabel(l10n, user.role)}',
                    style: PosTypography.body,
                  ),
                  const SizedBox(width: PosSpacing.xl),
                ],
                const _Clock(),
                const SizedBox(width: PosSpacing.s),
              ],
            ),
    );
  }
}

/// Soat (daqiqa aniqligida, do'kon vaqt zonasida).
class _Clock extends ConsumerStatefulWidget {
  const _Clock();

  @override
  ConsumerState<_Clock> createState() => _ClockState();
}

class _ClockState extends ConsumerState<_Clock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    return Text(
      context.fmt.time(now),
      style: PosTypography.bodyStrong.copyWith(
        color: PosPalette.of(context).text,
        fontFeatures: PosTypography.tabular,
      ),
    );
  }
}

/// Savdo nega to'xtagani (holat qatori va kassa ekrani banneri).
String salesBlockLabel(AppLocalizations l10n, SalesBlock block) =>
    switch (block) {
      SalesBlock.readonly => l10n.statusSalesReadonly,
      SalesBlock.blocked => l10n.statusSalesBlocked,
      SalesBlock.offlineTooLong => l10n.statusSalesOffline,
      SalesBlock.deviceBlocked => l10n.statusDeviceBlocked,
      SalesBlock.none => '',
    };
