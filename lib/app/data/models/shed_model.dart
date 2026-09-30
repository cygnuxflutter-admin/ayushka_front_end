/// Model representing a Cattle Shed in Ayushka Admin Portal.
class ShedModel {
  final String id;
  final String shedName;
  final String shedNumber;
  final String? gaushalaId;
  final String? gaushalaName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShedModel({
    required this.id,
    required this.shedName,
    required this.shedNumber,
    this.gaushalaId,
    this.gaushalaName,
    this.createdAt,
    this.updatedAt,
  });

  factory ShedModel.fromJson(Map<String, dynamic> json) {
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

    return ShedModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      shedName: (json['shedName'] ?? json['name'])?.toString() ?? '',
      shedNumber: ((json['shedNumber'] ?? json['number'])?.toString() ?? '').toUpperCase(),
      gaushalaId: gId,
      gaushalaName: gName,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shedName': shedName,
      'shedNumber': shedNumber,
      if (gaushalaId != null && gaushalaId!.isNotEmpty) 'gaushalaId': gaushalaId,
      if (id.isNotEmpty) '_id': id,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  ShedModel copyWith({
    String? id,
    String? shedName,
    String? shedNumber,
    String? gaushalaId,
    String? gaushalaName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShedModel(
      id: id ?? this.id,
      shedName: shedName ?? this.shedName,
      shedNumber: shedNumber ?? this.shedNumber,
      gaushalaId: gaushalaId ?? this.gaushalaId,
      gaushalaName: gaushalaName ?? this.gaushalaName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
