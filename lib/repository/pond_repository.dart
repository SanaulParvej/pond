import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

import '../models/pond_info.dart';
import '../models/product.dart';
import '../models/usage.dart';

class PondRepository {
  PondRepository._internal({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final PondRepository instance = PondRepository._internal();

  FirebaseFirestore _firestore;

  static const _productsCollection = 'products';
  static const _pondsCollection = 'ponds';
  static const _usagesCollection = 'usages';

  @visibleForTesting
  void configureFirestore(FirebaseFirestore firestore) {
    _firestore = firestore;
  }

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection(_productsCollection);

  CollectionReference<Map<String, dynamic>> get _pondsRef =>
      _firestore.collection(_pondsCollection);

  CollectionReference<Map<String, dynamic>> get _usagesRef =>
      _firestore.collection(_usagesCollection);

  Future<void> ensureSeedData() async {
    final snapshot = await _pondsRef.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    for (var i = 1; i <= 6; i++) {
      final doc = _pondsRef.doc('pond_$i');
      batch.set(doc, {
        'id': i,
        'name': 'Pond $i',
        'isCore': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Stream<List<Product>> watchProducts() {
    return _productsRef.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data()))
          .toList(growable: false);
    });
  }

  Future<void> addProduct(Product product) async {
    final doc = _productsRef.doc(product.code);
    await doc.set(
      {
        ...product.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateProduct(String originalCode, Product updated) async {
    if (originalCode == updated.code) {
      await _productsRef.doc(originalCode).set(
        {
          ...updated.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return;
    }

    await _firestore.runTransaction((transaction) async {
      final newDoc = _productsRef.doc(updated.code);
      final newSnapshot = await transaction.get(newDoc);
      if (newSnapshot.exists) {
        throw StateError('Product code already exists');
      }
      transaction.set(newDoc, {
        ...updated.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.delete(_productsRef.doc(originalCode));
    });
  }

  Future<void> removeProduct(String code) async {
    await _productsRef.doc(code).delete();
  }

  Stream<List<PondInfo>> watchPonds() {
    return _pondsRef.orderBy('id').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PondInfo.fromMap(doc.data()))
          .toList(growable: false);
    });
  }

  Future<int> _nextPondId() async {
    final snapshot = await _pondsRef.orderBy('id', descending: true).limit(1).get();
    if (snapshot.docs.isEmpty) return 1;
    final data = snapshot.docs.first.data();
    final current = data['id'];
    if (current is num) return current.toInt() + 1;
    if (current is String) {
      final parsed = int.tryParse(current);
      if (parsed != null) return parsed + 1;
    }
    return 1;
  }

  Future<PondInfo> createPond(String name) async {
    final trimmed = name.trim();
    final resolvedName = trimmed.isEmpty
        ? 'Pond ${DateTime.now().millisecondsSinceEpoch}'
        : trimmed;
    final id = await _nextPondId();
    final doc = _pondsRef.doc('pond_$id');
    final payload = {
      'id': id,
      'name': resolvedName,
      'isCore': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await doc.set(payload);
    return PondInfo.fromMap(payload);
  }

  Future<void> renamePond(int pondId, String name) async {
    final doc = _pondsRef.doc('pond_$pondId');
    await doc.set(
      {
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<bool> deletePond(int pondId) async {
    final doc = _pondsRef.doc('pond_$pondId');
    final snapshot = await doc.get();
    if (!snapshot.exists) return false;
    final info = PondInfo.fromMap(snapshot.data() ?? {});
    if (info.isCore) {
      return false;
    }

    final batch = _firestore.batch();
    batch.delete(doc);

    final usagesSnapshot = await _usagesRef.where('pondId', isEqualTo: pondId).get();
    for (final usageDoc in usagesSnapshot.docs) {
      batch.delete(usageDoc.reference);
    }

    await batch.commit();
    return true;
  }

  Stream<Map<int, List<Usage>>> watchAllUsages() {
    return _usagesRef.orderBy('date', descending: true).snapshots().map((snapshot) {
      final result = <int, List<Usage>>{};
      for (final doc in snapshot.docs) {
        final usage = Usage.fromMap(doc.data(), id: doc.id);
        result.putIfAbsent(usage.pondId, () => <Usage>[]).add(usage);
      }
      for (final entry in result.entries) {
        entry.value.sort((a, b) => b.date.compareTo(a.date));
      }
      return result;
    });
  }

  Future<void> addUsage(Usage usage) async {
    await _usagesRef.add({
      ...usage.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> updateUsage(Usage usage) async {
    final usageId = usage.id;
    if (usageId == null) return false;
    await _usagesRef.doc(usageId).set(
      {
        ...usage.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    return true;
  }

  Future<bool> removeUsage(String usageId) async {
    final doc = _usagesRef.doc(usageId);
    final snapshot = await doc.get();
    if (!snapshot.exists) {
      return false;
    }
    await doc.delete();
    return true;
  }

  Future<Product?> productByCode(String code) async {
    final doc = await _productsRef.doc(code).get();
    if (!doc.exists) return null;
    return Product.fromMap(doc.data() ?? {});
  }
}

