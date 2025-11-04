class PondInfo {
  final int id;
  final String name;
  final bool isCore;

  const PondInfo({required this.id, required this.name, this.isCore = false});

  PondInfo copyWith({int? id, String? name, bool? isCore}) {
    return PondInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      isCore: isCore ?? this.isCore,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isCore': isCore,
    };
  }

  factory PondInfo.fromMap(Map<String, dynamic> map) {
    final dynamic rawId = map['id'];
    final int resolvedId;
    if (rawId is int) {
      resolvedId = rawId;
    } else if (rawId is num) {
      resolvedId = rawId.toInt();
    } else if (rawId is String) {
      resolvedId = int.tryParse(rawId) ?? 0;
    } else {
      resolvedId = 0;
    }
    return PondInfo(
      id: resolvedId,
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? map['name'] as String
          : 'Pond $resolvedId',
      isCore: map['isCore'] as bool? ?? false,
    );
  }
}
