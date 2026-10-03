/// Model representing a Farm Worker in Ayushka Admin Portal.
class WorkerModel {
  final String id;
  final String gaushalaId;
  final String? gaushalaName;
  final String departmentId;
  final String? departmentName;
  final String? departmentCode;
  final String name;
  final DateTime? joiningDate;
  final DateTime? leavingDate;
  final bool isActive;
  final bool isDelete;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WorkerModel({
    required this.id,
    required this.gaushalaId,
    this.gaushalaName,
    required this.departmentId,
    this.departmentName,
    this.departmentCode,
    required this.name,
    this.joiningDate,
    this.leavingDate,
    this.isActive = true,
    this.isDelete = false,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    String gId = '';
    String? gName;

    if (json['gaushalaId'] != null) {
      if (json['gaushalaId'] is Map) {
        final m = json['gaushalaId'] as Map;
        gId = (m['_id'] ?? m['id'])?.toString() ?? '';
        gName = (m['gaushalaName'] ?? m['name'])?.toString();
      } else {
        gId = json['gaushalaId'].toString();
      }
    } else if (json['gaushala_id'] != null) {
      if (json['gaushala_id'] is Map) {
        final m = json['gaushala_id'] as Map;
        gId = (m['_id'] ?? m['id'])?.toString() ?? '';
        gName = (m['gaushalaName'] ?? m['name'])?.toString();
      } else {
        gId = json['gaushala_id'].toString();
      }
    } else if (json['gaushala'] != null) {
      if (json['gaushala'] is Map) {
        final m = json['gaushala'] as Map;
        gId = (m['_id'] ?? m['id'])?.toString() ?? '';
        gName = (m['gaushalaName'] ?? m['name'])?.toString();
      } else {
        gId = json['gaushala'].toString();
      }
    }

    if (gName == null && json['gaushalaName'] != null) {
      gName = json['gaushalaName']?.toString();
    }

    String dId = '';
    String? dName;
    String? dCode;

    if (json['departmentId'] != null) {
      if (json['departmentId'] is Map) {
        final m = json['departmentId'] as Map;
        dId = (m['_id'] ?? m['id'])?.toString() ?? '';
        dName = (m['departmentName'] ?? m['name'])?.toString();
        dCode = (m['departmentCode'] ?? m['code'])?.toString();
      } else {
        dId = json['departmentId'].toString();
      }
    } else if (json['department_id'] != null) {
      if (json['department_id'] is Map) {
        final m = json['department_id'] as Map;
        dId = (m['_id'] ?? m['id'])?.toString() ?? '';
        dName = (m['departmentName'] ?? m['name'])?.toString();
        dCode = (m['departmentCode'] ?? m['code'])?.toString();
      } else {
        dId = json['department_id'].toString();
      }
    } else if (json['department'] != null) {
      if (json['department'] is Map) {
        final m = json['department'] as Map;
        dId = (m['_id'] ?? m['id'])?.toString() ?? '';
        dName = (m['departmentName'] ?? m['name'])?.toString();
        dCode = (m['departmentCode'] ?? m['code'])?.toString();
      } else {
        dId = json['department'].toString();
      }
    }

    if (dName == null && json['departmentName'] != null) {
      dName = json['departmentName']?.toString();
    }
    if (dCode == null && json['departmentCode'] != null) {
      dCode = json['departmentCode']?.toString();
    }

    return WorkerModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      gaushalaId: gId,
      gaushalaName: gName,
      departmentId: dId,
      departmentName: dName,
      departmentCode: dCode,
      name: (json['name'] ?? json['workerName'])?.toString() ?? '',
      joiningDate: json['joiningDate'] != null ? DateTime.tryParse(json['joiningDate'].toString()) : null,
      leavingDate: json['leavingDate'] != null ? DateTime.tryParse(json['leavingDate'].toString()) : null,
      isActive: json['isActive'] as bool? ?? (json['status'] == 'active' || json['status'] == true),
      isDelete: json['isDelete'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'gaushalaId': gaushalaId,
      'departmentId': departmentId,
      'name': name,
      if (joiningDate != null) 'joiningDate': joiningDate!.toUtc().toIso8601String(),
      if (leavingDate != null) 'leavingDate': leavingDate!.toUtc().toIso8601String(),
      'isActive': isActive,
      'isDelete': isDelete,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  WorkerModel copyWith({
    String? id,
    String? gaushalaId,
    String? gaushalaName,
    String? departmentId,
    String? departmentName,
    String? departmentCode,
    String? name,
    DateTime? joiningDate,
    DateTime? leavingDate,
    bool? isActive,
    bool? isDelete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkerModel(
      id: id ?? this.id,
      gaushalaId: gaushalaId ?? this.gaushalaId,
      gaushalaName: gaushalaName ?? this.gaushalaName,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      departmentCode: departmentCode ?? this.departmentCode,
      name: name ?? this.name,
      joiningDate: joiningDate ?? this.joiningDate,
      leavingDate: leavingDate ?? this.leavingDate,
      isActive: isActive ?? this.isActive,
      isDelete: isDelete ?? this.isDelete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Paginated Result wrapper for workers list
class WorkerPaginatedResult {
  final List<WorkerModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const WorkerPaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });
}
