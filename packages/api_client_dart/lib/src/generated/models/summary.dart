// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'payments.dart';
import 'period.dart';
import 'previous.dart';
import 'refunds_by_method.dart';

part 'summary.g.dart';

@JsonSerializable()
class Summary {
  const Summary({
    required this.period,
    required this.revenueTiyin,
    required this.salesTotalTiyin,
    required this.refundsTotalTiyin,
    required this.salesCount,
    required this.averageCheckTiyin,
    required this.profitTiyin,
    required this.paymentsTiyin,
    required this.refundsTiyin,
    required this.previous,
    required this.revenueChangeBp,
    required this.profitChangeBp,
  });
  
  factory Summary.fromJson(Map<String, Object?> json) => _$SummaryFromJson(json);
  
  final Period period;
  @JsonKey(name: 'revenue_tiyin')
  final int revenueTiyin;
  @JsonKey(name: 'sales_total_tiyin')
  final int salesTotalTiyin;
  @JsonKey(name: 'refunds_total_tiyin')
  final int refundsTotalTiyin;
  @JsonKey(name: 'sales_count')
  final int salesCount;
  @JsonKey(name: 'average_check_tiyin')
  final int averageCheckTiyin;
  @JsonKey(name: 'profit_tiyin')
  final int profitTiyin;
  @JsonKey(name: 'payments_tiyin')
  final Payments paymentsTiyin;
  @JsonKey(name: 'refunds_tiyin')
  final RefundsByMethod refundsTiyin;
  final Previous previous;
  @JsonKey(name: 'revenue_change_bp')
  final int? revenueChangeBp;
  @JsonKey(name: 'profit_change_bp')
  final int? profitChangeBp;

  Map<String, Object?> toJson() => _$SummaryToJson(this);
}
