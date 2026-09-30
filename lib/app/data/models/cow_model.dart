/// Model representing the Add Cow API request body for POST /api/v1/cows.
class AddCowRequestModel {
  final String breed;
  final String gaushalaId;
  final String type;
  final String? shedId;
  final String tagId;
  final String? dob;
  final String? calfName;
  final bool isFemale;
  final String addedBy;
  final num calfWeight;
  final String avatarUrl;
  final String? damId;
  final String? sairId;
  final String? deliveryTime;
  final String? sendDiedDate;
  final String? purchaseDate;
  final String? remark;

  const AddCowRequestModel({
    required this.breed,
    required this.gaushalaId,
    required this.type,
    this.shedId,
    required this.tagId,
    this.dob,
    this.calfName,
    required this.isFemale,
    required this.addedBy,
    this.calfWeight = 0,
    this.avatarUrl = '',
    this.damId,
    this.sairId,
    this.deliveryTime,
    this.sendDiedDate,
    this.purchaseDate,
    this.remark,
  });

  Map<String, dynamic> toJson() {
    return {
      'breed': breed,
      'gaushala_id': gaushalaId,
      'type': type,
      'tag_id': tagId.trim().toUpperCase(),
      'isFemale': isFemale,
      'addedBy': addedBy,
      'calf_weight': calfWeight,
      'avatarUrl': avatarUrl,
      if (shedId != null && shedId!.isNotEmpty) 'shed_id': shedId,
      if (dob != null && dob!.isNotEmpty) 'dob': dob,
      if (calfName != null && calfName!.isNotEmpty) 'calf_name': calfName,
      if (damId != null && damId!.isNotEmpty) 'dam_id': damId,
      if (sairId != null && sairId!.isNotEmpty) 'sair_id': sairId,
      if (deliveryTime != null && deliveryTime!.isNotEmpty) 'delivery_time': deliveryTime,
      'send_died_date': sendDiedDate ?? '',
      if (purchaseDate != null && purchaseDate!.isNotEmpty) 'purchase_date': purchaseDate,
      if (remark != null && remark!.isNotEmpty) 'remark': remark,
    };
  }
}

/// Model representing a Cow returned from the backend API responses.
class CowModel {
  final String id;
  final String tagId;
  final String? calfName;
  final bool isFemale;
  final bool isDeleted;
  final bool isDied;
  final bool isActive;
  final num calfWeight;
  final String? avatarUrl;
  final String? dob;
  final String? deliveryTime;
  final String? sendDiedDate;
  final String? purchaseDate;
  final String? remark;

  // Helper getters
  bool get isDelete => isDeleted;
  bool get isDead => isDied || (sendDiedDate != null && sendDiedDate!.trim().isNotEmpty);
  bool get canEdit => !isDelete && !isDeleted && !isDead && !isDied;

  /// Status hierarchy:
  /// 1. Delete -> "Deleted"
  /// 2. Died -> "Died"
  /// 3. InActive -> "InActive"
  /// 4. Active -> "Active"
  String get statusDisplay {
    if (isDelete || isDeleted) {
      return 'Deleted';
    }
    if (isDied || isDead) {
      return 'Died';
    }
    if (!isActive) {
      return 'InActive';
    }
    return 'Active';
  }

