/// Model representing a Gaushala (Cattle Farm) in Ayushka Admin Portal.
class GaushalaModel {
  final String id;
  final String gaushalaName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GaushalaModel({
    required this.id,
    required this.gaushalaName,
    this.createdAt,
    this.updatedAt,
  });

  factory GaushalaModel.fromJson(Map<String, dynamic> json) {
    return GaushalaModel(
      id: (json['_id'] ?? json['id']) as String? ?? '',
      gaushalaName: (json['gaushalaName'] ?? json['name']) as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gaushalaName': gaushalaName,
      if (id.isNotEmpty) '_id': id,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  GaushalaModel copyWith({
    String? id,
    String? gaushalaName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GaushalaModel(
      id: id ?? this.id,
      gaushalaName: gaushalaName ?? this.gaushalaName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
