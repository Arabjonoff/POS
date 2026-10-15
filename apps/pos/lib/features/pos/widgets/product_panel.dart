import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/data/catalog/product_catalog.dart';
import 'package:pos_app/features/products/product_thumbnail.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Qidiruv natijalari (telefon): nom, shtrix-kod/PLU, narx. ↑/↓ + Enter yoki
/// bosish.
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

/// Kassa tabi: "Sevimlilar", "Hammasi" yoki kategoriya.
@immutable
sealed class ProductTab {
  const ProductTab();
}

/// Tez tugmalar + so'nggi 30 kunda ko'p sotilganlar.
final class FavoritesTab extends ProductTab {
  const FavoritesTab();

  @override
  bool operator ==(Object other) => other is FavoritesTab;

  @override
  int get hashCode => 0;
}

final class AllTab extends ProductTab {
  const AllTab();

  @override
  bool operator ==(Object other) => other is AllTab;

  @override
  int get hashCode => 1;
}

final class CategoryTab extends ProductTab {
  const CategoryTab(this.id);

  final String id;

  @override
  bool operator ==(Object other) => other is CategoryTab && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Tovar qoldig'i kartada: [stock] — `null` bo'lsa do'kon qoldiq yuritmaydi
/// (hech bir tovarda musbat qoldiq yo'q) va qoldiq ko'rsatilmaydi.
class StockView {
  const StockView(this.stock);

  /// Bitta ham musbat qoldiq bo'lmasa — do'kon kirim qilmaydi: kartalarda
  /// "qoldiq yo'q" bilan hammasini kulrang qilmaymiz.
  factory StockView.of(Map<String, int>? all) =>
      StockView(all != null && all.values.any((q) => q > 0) ? all : null);

  final Map<String, int>? stock;

  int? qty(CatalogProduct p) => stock == null ? null : (stock![p.id] ?? 0);

  bool isOut(CatalogProduct p) {
    final q = qty(p);
    return q != null && q <= 0;
  }

  bool isLow(CatalogProduct p) {
    final q = qty(p);
    return q != null && q > 0 && p.minStockMilli > 0 && q < p.minStockMilli;
  }
}

/// Kassaning chap paneli: kategoriya tablari ("Sevimlilar" birinchi) va
/// tovar kartalari panjarasi (`auto-fill, minmax(160, 1fr)`). Qidiruvda
/// ([results] berilgan) panjara natijalarni ko'rsatadi, [highlighted] —
/// ↑/↓ bilan tanlangan karta.
class ProductGrid extends StatefulWidget {
  const ProductGrid({
    required this.catalog,
    required this.tab,
    required this.onTab,
    required this.onPick,
    required this.favorites,
    required this.stock,
    this.results,
    this.highlighted = 0,
    super.key,
  });

  final ProductCatalog catalog;
  final ProductTab tab;
  final ValueChanged<ProductTab> onTab;
  final ValueChanged<CatalogProduct> onPick;

  /// "Sevimlilar" tovarlari (tartibda).
  final List<CatalogProduct> favorites;
  final StockView stock;
  final List<CatalogProduct>? results;
  final int highlighted;

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  final _scroll = ScrollController();
  int _columns = 1;

