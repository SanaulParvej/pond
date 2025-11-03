class Product {
  final String name;
  final String code;
  final String unit; // "kg" or "gm"
  final double pricePerUnit;
  final String category; // 'feed' or 'medicine' or other

  Product({required this.name, required this.code, required this.unit, required this.pricePerUnit, this.category = 'feed'});
}
