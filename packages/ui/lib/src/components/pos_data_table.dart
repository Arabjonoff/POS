import 'package:flutter/material.dart';
import 'package:pos_ui/src/components/pos_skeleton.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// Jadval ustuni. Kenglik: [width] (qat'iy) yoki [flex] (qolgan joydan ulush).
class PosTableColumn<T> {
  const PosTableColumn({
    required this.label,
    required this.cell,
    this.flex = 1,
    this.width,
    this.numeric = false,
    this.sortable = false,
  });

  final String label;
  final Widget Function(BuildContext context, T row) cell;
  final int flex;
  final double? width;

  /// Raqamli ustun: o'ngga tekislangan, raqamlar bir xil kenglikda.
  final bool numeric;
  final bool sortable;
}

/// Desktop/planshet jadvali: sarlavha (saralash bilan), qatorlar (hover,
/// tanlash, klaviatura bilan fokus + Enter), yuklanish va bo'sh holat.
class PosDataTable<T> extends StatelessWidget {
  const PosDataTable({
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.isSelected,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.loading = false,
    this.empty,
    this.rowHeight = 52,
    this.shrinkWrap = false,
    super.key,
  }) : assert(rowHeight >= PosSizes.touchMin, 'Qator kamida 48 dp');

  final List<PosTableColumn<T>> columns;
  final List<T> rows;
  final ValueChanged<T>? onRowTap;
  final bool Function(T row)? isSelected;
  final int? sortColumnIndex;
  final bool sortAscending;

  /// Ustun sarlavhasi bosildi: (ustun indeksi, yangi yo'nalish).
  final void Function(int columnIndex, {required bool ascending})? onSort;
  final bool loading;

  /// Qatorlar bo'sh bo'lganda ko'rsatiladi (odatda `PosEmptyState`).
  final Widget? empty;
  final double rowHeight;

  /// Balandligi cheklanmagan joyda (masalan, `ListView` ichida).
  final bool shrinkWrap;

  static const double _headerHeight = 48;
  static const double _cellPadding = PosSpacing.l;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);

    Widget sized(PosTableColumn<T> column, Widget child) {
      final padded = Padding(
        padding: const EdgeInsets.symmetric(horizontal: _cellPadding),
        child: Align(
          alignment: column.numeric
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: child,
        ),
      );
      return column.width != null
          ? SizedBox(width: column.width, child: padded)
          : Expanded(flex: column.flex, child: padded);
    }

    final header = Container(
      height: _headerHeight,
      color: p.surfaceMuted,
      child: Row(
        children: [
          for (final (i, column) in columns.indexed)
            sized(
              column,
              _HeaderCell(
                label: column.label,
                numeric: column.numeric,
                sorted: sortColumnIndex == i,
                ascending: sortAscending,
                onTap: column.sortable && onSort != null
                    ? () => onSort!(
                        i,
                        ascending: sortColumnIndex != i || !sortAscending,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );

    Widget row(BuildContext context, int index) {
      final item = rows[index];
      final selected = isSelected?.call(item) ?? false;
      final cells = Row(
        children: [
          for (final column in columns)
            sized(
              column,
              DefaultTextStyle.merge(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PosTypography.small.copyWith(
                  color: selected ? p.onPrimarySoft : p.text,
                  fontFeatures: column.numeric ? PosTypography.tabular : null,
                ),
                child: column.cell(context, item),
              ),
            ),
        ],
      );
      return Material(
        color: selected ? p.primarySoft : p.surface,
        child: InkWell(
          onTap: onRowTap == null ? null : () => onRowTap!(item),
          hoverColor: p.text.withValues(alpha: 0.04),
          focusColor: p.primary.withValues(alpha: 0.10),
          child: Container(
            height: rowHeight,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: p.border)),
            ),
            child: cells,
          ),
        ),
      );
    }

    Widget bodyContent;
    if (loading) {
      bodyContent = ListView.builder(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        itemCount: 5,
        itemBuilder: (context, _) => Container(
          height: rowHeight,
          padding: const EdgeInsets.symmetric(horizontal: _cellPadding),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: PosSkeleton(height: 14)),
              SizedBox(width: PosSpacing.xxl),
              Expanded(child: PosSkeleton(height: 14)),
              SizedBox(width: PosSpacing.xxl),
              Expanded(child: PosSkeleton(height: 14)),
            ],
          ),
        ),
      );
    } else if (rows.isEmpty && empty != null) {
      bodyContent = shrinkWrap ? empty! : Center(child: empty);
    } else {
      bodyContent = ListView.builder(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        itemCount: rows.length,
        itemBuilder: row,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: PosRadius.controlAll,
        border: Border.all(color: p.border),
      ),
      child: ClipRRect(
        borderRadius: PosRadius.controlAll,
        child: Column(
          mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Divider(height: 1, color: p.border),
            if (shrinkWrap) bodyContent else Expanded(child: bodyContent),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.numeric,
    required this.sorted,
    required this.ascending,
    required this.onTap,
  });

  final String label;
  final bool numeric;
  final bool sorted;
  final bool ascending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final color = sorted ? p.text : p.textSecondary;
    final text = Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: PosTypography.smallStrong.copyWith(color: color),
      ),
    );
    final arrow = Icon(
      sorted
          ? (ascending ? Icons.arrow_upward : Icons.arrow_downward)
          : Icons.unfold_more,
      size: PosSizes.iconS,
      color: sorted ? p.text : p.textMuted,
    );
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onTap != null && numeric) ...[
          arrow,
          const SizedBox(width: PosSpacing.xs),
        ],
        text,
        if (onTap != null && !numeric) ...[
          const SizedBox(width: PosSpacing.xs),
          arrow,
        ],
      ],
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: PosRadius.inputAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: PosSizes.touchMin),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: PosSpacing.xs),
            child: content,
          ),
        ),
      ),
    );
  }
}
