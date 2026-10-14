/// Model representing a Cattle Type (e.g. Milking, Dry, Pregnant, Heifer, Calf) in Ayushka Admin Portal.
class TypeModel {
  final String id;
  final String typeName;
  final String? gaushalaId;
  final String? gaushalaName;
  final String tag; // "isFemale", "isMale", "both"
  final bool isFemale;
  final bool isMale;
  final String? gender;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TypeModel({
    required this.id,
    required this.typeName,
    this.gaushalaId,
    this.gaushalaName,
    this.tag = 'both',
    this.isFemale = true,
    this.isMale = true,
    this.gender,
    this.createdAt,
    this.updatedAt,
  });

  bool get isForFemale => isFemale || tag == 'isFemale' || tag == 'both';
  bool get isForMale => isMale || tag == 'isMale' || tag == 'both';
  bool get isForBoth => tag == 'both' || (isFemale && isMale);

  String get tagDisplayName {
    switch (tag.toLowerCase()) {
      case 'isfemale':
      case 'female':
        return 'Female';
      case 'ismale':
      case 'male':
        return 'Male';
      case 'both':
      default:
        return 'Both (M & F)';
    }
  }

  String get tagShortLabel {
    switch (tag.toLowerCase()) {
      case 'isfemale':
      case 'female':
        return 'Female';
      case 'ismale':
      case 'male':
        return 'Male';
      case 'both':
      default:
        return 'Both';
    }
  }

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

    final rawTag = json['tag']?.toString().trim();
    final rawGender = json['gender']?.toString().trim().toLowerCase();

    bool parsedIsFemale = false;
    bool parsedIsMale = false;

    if (json['isFemale'] != null) {
      parsedIsFemale = json['isFemale'] == true;
    }
    if (json['isMale'] != null) {
      parsedIsMale = json['isMale'] == true;
    }

    String resolvedTag = rawTag ?? '';
    if (resolvedTag.isEmpty) {
      if (rawGender == 'female') {
        resolvedTag = 'isFemale';
      } else if (rawGender == 'male') {
        resolvedTag = 'isMale';
      } else if (rawGender == 'both') {
        resolvedTag = 'both';
      } else if (parsedIsFemale && !parsedIsMale) {
        resolvedTag = 'isFemale';
      } else if (parsedIsMale && !parsedIsFemale) {
        resolvedTag = 'isMale';
      } else {
        resolvedTag = 'both';
      }
    }

    if (json['isFemale'] == null) {
      parsedIsFemale = resolvedTag == 'isFemale' || resolvedTag == 'both';
    }
    if (json['isMale'] == null) {
      parsedIsMale = resolvedTag == 'isMale' || resolvedTag == 'both';
    }

    return TypeModel(
      id: (json['_id'] ?? json['id']) as String? ?? '',
      typeName: (json['typeName'] ?? json['name'] ?? json['type']) as String? ?? '',
      gaushalaId: gId,
      gaushalaName: gName,
      tag: resolvedTag,
      isFemale: parsedIsFemale,
      isMale: parsedIsMale,
      gender: json['gender']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'typeName': typeName,
      'tag': tag,
      'isFemale': isFemale,
      'isMale': isMale,
      if (gender != null) 'gender': gender,
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
    String? tag,
    bool? isFemale,
    bool? isMale,
    String? gender,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TypeModel(
      id: id ?? this.id,
      typeName: typeName ?? this.typeName,
      gaushalaId: gaushalaId ?? this.gaushalaId,
      gaushalaName: gaushalaName ?? this.gaushalaName,
      tag: tag ?? this.tag,
      isFemale: isFemale ?? this.isFemale,
      isMale: isMale ?? this.isMale,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
