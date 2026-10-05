/// Model representing a Breed (Cattle Breed Type) in Ayushka Admin Portal.
class BreedModel {
  final String id;
  final String breedName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BreedModel({
    required this.id,
    required this.breedName,
    this.createdAt,
    this.updatedAt,
  });

  factory BreedModel.fromJson(Map<String, dynamic> json) {
    return BreedModel(
      id: (json['_id'] ?? json['id']) as String? ?? '',
      breedName: (json['breedName'] ?? json['name']) as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'breedName': breedName,
      if (id.isNotEmpty) '_id': id,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  BreedModel copyWith({
    String? id,
    String? breedName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BreedModel(
      id: id ?? this.id,
      breedName: breedName ?? this.breedName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
