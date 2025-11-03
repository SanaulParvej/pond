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
  bool _seeded = false;
  int _initialCount = 0;

  void addProduct(Product p) {
    products.add(p);
  }

  // Pond management
  void _seedPonds() {
    if (_seeded) return;
    ponds.addAll(List.generate(6, (index) => 'Pond ${index + 1}'));
    _initialCount = ponds.length;
    _seeded = true;
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

  void renamePond(int pondId, String name) {
    if (pondId < 1 || pondId > ponds.length) return;
    ponds[pondId - 1] = name;
  }

  bool removePond(int pondId) {
    if (pondId < 1 || pondId > ponds.length) return false;
    if (pondId <= _initialCount) return false;
    ponds.removeAt(pondId - 1);
    pondUsages.remove(pondId);

    final keysToShift = pondUsages.keys.where((k) => k > pondId).toList()..sort();
    for (final key in keysToShift) {
      final usages = pondUsages.remove(key);
      if (usages != null) {
        pondUsages[key - 1] = usages;
      }
    }
    return true;
  }

  List<Usage> getUsagesForPond(int pondId) {
    return pondUsages[pondId] ?? [];
  }

  void addUsage(int pondId, Usage u) {
    pondUsages.putIfAbsent(pondId, () => []).add(u);
  }

  bool updateUsage(int pondId, int index, Usage updated) {
    final list = pondUsages[pondId];
    if (list == null || index < 0 || index >= list.length) return false;
    list[index] = updated;
    return true;
  }

  bool removeUsageAt(int pondId, int index) {
    final list = pondUsages[pondId];
    if (list == null || index < 0 || index >= list.length) return false;
    list.removeAt(index);
    return true;
  }

  int indexOfUsage(int pondId, Usage usage) {
    final list = pondUsages[pondId];
    if (list == null) return -1;
    return list.indexOf(usage);
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
