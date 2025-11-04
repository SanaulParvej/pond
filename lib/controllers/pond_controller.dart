import 'dart:async';

import 'package:get/get.dart';

import '../models/pond_info.dart';
import '../models/product.dart';
import '../models/usage.dart';
import '../repository/pond_repository.dart';

class PondController extends GetxController {
  PondController({PondRepository? repository})
      : _repo = repository ?? PondRepository.instance;

  final PondRepository _repo;

  final RxList<Product> products = <Product>[].obs;
  final RxList<PondInfo> ponds = <PondInfo>[].obs;
  final RxMap<int, List<Usage>> pondUsages = <int, List<Usage>>{}.obs;

  StreamSubscription<List<Product>>? _productSub;
  StreamSubscription<List<PondInfo>>? _pondSub;
  StreamSubscription<Map<int, List<Usage>>>? _usageSub;

  @override
  void onInit() {
    super.onInit();
    _repo.ensureSeedData();
    _productSub = _repo.watchProducts().listen(products.assignAll);
    _pondSub = _repo.watchPonds().listen(ponds.assignAll);
    _usageSub = _repo.watchAllUsages().listen((usageMap) {
      final cloned = <int, List<Usage>>{};
      usageMap.forEach((key, list) {
        cloned[key] = List<Usage>.from(list);
      });
      pondUsages.assignAll(cloned);
    });
  }

  @override
  void onClose() {
    _productSub?.cancel();
    _pondSub?.cancel();
    _usageSub?.cancel();
    super.onClose();
  }

  int get pondCount => ponds.length;

  PondInfo? pondInfo(int pondId) {
    return ponds.firstWhereOrNull((pond) => pond.id == pondId);
  }

  String pondName(int pondId) {
    return pondInfo(pondId)?.name ?? 'Pond $pondId';
  }

  Future<void> addPond(String name) {
    return _repo.createPond(name);
  }

  Future<void> renamePond(int pondId, String name) {
    return _repo.renamePond(pondId, name);
  }

  Future<bool> removePond(int pondId) {
    return _repo.deletePond(pondId);
  }

  List<Usage> usagesForPond(int pondId) {
    return List<Usage>.from(pondUsages[pondId] ?? const <Usage>[]);
  }

  double totalWeightForPond(int pondId) {
    return usagesForPond(pondId)
        .fold(0.0, (sum, usage) => sum + usage.weight);
  }

  double totalCostForPond(int pondId) {
    return usagesForPond(pondId)
        .fold(0.0, (sum, usage) => sum + usage.totalPrice);
  }

  Future<bool> addUsage(Usage usage) async {
    await _repo.addUsage(usage);
    return true;
  }

  Future<bool> updateUsage(Usage usage) {
    return _repo.updateUsage(usage);
  }

  Future<bool> removeUsage(String usageId) {
    return _repo.removeUsage(usageId);
  }

  Product? productByCode(String code) {
    return products.firstWhereOrNull((p) => p.code == code);
  }

  bool codeExists(String code) {
    return products.any((p) => p.code == code);
  }

  Future<bool> addProduct(Product product) async {
    if (codeExists(product.code)) {
      return false;
    }
    await _repo.addProduct(product);
    return true;
  }

  Future<bool> updateProduct(String originalCode, Product updated) async {
    if (originalCode != updated.code && codeExists(updated.code)) {
      return false;
    }
    try {
      await _repo.updateProduct(originalCode, updated);
      return true;
    } on StateError {
      return false;
    }
  }

  Future<bool> removeProduct(String code) async {
    await _repo.removeProduct(code);
    return true;
  }

  List<Product> productsByCategory(String? category) {
    if (category == null) return products.toList(growable: false);
    final lower = category.toLowerCase();
    return products
        .where((p) => p.category.toLowerCase() == lower)
        .toList(growable: false);
  }
}
