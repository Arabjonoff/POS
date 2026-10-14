import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/barcode/scanner_service.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/data/catalog/product_editor.dart';
import 'package:pos_app/features/common/section_page.dart';
import 'package:pos_app/features/products/import_dialog.dart';
import 'package:pos_app/features/products/product_card.dart';
import 'package:pos_app/features/products/product_list.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Tovarlar (`products.md`): qidiruv, kategoriya va holat filtrlari, desktop
/// — jadval, telefon — kartalar. Skaner: tovar bo'lsa kartasi, yo'q bo'lsa
/// yangi karta (shtrix-kod to'ldirilgan).
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  /// Kontent shu kenglikdan katta bo'lsa — jadval.
  static const double tableMinWidth = 720;

  /// Jadval shundan tor bo'lsa — shtrix-kod va tannarx ustunlari yashiriladi
  /// (qoldiq doim ko'rinsin).
  static const double fullTableMinWidth = 1000;

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _search = TextEditingController();
  String? _category;
  ProductFilter _filter = ProductFilter.active;
  bool _dialogOpen = false;
  int _sortColumn = 0;
  bool _ascending = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open({String? productId, String? barcode}) async {
    if (_dialogOpen) return;
    setState(() => _dialogOpen = true);
    try {
      final saved = await showProductCard(
        context,
        productId: productId,
        barcode: barcode,
      );
      if (saved != null && mounted) {
        showPosToast(
          context,
          message: AppLocalizations.of(context).productSaved,
          tone: PosTone.success,
        );
      }
    } finally {
      if (mounted) setState(() => _dialogOpen = false);
    }
  }

  Future<void> _import() async {
    if (_dialogOpen) return;
    setState(() => _dialogOpen = true);
    try {
      final result = await showImportDialog(context);
      if (result != null && mounted) {
        showPosToast(
          context,
          message: AppLocalizations.of(
            context,
          ).importDone(result.created, result.updated, result.skipped),
          tone: PosTone.success,
        );
      }
    } finally {
      if (mounted) setState(() => _dialogOpen = false);
    }
  }

  Future<void> _onScan(ScanEvent event) async {
    final owner = await ref.read(productEditorProvider).ownerOf(event.code);
    if (!mounted) return;
    await _open(productId: owner?.productId, barcode: event.code);
  }

  void _onTyping(String text) {
    final value = _search.text + text;
    _search.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() {});
  }

  List<ProductRow> _sorted(List<ProductRow> rows) {
    int compare(ProductRow a, ProductRow b) => switch (_sortColumn) {
      3 => a.priceTiyin.compareTo(b.priceTiyin),
      5 => a.stockMilli.compareTo(b.stockMilli),
      _ => a.searchKey.compareTo(b.searchKey),
    };
    return [...rows]
      ..sort((a, b) => _ascending ? compare(a, b) : compare(b, a));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = PosWindowSize.of(context).isCompact;
    final padding = compact ? PosSpacing.l : PosSpacing.xl;
    final all = ref.watch(productRowsProvider);
    final categories =
        ref.watch(productCategoriesProvider).value ?? const <ProductCategory>[];
    final rows = all == null
        ? null
        : _sorted(
            filterProducts(
              all,
              query: _search.text,
              categoryId: _category,
              filter: _filter,
            ),
          );

    Widget chip(
      String label, {
      required bool selected,
      required VoidCallback onTap,
      Key? key,
    }) => Padding(
      padding: const EdgeInsets.only(right: PosSpacing.s),
      child: PosButton(
        key: key,
        label: label,
        size: PosButtonSize.s,
        variant: selected
            ? PosButtonVariant.primary
            : PosButtonVariant.secondary,
        onPressed: onTap,
      ),
    );

    final Widget body;
    if (rows == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (all!.isEmpty) {
      body = PosEmptyState(
        icon: Icons.inventory_2_outlined,
        title: l10n.productsEmptyTitle,
        message: l10n.productsEmptyMessage,
        action: Wrap(
          spacing: PosSpacing.s,
          runSpacing: PosSpacing.s,
          alignment: WrapAlignment.center,
          children: [
            PosButton(
              label: l10n.productsAdd,
              icon: Icons.add,
              onPressed: () => unawaited(_open()),
            ),
            PosButton(
              key: const ValueKey('products-import-empty'),
              label: l10n.importTitle,
              icon: Icons.upload_file_outlined,
              variant: PosButtonVariant.secondary,
              onPressed: () => unawaited(_import()),
            ),
          ],
        ),
      );
    } else if (rows.isEmpty) {
      body = PosEmptyState(
        icon: Icons.search_off,
        title: l10n.productsNotFound,
      );
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth >= ProductsScreen.tableMinWidth
            ? _table(
                rows,
                full: constraints.maxWidth >= ProductsScreen.fullTableMinWidth,
              )
            : _cards(rows),
      );
    }

    return ScanListener(
      enabled: !_dialogOpen,
      onScan: (e) => unawaited(_onScan(e)),
      onTyping: _onTyping,
      child: SectionPage(
        title: l10n.navProducts,
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding, 0, padding, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: PosSearchField(
                      key: const ValueKey('products-search'),
                      controller: _search,
                      hint: l10n.productsSearchHint,
                      clearTooltip: l10n.actionClear,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: PosSpacing.s),
                  if (compact)
                    PosIconButton(
                      key: const ValueKey('products-import'),
                      icon: Icons.upload_file_outlined,
                      tooltip: l10n.importTitle,
                      variant: PosIconButtonVariant.outlined,
                      onPressed: () => unawaited(_import()),
                    )
                  else
                    PosButton(
                      key: const ValueKey('products-import'),
                      label: l10n.importTitle,
                      icon: Icons.upload_file_outlined,
                      variant: PosButtonVariant.secondary,
                      onPressed: () => unawaited(_import()),
                    ),
                  const SizedBox(width: PosSpacing.s),
                  if (compact)
                    PosIconButton(
                      key: const ValueKey('products-add'),
                      icon: Icons.add,
                      tooltip: l10n.productsAdd,
                      variant: PosIconButtonVariant.filled,
                      onPressed: () => unawaited(_open()),
                    )
                  else
                    PosButton(
                      key: const ValueKey('products-add'),
                      label: l10n.productsAdd,
                      icon: Icons.add,
                      onPressed: () => unawaited(_open()),
                    ),
                ],
              ),
              const SizedBox(height: PosSpacing.s),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final (f, label) in [
                      (ProductFilter.active, l10n.productsAll),
                      (ProductFilter.low, l10n.productsFilterLow),
                      (ProductFilter.negative, l10n.productsFilterNegative),
                      (ProductFilter.inactive, l10n.productsFilterInactive),
                    ])
                      chip(
                        label,
                        key: ValueKey('products-filter-${f.name}'),
                        selected: _filter == f,
                        onTap: () => setState(() => _filter = f),
                      ),
                  ],
                ),
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: PosSpacing.s),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      chip(
                        l10n.productsAll,
                        selected: _category == null,
                        onTap: () => setState(() => _category = null),
                      ),
                      for (final c in categories)
                        chip(
                          c.name,
                          key: ValueKey('products-category-${c.id}'),
                          selected: _category == c.id,
                          onTap: () => setState(() => _category = c.id),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: PosSpacing.m),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }

  Widget _table(List<ProductRow> rows, {required bool full}) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    return PosDataTable<ProductRow>(
      rows: rows,
      onRowTap: (r) => unawaited(_open(productId: r.id)),
      sortColumnIndex: full
          ? _sortColumn
          : const {0: 0, 3: 2, 5: 3}[_sortColumn],
      sortAscending: _ascending,
      onSort: (i, {required ascending}) => setState(() {
        // Tor jadvalda ustun indekslari: nom 0, kategoriya 1, narx 2, qoldiq 3.
        _sortColumn = full ? i : const {0: 0, 2: 3, 3: 5}[i] ?? 0;
        _ascending = ascending;
      }),
      columns: [
        PosTableColumn(
          label: l10n.productsColName,
          flex: 3,
          sortable: true,
          minWidth: 200,
          cell: (context, r) => Text(
            r.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PosTypography.bodyStrong.copyWith(
              color: r.isActive ? p.text : p.textMuted,
            ),
          ),
        ),
        if (full)
          PosTableColumn(
            label: l10n.productsColBarcode,
            flex: 2,
            minWidth: 150,
            cell: (context, r) => Text(
              r.barcodes.isEmpty ? (r.pluCode ?? '') : r.barcodes.first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PosTypography.body.copyWith(
                color: p.textSecondary,
                fontFeatures: PosTypography.tabular,
              ),
            ),
          ),
        PosTableColumn(
          label: l10n.productsColCategory,
          flex: 2,
          cell: (context, r) => Text(
            r.categoryName ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PosTypography.body.copyWith(color: p.textSecondary),
          ),
        ),
        PosTableColumn(
          label: l10n.productsColPrice,
          flex: 2,
          minWidth: 130,
          numeric: true,
          sortable: true,
          cell: (context, r) =>
              PosMoneyText(amount: r.priceTiyin, currency: fmt.currency),
        ),
        if (full)
          PosTableColumn(
            label: l10n.productsColCost,
            flex: 2,
            minWidth: 130,
            numeric: true,
            cell: (context, r) => PosMoneyText(
              amount: r.costTiyin,
              currency: fmt.currency,
              tone: PosTone.neutral,
            ),
          ),
        PosTableColumn(
          label: l10n.productsColStock,
          numeric: true,
          sortable: true,
          flex: 2,
          minWidth: 200,
          cell: (context, r) => FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: _Stock(row: r),
          ),
        ),
      ],
    );
  }

  Widget _cards(List<ProductRow> rows) {
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    return ListView.separated(
      itemCount: rows.length,
      padding: const EdgeInsets.only(bottom: PosSpacing.l),
      separatorBuilder: (_, _) => const SizedBox(height: PosSpacing.s),
      itemBuilder: (context, i) {
        final r = rows[i];
        return PosCard(
          onTap: () => unawaited(_open(productId: r.id)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PosTypography.bodyStrong.copyWith(
                        color: r.isActive ? p.text : p.textMuted,
                      ),
                    ),
                    Text(
                      [
                        if (r.barcodes.isNotEmpty) r.barcodes.first,
                        if (r.categoryName != null) r.categoryName!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PosTypography.small.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PosSpacing.s),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PosMoneyText(amount: r.priceTiyin, currency: fmt.currency),
                  const SizedBox(height: PosSpacing.xs),
                  _Stock(row: r),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Qoldiq: miqdor + "Kam"/"Manfiy"/"Nofaol" belgisi.
class _Stock extends StatelessWidget {
  const _Stock({required this.row});

  final ProductRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final (label, tone) = !row.isActive
        ? (l10n.productsBadgeInactive, PosTone.neutral)
        : row.negative
        ? (l10n.productsBadgeNegative, PosTone.danger)
        : row.low
        ? (l10n.productsBadgeLow, PosTone.warning)
        : (null, null);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          PosBadge(label: label, tone: tone!),
          const SizedBox(width: PosSpacing.xs),
        ],
        Flexible(
          child: Text(
            fmt.qty(row.stockMilli, row.unit),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PosTypography.body.copyWith(
              color: row.negative ? p.dangerText : p.text,
              fontFeatures: PosTypography.tabular,
            ),
          ),
        ),
      ],
    );
  }
}
