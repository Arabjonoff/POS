/// Boshqa (2-) kassada sotilgan chek — server javobi
/// (`GET /api/v1/sync/sales/?number=`, T-110): 3 × Non issiq, naqd,
/// bittasi serverda qaytarilgan.
const String remoteSaleId = '01900000-0000-7000-8000-000000000201';
const String remoteItemId = '01900000-0000-7000-8000-000000000202';

Map<String, Object?> remoteSaleJson({
  String number = 'D2-000007',
  int refundedQty = 1000,
}) => {
  'id': remoteSaleId,
  'number': number,
  'store': 'store-1',
  'device_number': 2,
  'cashier': 'cashier-2',
  'cashier_name': 'Dilshod',
  'customer': null,
  'customer_name': null,
  'subtotal_tiyin': 1200000,
  'discount_tiyin': 0,
  'total_tiyin': 1200000,
  'status': refundedQty == 0 ? 'completed' : 'partially_refunded',
  'sold_at': '2026-10-14T06:30:00Z',
  'items': [
    {
      'id': remoteItemId,
      'product': 'p-non',
      'name_snapshot': 'Non issiq',
      'barcode_snapshot': '4780000000014',
      'qty_milli': 3000,
      'price_tiyin': 400000,
      'discount_tiyin': 0,
      'total_tiyin': 1200000,
      'refunded_qty_milli': refundedQty,
      'refunded_tiyin': refundedQty * 400,
    },
  ],
  'payments': [
    {
      'method': 'cash',
      'amount_tiyin': 1200000,
      'received_tiyin': 1200000,
      'change_tiyin': 0,
    },
  ],
  'refunds': [
    if (refundedQty > 0)
      {
        'id': '01900000-0000-7000-8000-000000000203',
        'at': '2026-10-14T08:00:00Z',
        'method': 'cash',
        'total_tiyin': refundedQty * 400,
        'reason': 'Yaroqsiz',
      },
  ],
};
