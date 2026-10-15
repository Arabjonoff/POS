import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/shell/app_status_bar.dart';
import 'package:pos_app/app/sync/sales_gate.dart';
import 'package:pos_app/app/sync/subscription_notice.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Sinov banneri yopildi (ilova qayta ochilguncha; T-108a).
class TrialBannerClosed extends Notifier<bool> {
  @override
  bool build() => false;

  void close() => state = true;
}

final trialBannerClosedProvider = NotifierProvider<TrialBannerClosed, bool>(
  TrialBannerClosed.new,
);

/// Obuna ogohlantirishi — barcha bo'limlar tepasida (`subscription-billing.md`):
/// sinov — ko'k, tugashiga ≤ 3 kun — sariq, muddati o'tgan (grace) — qizil.
/// Bir qator, 28 dp (kassa ekraniga joy qolsin); sinov xabarini yopsa bo'ladi,
/// muddat tugayotgani/o'tgani — yo'q.
/// Savdo to'xtagan holatlar kassa ekranidagi bannerda (sababi bilan).
class SubscriptionBanner extends ConsumerWidget {
  const SubscriptionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notice = ref.watch(subscriptionNoticeProvider);
    if (notice == null) return const SizedBox.shrink();
    final trial = notice.kind == SubscriptionNoticeKind.trial;
    if (trial && ref.watch(trialBannerClosedProvider)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final phone = ref.watch(supportPhoneProvider);
    final days = notice.daysLeft;
    final (tone, icon, text) = switch (notice.kind) {
      SubscriptionNoticeKind.trial => (
        PosTone.primary,
        Icons.hourglass_bottom,
        l10n.subTrial(days ?? 0),
      ),
      SubscriptionNoticeKind.expiring => (
        PosTone.warning,
        Icons.event_busy_outlined,
        l10n.subExpiring(days ?? 0),
      ),
      SubscriptionNoticeKind.grace => (
        PosTone.danger,
        Icons.warning_amber_rounded,
        days == null ? l10n.subGraceUnknown : l10n.subGrace(days),
      ),
    };
    return NoticeBar(
      key: const ValueKey('subscription-banner'),
      tone: tone,
      icon: icon,
      text: text,
      detail: contactLine(l10n, phone),
      compact: true,
      closeTooltip: l10n.actionCloseBanner,
      onClose: trial
          ? () => ref.read(trialBannerClosedProvider.notifier).close()
          : null,
    );
  }
}

/// "Aloqa: +998 …" yoki telefon sozlanmagan bo'lsa — administratorga.
String contactLine(AppLocalizations l10n, String phone) =>
    phone.isEmpty ? l10n.subContactAdmin : l10n.subContact(phone);

/// Savdo nega to'xtagani va nima ishlashi (kassa ekrani banneri).
String salesBlockHelp(AppLocalizations l10n, SalesBlock block) =>
    switch (block) {
      SalesBlock.readonly => l10n.salesHelpReadonly,
      SalesBlock.blocked || SalesBlock.deviceBlocked => l10n.salesHelpBlocked,
      SalesBlock.offlineTooLong => l10n.salesHelpOffline,
      SalesBlock.none => '',
    };

/// Bir qatorli ogohlantirish: ikonka, matn va ixtiyoriy izoh (ohang bo'yicha).
class NoticeBar extends StatelessWidget {
  const NoticeBar({
    required this.tone,
    required this.icon,
    required this.text,
    this.detail,
    this.extra,
    this.rounded = false,
    this.compact = false,
    this.onClose,
    this.closeTooltip = '',
    super.key,
  });

  final PosTone tone;
  final IconData icon;
  final String text;
  final String? detail;

  /// Qo'shimcha qator (masalan, aloqa).
  final String? extra;

  /// Karta ichida (kassa ekrani) — yumaloq burchak; qobiq tepasida — to'liq kenglik.
  final bool rounded;

  /// Bir qator, 28 dp (qobiq tepasi): matn va izoh bir qatorda, sig'masa — `…`.
  final bool compact;

  /// Berilsa — o'ngda yopish tugmasi (48 × 28: banner balandligi 28).
  final VoidCallback? onClose;
  final String closeTooltip;

  @override
  Widget build(BuildContext context) {
    final c = PosPalette.of(context).tone(tone);
    if (compact) return _compact(context, c);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: PosSpacing.l,
          vertical: PosSpacing.s,
        ),
        decoration: BoxDecoration(
          color: c.soft,
          borderRadius: rounded ? PosRadius.controlAll : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: c.onSoft, size: PosSizes.iconM),
            const SizedBox(width: PosSpacing.s),
            Expanded(
              child: Wrap(
                spacing: PosSpacing.m,
                runSpacing: PosSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    text,
                    style: PosTypography.bodyStrong.copyWith(color: c.onSoft),
                  ),
                  for (final line in [detail, extra])
                    if (line != null)
                      Text(
                        line,
                        style: PosTypography.small.copyWith(color: c.onSoft),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on NoticeBar {
  Widget _compact(BuildContext context, PosToneColors c) {
    final style = PosTypography.small.copyWith(
      color: c.onSoft,
      fontWeight: FontWeight.w500,
    );
    Widget part(String value, {int flex = 10}) => Flexible(
      flex: flex,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
    final parts = [text, ?detail, ?extra];
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        height: PosSizes.noticeBarHeight,
        color: c.soft,
        padding: EdgeInsets.only(
          left: PosSpacing.l,
          right: onClose == null ? PosSpacing.l : 0,
        ),
        child: Row(
          children: [
            const Spacer(),
            Icon(icon, color: c.onSoft, size: PosSizes.iconS),
            const SizedBox(width: PosSpacing.s),
            for (final (i, value) in parts.indexed) ...[
              if (i > 0) Text(' · ', style: style),
              // Asosiy matn birinchi qisqarmasin.
              part(value, flex: i == 0 ? 20 : 10),
            ],
            const Spacer(),
            if (onClose != null)
              Tooltip(
                message: closeTooltip,
                excludeFromSemantics: true,
                child: Semantics(
                  button: true,
                  label: closeTooltip,
                  excludeSemantics: true,
                  child: InkWell(
                    key: const ValueKey('notice-close'),
                    onTap: onClose,
                    child: SizedBox(
                      width: PosSizes.touchMin,
                      height: PosSizes.noticeBarHeight,
                      child: Icon(
                        Icons.close,
                        color: c.onSoft,
                        size: PosSizes.iconS,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Kirim/inventarizatsiyani tasdiqlash o'chiq bo'lsa — sababi (savdo bilan
/// bir xil qoida, `sync.md`).
class SalesBlockedNote extends ConsumerWidget {
  const SalesBlockedNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final block = ref.watch(salesBlockProvider);
    if (block == SalesBlock.none) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      key: const ValueKey('sales-blocked-note'),
      padding: const EdgeInsets.only(bottom: PosSpacing.s),
      child: Text(
        l10n.salesBlockedAction(salesBlockLabel(l10n, block)),
        style: PosTypography.small.copyWith(
          color: PosPalette.of(context).dangerText,
        ),
      ),
    );
  }
}
