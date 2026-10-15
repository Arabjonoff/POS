import 'package:flutter/material.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/data/catalog/product_catalog.dart';
import 'package:pos_app/features/products/product_thumbnail.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Qidiruv natijalari: nom, shtrix-kod/PLU, narx. ↑/↓ + Enter yoki bosish.
class SearchResults extends StatelessWidget {
  const SearchResults({
    required this.results,
    required this.highlighted,
    required this.onPick,
    super.key,
  });

  final List<CatalogProduct> results;
  final int highlighted;
  final ValueChanged<CatalogProduct> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    if (results.isEmpty) {
      return PosEmptyState(icon: Icons.search_off, title: l10n.posNoResults);
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, i) {
        final product = results[i];
        final code = product.pluCode ?? product.primaryBarcode;
        return PosListTile(
          title: product.name,
          subtitle: code,
          selected: i == highlighted,
          leading: product.imageId != null
              ? ProductThumbnail(imageId: product.imageId)
              : Icon(
                  product.isWeighted
                      ? Icons.scale_outlined
                      : Icons.inventory_2_outlined,
                ),
          trailing: PosMoneyText(
            amount: product.priceTiyin,
            currency: fmt.currency,
          ),
          onTap: () => onPick(product),
        );
      },
    );
  }
}

/// Tez tugmalar: kategoriya tablari + shtrix-kodsiz tovarlar plitkalari.
class QuickPanel extends StatelessWidget {
  const QuickPanel({
    required this.catalog,
    required this.category,
    required this.onCategory,
    required this.onPick,
    super.key,
  });

  final ProductCatalog catalog;

  /// `null` — hammasi.
  final String? category;
  final ValueChanged<String?> onCategory;
  final ValueChanged<CatalogProduct> onPick;

  static const double _tileMinWidth = 152;
  // Ichki joy: 2 qator nom (2 × 24) + narx (20) + chekka (2 × 12) = 92.
  static const double _tileHeight = 96;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = catalog.quickCategories;
    final products = catalog.quick(categoryId: category);
    if (catalog.quick().isEmpty) {
      return PosEmptyState(
        icon: Icons.grid_view_outlined,
        title: l10n.posQuickEmpty,
      );
    }

    Widget chip(String? id, String label) => PosButton(
      label: label,
      size: PosButtonSize.s,
      variant: id == category
          ? PosButtonVariant.primary
          : PosButtonVariant.secondary,
      onPressed: () => onCategory(id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (categories.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip(null, l10n.posQuickAll),
                for (final c in categories) ...[
                  const SizedBox(width: PosSpacing.xs),
                  chip(c.id, c.name),
                ],
              ],
            ),
          ),
        const SizedBox(height: PosSpacing.s),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = (constraints.maxWidth / _tileMinWidth)
                  .floor()
                  .clamp(2, 6);
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisExtent: _tileHeight,
                  mainAxisSpacing: PosSpacing.s,
                  crossAxisSpacing: PosSpacing.s,
                ),
                itemCount: products.length,
                itemBuilder: (context, i) =>
                    _QuickTile(product: products[i], onTap: onPick),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.product, required this.onTap});

  final CatalogProduct product;
  final ValueChanged<CatalogProduct> onTap;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return PosCard(
      padding: const EdgeInsets.all(PosSpacing.m),
      onTap: () => onTap(product),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: PosTypography.bodyStrong.copyWith(color: p.text),
          ),
          PosMoneyText(
            amount: product.priceTiyin,
            currency: context.fmt.currency,
            size: PosMoneySize.small,
          ),
        ],
      ),
    );
  }
}
