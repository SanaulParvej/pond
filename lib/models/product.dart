class Product {
  final String name;
  final String code;
  final String unit;
  final double pricePerUnit;
  final String category;

  const Product({
    required this.name,
    required this.code,
    required this.unit,
    required this.pricePerUnit,
    this.category = 'feed',
  });

  Product copyWith({
    String? name,
    String? code,
    String? unit,
    double? pricePerUnit,
    String? category,
  }) {
    return Product(
      name: name ?? this.name,
      code: code ?? this.code,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
      'category': category,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    final price = map['pricePerUnit'];
    double resolvedPrice;
    if (price is num) {
      resolvedPrice = price.toDouble();
    } else if (price is String) {
      resolvedPrice = double.tryParse(price) ?? 0;
    } else {
      resolvedPrice = 0;
    }

    return Product(
      name: (map['name'] as String?)?.trim() ?? '',
      code: (map['code'] as String?)?.trim() ?? '',
      unit: (map['unit'] as String?)?.trim() ?? 'unit',
      pricePerUnit: resolvedPrice,
      category: (map['category'] as String?)?.trim().toLowerCase() ?? 'feed',
    );
  }
}
