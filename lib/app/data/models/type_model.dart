/// Model representing a Cattle Type (e.g. Milking, Dry, Pregnant, Heifer, Calf) in Ayushka Admin Portal.
class TypeModel {
  final String id;
  final String typeName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TypeModel({
    required this.id,
    required this.typeName,
    this.createdAt,
    this.updatedAt,
  });

  factory TypeModel.fromJson(Map<String, dynamic> json) {
    return TypeModel(
      id: (json['_id'] ?? json['id']) as String? ?? '',
      typeName: (json['typeName'] ?? json['name'] ?? json['type']) as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'typeName': typeName,
      if (id.isNotEmpty) '_id': id,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  TypeModel copyWith({
    String? id,
    String? typeName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TypeModel(
      id: id ?? this.id,
      typeName: typeName ?? this.typeName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