  // Nested populated references
  final CowBreedRef? breed;
  final CowGaushalaRef? gaushala;
  final CowTypeRef? cowType;
  final CowShedRef? shed;
  final CowUserRef? addedBy;
  final CowParentRef? dam;
  final CowParentRef? sire;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CowModel({
    required this.id,
    required this.tagId,
    this.calfName,
    this.isFemale = true,
    this.isDeleted = false,
    this.isDied = false,
    this.isActive = true,
    this.calfWeight = 0,
    this.avatarUrl,
    this.dob,
    this.deliveryTime,
    this.sendDiedDate,
    this.purchaseDate,
    this.remark,
    this.breed,
    this.gaushala,
    this.cowType,
    this.shed,
    this.addedBy,
    this.dam,
    this.sire,
    this.createdAt,
    this.updatedAt,
  });

  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes') return true;
      if (v == 'false' || v == '0' || v == 'no') return false;
    }
    return defaultValue;
  }

  factory CowModel.fromJson(Map<String, dynamic> json) {
    final bool parsedIsDeleted = _parseBool(json['isDelete']) ||
        _parseBool(json['isDeleted']) ||
        _parseBool(json['is_delete']) ||
        _parseBool(json['is_deleted']) ||
        (json['status'] != null && json['status'].toString().trim().toLowerCase() == 'deleted');

    final bool hasDiedDate = (json['send_died_date'] != null && json['send_died_date'].toString().trim().isNotEmpty) ||
        (json['sendDiedDate'] != null && json['sendDiedDate'].toString().trim().isNotEmpty);

    final bool parsedIsDied = _parseBool(json['isDied']) ||
        _parseBool(json['is_died']) ||
        _parseBool(json['isDead']) ||
        (json['status'] != null &&
            (json['status'].toString().trim().toLowerCase() == 'died' ||
                json['status'].toString().trim().toLowerCase() == 'death' ||
                json['status'].toString().trim().toLowerCase() == 'deceased')) ||
        hasDiedDate;

    final bool parsedIsActive = json['isActive'] != null
        ? _parseBool(json['isActive'], defaultValue: true)
        : (json['is_active'] != null
            ? _parseBool(json['is_active'], defaultValue: true)
            : (json['status'] != null && json['status'].toString().trim().toLowerCase() == 'inactive' ? false : true));

    return CowModel(
      id: (json['_id'] ?? json['id']) as String? ?? '',
      tagId: (json['tag_id'] as String? ?? '').toUpperCase(),
      calfName: json['calf_name'] as String?,
      isFemale: json['isFemale'] as bool? ?? true,
      isDeleted: parsedIsDeleted,
      isDied: parsedIsDied,
      isActive: parsedIsActive,
      calfWeight: json['calf_weight'] as num? ?? 0,
      avatarUrl: json['avatarUrl'] as String?,
      dob: json['dob'] as String?,
      deliveryTime: json['delivery_time'] as String?,
      sendDiedDate: json['send_died_date'] as String?,
      purchaseDate: json['purchase_date'] as String?,
      remark: json['remark'] as String?,
      breed: json['breed'] is Map
          ? CowBreedRef.fromJson(Map<String, dynamic>.from(json['breed'] as Map))
          : null,
      gaushala: json['gaushala_id'] is Map
          ? CowGaushalaRef.fromJson(Map<String, dynamic>.from(json['gaushala_id'] as Map))
          : null,
      cowType: json['type'] is Map
          ? CowTypeRef.fromJson(Map<String, dynamic>.from(json['type'] as Map))
          : null,
      shed: json['shed_id'] is Map
          ? CowShedRef.fromJson(Map<String, dynamic>.from(json['shed_id'] as Map))
          : null,
      addedBy: json['addedBy'] is Map
          ? CowUserRef.fromJson(Map<String, dynamic>.from(json['addedBy'] as Map))
          : null,
      dam: json['dam_id'] is Map
          ? CowParentRef.fromJson(Map<String, dynamic>.from(json['dam_id'] as Map))
          : null,
      sire: json['sair_id'] is Map
          ? CowParentRef.fromJson(Map<String, dynamic>.from(json['sair_id'] as Map))
          : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  CowModel copyWith({
    String? id,
    String? tagId,
    String? calfName,
    bool? isFemale,
    bool? isDeleted,
    bool? isDied,
    bool? isActive,
    num? calfWeight,
    String? avatarUrl,
    String? dob,
    String? deliveryTime,
    String? sendDiedDate,
    String? purchaseDate,
    String? remark,
    CowBreedRef? breed,
    CowGaushalaRef? gaushala,
    CowTypeRef? cowType,
    CowShedRef? shed,
    CowUserRef? addedBy,
    CowParentRef? dam,
    CowParentRef? sire,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CowModel(
      id: id ?? this.id,
      tagId: tagId ?? this.tagId,
      calfName: calfName ?? this.calfName,
      isFemale: isFemale ?? this.isFemale,
      isDeleted: isDeleted ?? this.isDeleted,
      isDied: isDied ?? this.isDied,
      isActive: isActive ?? this.isActive,
      calfWeight: calfWeight ?? this.calfWeight,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dob: dob ?? this.dob,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      sendDiedDate: sendDiedDate ?? this.sendDiedDate,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      remark: remark ?? this.remark,
      breed: breed ?? this.breed,
      gaushala: gaushala ?? this.gaushala,
      cowType: cowType ?? this.cowType,
      shed: shed ?? this.shed,
      addedBy: addedBy ?? this.addedBy,
      dam: dam ?? this.dam,
      sire: sire ?? this.sire,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CowModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Nested breed reference in cow response.
class CowBreedRef {
  final String id;
  final String breedName;

  const CowBreedRef({required this.id, required this.breedName});

  factory CowBreedRef.fromJson(Map<String, dynamic> json) {
    return CowBreedRef(
      id: (json['_id'] ?? json['id']) as String? ?? '',
      breedName: json['breedName'] as String? ?? '',
    );
  }
}

/// Nested gaushala reference in cow response.
class CowGaushalaRef {
  final String id;
  final String gaushalaName;

  const CowGaushalaRef({required this.id, required this.gaushalaName});

  factory CowGaushalaRef.fromJson(Map<String, dynamic> json) {
    return CowGaushalaRef(
      id: (json['_id'] ?? json['id']) as String? ?? '',
      gaushalaName: json['gaushalaName'] as String? ?? '',
    );
  }
}

/// Nested type reference in cow response.
class CowTypeRef {
  final String id;
  final String typeName;

  const CowTypeRef({required this.id, required this.typeName});

  factory CowTypeRef.fromJson(Map<String, dynamic> json) {
    return CowTypeRef(
      id: (json['_id'] ?? json['id']) as String? ?? '',
      typeName: json['typeName'] as String? ?? '',
    );
  }
}

/// Nested shed reference in cow response.
class CowShedRef {
  final String id;
  final String shedName;
  final String shedNumber;

  const CowShedRef({required this.id, required this.shedName, required this.shedNumber});

  factory CowShedRef.fromJson(Map<String, dynamic> json) {
    return CowShedRef(
      id: (json['_id'] ?? json['id']) as String? ?? '',
      shedName: json['shedName'] as String? ?? '',
      shedNumber: json['shedNumber'] as String? ?? '',
    );
  }
}

/// Nested user reference in cow response.
class CowUserRef {
  final String id;
  final String name;
  final String username;

  const CowUserRef({required this.id, required this.name, required this.username});

  factory CowUserRef.fromJson(Map<String, dynamic> json) {
    return CowUserRef(
      id: (json['_id'] ?? json['id']) as String? ?? '',
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
    );
  }
}

/// Nested parent cow reference (dam/sire) in cow response.
class CowParentRef {
  final String id;
  final String tagId;

  const CowParentRef({required this.id, required this.tagId});

  factory CowParentRef.fromJson(Map<String, dynamic> json) {
    return CowParentRef(
      id: (json['_id'] ?? json['id']) as String? ?? '',
      tagId: (json['tag_id'] as String? ?? '').toUpperCase(),
    );
  }
}

/// Statistics counts returned by GET /api/v1/cows.
class CowCounts {
  final int total;
  final int female;
  final int male;
  final int cow;
  final int bull;

  const CowCounts({
    this.total = 0,
    this.female = 0,
    this.male = 0,
    this.cow = 0,
    this.bull = 0,
  });

  factory CowCounts.fromJson(Map<String, dynamic> json) {
    return CowCounts(
      total: (json['total'] as num?)?.toInt() ?? 0,
      female: (json['female'] as num?)?.toInt() ?? 0,
      male: (json['male'] as num?)?.toInt() ?? 0,
      cow: (json['cow'] as num?)?.toInt() ?? 0,
      bull: (json['bull'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'female': female,
    'male': male,
    'cow': cow,
    'bull': bull,
  };
}

/// Response model for GET /api/v1/cows list endpoint.
class CowListResponse {
  final int total;
  final int femaleCount;
  final int maleCount;
  final CowCounts counts;
  final List<CowModel> female;
  final List<CowModel> male;
  final List<CowModel> allCows;

  const CowListResponse({
    this.total = 0,
    this.femaleCount = 0,
    this.maleCount = 0,
    this.counts = const CowCounts(),
    this.female = const [],
    this.male = const [],
    this.allCows = const [],
  });

  factory CowListResponse.fromJson(Map<String, dynamic> json) {
    final countsMap = json['counts'] is Map
        ? Map<String, dynamic>.from(json['counts'] as Map)
        : <String, dynamic>{};
    final counts = CowCounts.fromJson(countsMap);

    final List<CowModel> femaleList = [];
    if (json['female'] is List) {
      for (final item in json['female'] as List) {
        if (item is Map) {
          femaleList.add(CowModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final List<CowModel> maleList = [];
    if (json['male'] is List) {
      for (final item in json['male'] as List) {
        if (item is Map) {
          maleList.add(CowModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final List<CowModel> directCows = [];
    if (json['cows'] is List) {
      for (final item in json['cows'] as List) {
        if (item is Map) {
          directCows.add(CowModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final List<CowModel> combined = [
      ...femaleList,
      ...maleList,
      ...directCows,
    ];

    return CowListResponse(
      total: (json['total'] as num?)?.toInt() ?? combined.length,
      femaleCount: (json['femaleCount'] as num?)?.toInt() ?? femaleList.length,
      maleCount: (json['maleCount'] as num?)?.toInt() ?? maleList.length,
      counts: counts,
      female: femaleList,
      male: maleList,
      allCows: combined,
    );
  }
}

