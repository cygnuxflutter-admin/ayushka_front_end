/// Model representing a Cattle Type (e.g. Milking, Dry, Pregnant, Heifer, Calf) in Ayushka Admin Portal.
class TypeModel {
  final String id;
  final String typeName;
  final String? gaushalaId;
  final String? gaushalaName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TypeModel({
    required this.id,
    required this.typeName,
    this.gaushalaId,
    this.gaushalaName,
    this.createdAt,
    this.updatedAt,
  });

  factory TypeModel.fromJson(Map<String, dynamic> json) {
    String? gId;
    String? gName;

    if (json['gaushalaId'] != null) {
      if (json['gaushalaId'] is Map) {
        final m = json['gaushalaId'] as Map;
        gId = (m['_id'] ?? m['id'])?.toString();
        gName = (m['gaushalaName'] ?? m['name'])?.toString();
      } else {
        gId = json['gaushalaId']?.toString();
      }
    } else if (json['gaushala_id'] != null) {
      if (json['gaushala_id'] is Map) {
        final m = json['gaushala_id'] as Map;
        gId = (m['_id'] ?? m['id'])?.toString();
        gName = (m['gaushalaName'] ?? m['name'])?.toString();
      } else {
        gId = json['gaushala_id']?.toString();
      }
    } else if (json['gaushala'] != null) {
      if (json['gaushala'] is Map) {
        final m = json['gaushala'] as Map;
        gId = (m['_id'] ?? m['id'])?.toString();
        gName = (m['gaushalaName'] ?? m['name'])?.toString();
      } else {
        gId = json['gaushala']?.toString();
      }
    }

    if (gName == null && json['gaushalaName'] != null) {
      gName = json['gaushalaName']?.toString();
    }

    return TypeModel(
      id: (json['_id'] ?? json['id']) as String? ?? '',
      typeName: (json['typeName'] ?? json['name'] ?? json['type']) as String? ?? '',
      gaushalaId: gId,
      gaushalaName: gName,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'typeName': typeName,
      if (gaushalaId != null && gaushalaId!.isNotEmpty) 'gaushalaId': gaushalaId,
      if (id.isNotEmpty) '_id': id,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  TypeModel copyWith({
    String? id,
    String? typeName,
    String? gaushalaId,
    String? gaushalaName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TypeModel(
      id: id ?? this.id,
      typeName: typeName ?? this.typeName,
      gaushalaId: gaushalaId ?? this.gaushalaId,
      gaushalaName: gaushalaName ?? this.gaushalaName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
