import '../models/product.dart';
import '../models/usage.dart';

class PondRepository {
  PondRepository._internal() {
    // seed example products
    products.addAll([
      Product(name: 'Feed A', code: 'F001', unit: 'kg', pricePerUnit: 50.0, category: 'feed'),
      Product(name: 'Feed B', code: 'F002', unit: 'kg', pricePerUnit: 60.0, category: 'feed'),
      Product(name: 'Medicine X', code: 'M001', unit: 'gm', pricePerUnit: 0.5, category: 'medicine'),
    ]);
  }

  static final PondRepository instance = PondRepository._internal();

  final List<Product> products = [];
  final Map<int, List<Usage>> pondUsages = {}; // pondId -> usages
  final List<String> ponds = [];

  void addProduct(Product p) {
    products.add(p);
  }

  // Pond management
  void _seedPonds() {
    if (ponds.isEmpty) {
      for (var i = 1; i <= 6; i++) { ponds.add('Pond $i'); }
    }
  }

  int getPondCount() {
    _seedPonds();
    return ponds.length;
  }

  String getPondName(int pondId) {
    _seedPonds();
    if (pondId - 1 < 0 || pondId - 1 >= ponds.length) return 'Pond $pondId';
    return ponds[pondId - 1];
  }

  void addPond(String name) {
    ponds.add(name);
  }

  List<Usage> getUsagesForPond(int pondId) {
    return pondUsages[pondId] ?? [];
  }

  void addUsage(int pondId, Usage u) {
    pondUsages.putIfAbsent(pondId, () => []).add(u);
  }

  double totalWeightForPond(int pondId) {
    final list = getUsagesForPond(pondId);
    return list.fold(0.0, (s, e) => s + e.weight);
  }

  double totalCostForPond(int pondId) {
    final list = getUsagesForPond(pondId);
    return list.fold(0.0, (s, e) => s + e.totalPrice);
  }
}
