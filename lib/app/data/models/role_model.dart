/// Model representing a User Role in Ayushka Admin Portal.
class RoleModel {
  final String id;
  final String roleName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RoleModel({
    required this.id,
    required this.roleName,
    this.createdAt,
    this.updatedAt,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: (json['_id'] ?? json['id']) as String? ?? '',
      roleName: (json['roleName'] ?? json['name']) as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roleName': roleName,
      if (id.isNotEmpty) '_id': id,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  RoleModel copyWith({
    String? id,
    String? roleName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoleModel(
      id: id ?? this.id,
      roleName: roleName ?? this.roleName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
