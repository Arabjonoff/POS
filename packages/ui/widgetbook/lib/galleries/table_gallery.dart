import 'package:flutter/material.dart';
import 'package:pos_ui/pos_ui.dart';
import 'package:pos_ui_widgetbook/galleries/gallery.dart';

typedef SampleProduct = ({
  String name,
  String barcode,
  int qtyMilli,
  bool weighted,
  int price,
});

const List<SampleProduct> sampleProducts = [
  (
    name: 'Non "Buxoro"',
    barcode: '4780001000012',
    qtyMilli: 24000,
    weighted: false,
    price: 500000,
  ),
  (
    name: 'Sut 1 l',
    barcode: '4780001000029',
    qtyMilli: 3000,
    weighted: false,
    price: 1200000,
  ),
  (
    name: 'Shakar',
    barcode: '2000000000015',
    qtyMilli: 12750,
    weighted: true,
    price: 1450000,
  ),
  (
    name: 'Choy "Ahmad" 100 g',
    barcode: '5011111000017',
    qtyMilli: 0,
    weighted: false,
    price: 2800000,
  ),
  (
    name: 'Guruch lazer',
    barcode: '2000000000022',
    qtyMilli: 48250,
    weighted: true,
    price: 1800000,
  ),
  (
    name: 'Tuxum 10 ta',
    barcode: '4780001000036',
    qtyMilli: 6000,
    weighted: false,
    price: 1500000,
  ),
];

List<PosTableColumn<SampleProduct>> sampleColumns(BuildContext context) {
  final p = PosPalette.of(context);
  return [
    PosTableColumn(
      label: 'Nomi',
      minWidth: 180,
      flex: 3,
      sortable: true,
      cell: (_, r) => Text(r.name),
    ),
    PosTableColumn(
      label: 'Shtrix-kod',
      minWidth: 150,
      flex: 2,
      cell: (_, r) => Text(
        r.barcode,
        style: PosTypography.small.copyWith(
          color: p.textSecondary,
          fontFeatures: PosTypography.tabular,
        ),
      ),
    ),
    PosTableColumn(
      label: 'Qoldiq',
      numeric: true,
      sortable: true,
      cell: (_, r) => r.qtyMilli == 0
          ? const PosBadge(label: 'Tugagan', tone: PosTone.danger)
          : Text(
              PosFormat.qtyWithUnit(
                r.qtyMilli,
                unit: r.weighted ? 'kg' : 'dona',
                weighted: r.weighted,
              ),
            ),
    ),
    PosTableColumn(
      label: 'Narx',
      numeric: true,
      sortable: true,
      cell: (_, r) => Text(PosFormat.money(r.price, currency: "so'm")),
    ),
  ];
}

/// DataTable: saralangan, tanlangan qator; yuklanish va bo'sh holat.
class TableGallery extends StatelessWidget {
  const TableGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      sections: [
        GallerySection(
          title: 'DataTable',
          children: [
            SizedBox(
              width: 880,
              child: PosDataTable<SampleProduct>(
                columns: sampleColumns(context),
                rows: sampleProducts,
                sortColumnIndex: 0,
                isSelected: (r) => r.name == 'Shakar',
                onRowTap: noopValue,
                onSort: (_, {required ascending}) {},
                shrinkWrap: true,
              ),
            ),
          ],
        ),
        GallerySection(
          title: "Yuklanish va bo'sh",
          children: [
            SizedBox(
              width: 430,
              height: 220,
              child: PosDataTable<SampleProduct>(
                columns: sampleColumns(context).sublist(0, 2),
                rows: const [],
                loading: true,
              ),
            ),
            SizedBox(
              width: 430,
              height: 220,
              child: PosDataTable<SampleProduct>(
                columns: sampleColumns(context).sublist(0, 2),
                rows: const [],
                empty: const PosEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: "Tovarlar yo'q",
                  compact: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
