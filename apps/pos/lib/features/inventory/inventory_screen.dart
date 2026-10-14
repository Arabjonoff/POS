import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/data/inventory/count_store.dart';
import 'package:pos_app/features/common/section_page.dart';
import 'package:pos_app/features/inventory/count_editor.dart';
import 'package:pos_app/features/products/product_list.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

final countsProvider = StreamProvider<List<CountSummary>>(
  (ref) => ref.watch(countStoreProvider).watchAll(),
);

/// Tovarlar → Inventarizatsiya (`/products/inventory`): ro'yxat va
/// tahrirlovchi (`inventory-api.md`).
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String? _openId;

  /// Qamrov: hamma tovarlar yoki bitta kategoriya.
  Future<void> _new() async {
    final l10n = AppLocalizations.of(context);
    final categories =
        ref.read(productCategoriesProvider).value ?? const <ProductCategory>[];
    final choice = await showPosDialog<(String?,)>(
      context: context,
      builder: (context) => PosDialog(
        icon: Icons.fact_check_outlined,
        title: l10n.inventoryScopeTitle,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PosListTile(
              key: const ValueKey('scope-all'),
              leading: const Icon(Icons.inventory_2_outlined),
              title: l10n.inventoryScopeAll,
              onTap: () => Navigator.of(context).pop((null,)),
            ),
            for (final c in categories)
              PosListTile(
                key: ValueKey('scope-${c.id}'),
                leading: const Icon(Icons.category_outlined),
                title: c.name,
                onTap: () => Navigator.of(context).pop((c.id,)),
              ),
          ],
        ),
        actions: [
          PosButton(
            label: l10n.actionCancel,
            variant: PosButtonVariant.secondary,
            shortcut: 'Esc',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    final id = await ref.read(countStoreProvider).create(categoryId: choice.$1);
    if (mounted) setState(() => _openId = id);
  }

  @override
  Widget build(BuildContext context) {
    final openId = _openId;
    if (openId != null) {
      return CountEditor(
        key: ValueKey(openId),
        countId: openId,
        onClose: () => setState(() => _openId = null),
      );
    }
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final compact = PosWindowSize.of(context).isCompact;
    final padding = compact ? PosSpacing.l : PosSpacing.xl;
    final counts = ref.watch(countsProvider).value;
    final newButton = PosButton(
      key: const ValueKey('inventory-new'),
      label: l10n.inventoryNew,
      icon: Icons.add,
      onPressed: () => unawaited(_new()),
    );

    final Widget body;
    if (counts == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (counts.isEmpty) {
      body = PosEmptyState(
        icon: Icons.fact_check_outlined,
        title: l10n.inventoryEmptyTitle,
        message: l10n.inventoryEmptyMessage,
        action: newButton,
      );
    } else {
      body = ListView.separated(
        padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
        itemCount: counts.length,
        separatorBuilder: (_, _) => const SizedBox(height: PosSpacing.s),
        itemBuilder: (context, i) {
          final c = counts[i];
          return PosCard(
            key: ValueKey('count-${c.id}'),
            onTap: () => setState(() => _openId = c.id),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fmt.dateTime(c.postedAt ?? c.createdAt),
                        style: PosTypography.bodyStrong.copyWith(color: p.text),
                      ),
                      Text(
                        [
                          c.categoryName ?? l10n.inventoryScopeAll,
                          l10n.receivingLines(c.lineCount),
                        ].join(' · '),
                        style: PosTypography.small.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PosBadge(
                  label: c.isDraft
                      ? l10n.receivingDraft
                      : l10n.receivingPostedBadge,
                  tone: c.isDraft ? PosTone.warning : PosTone.success,
                ),
              ],
            ),
          );
        },
      );
    }

    return SectionPage(
      title: l10n.inventoryTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(padding, 0, padding, PosSpacing.m),
            child: Wrap(
              spacing: PosSpacing.s,
              runSpacing: PosSpacing.s,
              children: [
                PosButton(
                  key: const ValueKey('inventory-back'),
                  label: l10n.navProducts,
                  icon: Icons.arrow_back,
                  variant: PosButtonVariant.secondary,
                  onPressed: () => context.go('/products'),
                ),
                if (counts != null && counts.isNotEmpty) newButton,
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
