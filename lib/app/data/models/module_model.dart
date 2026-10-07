/// Model representing a Sub-Module and Module in the Ayushka Admin Portal.
class SubModuleModel {
  final String id;
  final String name;
  final String code;
  final String description;
  final bool isActive;

  const SubModuleModel({
    this.id = '',
    required this.name,
    required this.code,
    this.description = '',
    this.isActive = true,
  });

  factory SubModuleModel.fromJson(Map<String, dynamic> json) {
    return SubModuleModel(
      id: (json['_id'] ?? json['id'] ?? '')?.toString() ?? '',
      name: (json['name'] ?? json['subModuleName'] ?? '')?.toString() ?? '',
      code: (json['code'] ?? json['subModuleCode'] ?? '')?.toString() ?? '',
      description: (json['description'] ?? '')?.toString() ?? '',
      isActive: json['isActive'] == null
          ? true
          : (json['isActive'] is bool
              ? json['isActive'] as bool
              : json['isActive'].toString().toLowerCase() == 'true'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'name': name,
      'code': code,
      if (description.isNotEmpty) 'description': description,
      'isActive': isActive,
    };
  }

  SubModuleModel copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    bool? isActive,
  }) {
    return SubModuleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}

class ModuleModel {
  final String id;
  final String name;
  final String code;
  final String description;
  final bool isActive;
  final List<SubModuleModel> subModules;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ModuleModel({
    this.id = '',
    required this.name,
    required this.code,
    this.description = '',
    this.isActive = true,
    this.subModules = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    final rawSubModules = json['subModules'] ?? json['sub_modules'];
    List<SubModuleModel> parsedSubModules = [];
    if (rawSubModules is List) {
      parsedSubModules = rawSubModules
          .whereType<Map>()
          .map((item) => SubModuleModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return ModuleModel(
      id: (json['_id'] ?? json['id'] ?? '')?.toString() ?? '',
      name: (json['name'] ?? json['moduleName'] ?? '')?.toString() ?? '',
      code: (json['code'] ?? json['moduleCode'] ?? '')?.toString() ?? '',
      description: (json['description'] ?? '')?.toString() ?? '',
      isActive: json['isActive'] == null
          ? true
          : (json['isActive'] is bool
              ? json['isActive'] as bool
              : json['isActive'].toString().toLowerCase() == 'true'),
      subModules: parsedSubModules,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'name': name,
      'code': code,
      if (description.isNotEmpty) 'description': description,
      'isActive': isActive,
      'subModules': subModules.map((s) => s.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  ModuleModel copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    bool? isActive,
    List<SubModuleModel>? subModules,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModuleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      subModules: subModules ?? this.subModules,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
