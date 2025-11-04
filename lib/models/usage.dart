import 'package:cloud_firestore/cloud_firestore.dart';

class Usage {
  final String? id;
  final int pondId;
  final DateTime date;
  final String productCode;
  final String productName;
  final String unit;
  final double weight;
  final double totalPrice;

  const Usage({
    this.id,
    required this.pondId,
    required this.date,
    required this.productCode,
    required this.productName,
    required this.unit,
    required this.weight,
    required this.totalPrice,
  });

  Usage copyWith({
    String? id,
    int? pondId,
    DateTime? date,
    String? productCode,
    String? productName,
    String? unit,
    double? weight,
    double? totalPrice,
  }) {
    return Usage(
      id: id ?? this.id,
      pondId: pondId ?? this.pondId,
      date: date ?? this.date,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      unit: unit ?? this.unit,
      weight: weight ?? this.weight,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pondId': pondId,
      'date': Timestamp.fromDate(date),
      'productCode': productCode,
      'productName': productName,
      'unit': unit,
      'weight': weight,
      'totalPrice': totalPrice,
    };
  }

  factory Usage.fromMap(Map<String, dynamic> map, {required String id}) {
    final dynamic rawDate = map['date'];
    DateTime resolvedDate;
    if (rawDate is Timestamp) {
      resolvedDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      resolvedDate = rawDate;
    } else if (rawDate is String) {
      resolvedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      resolvedDate = DateTime.now();
    }

    double resolveDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return Usage(
      id: id,
      pondId: (map['pondId'] as num?)?.toInt() ?? 0,
      date: resolvedDate,
      productCode: (map['productCode'] as String?)?.trim() ?? '',
      productName: (map['productName'] as String?)?.trim() ?? '',
      unit: (map['unit'] as String?)?.trim() ?? 'unit',
      weight: resolveDouble(map['weight']),
      totalPrice: resolveDouble(map['totalPrice']),
    );
  }
}