  @override
  void didUpdateWidget(ProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final results = widget.results;
    if (results != null &&
        results.isNotEmpty &&
        widget.highlighted != oldWidget.highlighted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Tanlangan karta ko'rinsin (↑/↓).
  void _reveal() {
    if (!mounted || !_scroll.hasClients) return;
    const row = PosProductTile.height + PosSpacing.m;
    final top = (widget.highlighted ~/ _columns) * row;
    final position = _scroll.position;
    final bottom = top + PosProductTile.height;
    double? target;
    if (top < position.pixels) {
      target = top;
    } else if (bottom > position.pixels + position.viewportDimension) {
      target = bottom - position.viewportDimension;
    }
    if (target == null) return;
    unawaited(
      _scroll.animateTo(
        target.clamp(0, position.maxScrollExtent),
        duration: PosMotion.press,
        curve: PosMotion.curve,
      ),
    );
  }

  List<CatalogProduct> get _products => switch (widget.tab) {
    FavoritesTab() => widget.favorites,
    AllTab() => widget.catalog.active(),
    CategoryTab(:final id) => widget.catalog.active(categoryId: id),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final results = widget.results;
    final products = results ?? _products;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CategoryTabs(
          catalog: widget.catalog,
          // Qidiruvda — hech biri tanlanmagan (natija hamma tovardan).
          selected: results == null ? widget.tab : null,
          showFavorites: widget.favorites.isNotEmpty,
          onTab: widget.onTab,
        ),
        const SizedBox(height: PosSpacing.m),
        Expanded(
          child: products.isEmpty
              ? PosEmptyState(
                  icon: results == null
                      ? Icons.grid_view_outlined
                      : Icons.search_off,
                  title: results == null
                      ? l10n.posQuickEmpty
                      : l10n.posNoResults,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = PosSpacing.m;
                    _columns =
                        ((constraints.maxWidth + gap) /
                                (PosProductTile.minWidth + gap))
                            .floor()
                            .clamp(1, 12);
                    return GridView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.only(bottom: PosSpacing.m),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _columns,
                        mainAxisExtent: PosProductTile.height,
                        mainAxisSpacing: gap,
                        crossAxisSpacing: gap,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, i) => ProductTile(
                        key: ValueKey('tile-${products[i].id}'),
                        product: products[i],
                        catalog: widget.catalog,
                        stock: widget.stock,
                        selected: results != null && i == widget.highlighted,
                        onTap: widget.onPick,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Kategoriya tablari: gorizontal suriladi; rangli nuqta — karta chizig'i
/// bilan bir xil rang.
class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.catalog,
    required this.selected,
    required this.showFavorites,
    required this.onTab,
  });

  final ProductCatalog catalog;
  final ProductTab? selected;
  final bool showFavorites;
  final ValueChanged<ProductTab> onTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    Widget tab(ProductTab value, String label, Color dot) => Padding(
      padding: const EdgeInsets.only(right: PosSpacing.s),
      child: _TabChip(
        key: ValueKey(switch (value) {
          FavoritesTab() => 'tab-favorites',
          AllTab() => 'tab-all',
          CategoryTab(:final id) => 'tab-$id',
        }),
        label: label,
        dot: dot,
        selected: value == selected,
        onTap: () => onTab(value),
      ),
    );

    return SizedBox(
      height: PosSizes.touchMin,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (showFavorites)
            tab(const FavoritesTab(), l10n.posFavorites, p.warning),
          tab(const AllTab(), l10n.posQuickAll, p.textMuted),
          for (final c in catalog.categories)
            tab(
              CategoryTab(c.id),
              c.name,
              p.categoryAccent(catalog.accentIndex(c.id) ?? 0),
            ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.dot,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final Color dot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? p.primary : p.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? p.primary : p.borderStrong),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: p.text.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: PosSpacing.l),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: selected ? p.onPrimary : dot,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: PosSpacing.s),
                Text(
                  label,
                  style: PosTypography.bodyStrong.copyWith(
                    color: selected ? p.onPrimary : p.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bitta tovar kartasi (rasm yoki bosh harf, narx, qoldiq).
class ProductTile extends StatelessWidget {
  const ProductTile({
    required this.product,
    required this.catalog,
    required this.stock,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  final CatalogProduct product;
  final ProductCatalog catalog;
  final StockView stock;
  final ValueChanged<CatalogProduct> onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final unit = UnitCode.fromCode(product.unit);
    final qty = stock.qty(product);
    final out = stock.isOut(product);
    final low = stock.isLow(product);
    final accent = catalog.accentIndex(product.categoryId);
    final stockText = qty == null
        ? null
        : (out ? l10n.posOutOfStock : fmt.qty(qty, unit));
    final price = '${fmt.moneyAmount(product.priceTiyin)} ${fmt.currency}';
    final label = [
      l10n.posProductTileLabel(
        product.name,
        l10n.posPricePerUnit(price, unit.label(l10n)),
      ),
      ?stockText,
      if (low) l10n.posStockLow,
    ].join(', ');
    return PosProductTile(
      name: product.name,
      price: fmt.moneyAmount(product.priceTiyin),
      unit: l10n.posPricePerUnit(fmt.currency, unit.label(l10n)),
      accent: accent == null ? null : p.categoryAccent(accent),
      image: product.imageId == null
          ? null
          : ProductThumbnail(imageId: product.imageId, size: 36),
      stock: stockText,
      lowLabel: low ? l10n.posStockLow : null,
      out: out,
      selected: selected,
      semanticLabel: label,
      onTap: () => onTap(product),
    );
  }
}
