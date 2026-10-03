/// Model representing a Department in Ayushka Admin Portal.
class WorkerStats {
  final int totalWorkers;
  final int activeWorkers;
  final int inactiveWorkers;

  const WorkerStats({
    this.totalWorkers = 0,
    this.activeWorkers = 0,
    this.inactiveWorkers = 0,
  });

  factory WorkerStats.fromJson(dynamic json) {
    if (json == null || json is! Map) {
      return const WorkerStats();
    }
    final m = Map<String, dynamic>.from(json);
    return WorkerStats(
      totalWorkers: (m['totalWorkers'] ?? m['total'] ?? m['count'] as num?)?.toInt() ?? 0,
      activeWorkers: (m['activeWorkers'] ?? m['active'] as num?)?.toInt() ?? 0,
      inactiveWorkers: (m['inactiveWorkers'] ?? m['inactive'] ?? m['left'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalWorkers': totalWorkers,
      'activeWorkers': activeWorkers,
      'inactiveWorkers': inactiveWorkers,
    };
  }
}

class DepartmentModel {
  final String id;
  final String gaushalaId;
  final String? gaushalaName;
  final String departmentName;
  final String departmentCode;
  final String description;
  final bool isActive;
  final WorkerStats workerStats;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DepartmentModel({
    required this.id,
    required this.gaushalaId,
    this.gaushalaName,
    required this.departmentName,
    required this.departmentCode,
    this.description = '',
    this.isActive = true,
    this.workerStats = const WorkerStats(),
    this.createdAt,
    this.updatedAt,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
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

    WorkerStats stats;
    if (json['workerStats'] != null) {
      stats = WorkerStats.fromJson(json['workerStats']);
    } else {
      stats = WorkerStats(
        totalWorkers: (json['totalWorkers'] as num?)?.toInt() ?? 0,
        activeWorkers: (json['activeWorkers'] as num?)?.toInt() ?? 0,
        inactiveWorkers: (json['inactiveWorkers'] as num?)?.toInt() ?? 0,
      );
    }

    return DepartmentModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      gaushalaId: gId,
      gaushalaName: gName,
      departmentName: (json['departmentName'] ?? json['name'])?.toString() ?? '',
      departmentCode: ((json['departmentCode'] ?? json['code'])?.toString() ?? '').toUpperCase(),
      description: (json['description'] ?? json['desc'])?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      workerStats: stats,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'gaushalaId': gaushalaId,
      'departmentName': departmentName,
      'departmentCode': departmentCode,
      'description': description,
      'isActive': isActive,
      'workerStats': workerStats.toJson(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  DepartmentModel copyWith({
    String? id,
    String? gaushalaId,
    String? gaushalaName,
    String? departmentName,
    String? departmentCode,
    String? description,
    bool? isActive,
    WorkerStats? workerStats,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DepartmentModel(
      id: id ?? this.id,
      gaushalaId: gaushalaId ?? this.gaushalaId,
      gaushalaName: gaushalaName ?? this.gaushalaName,
      departmentName: departmentName ?? this.departmentName,
      departmentCode: departmentCode ?? this.departmentCode,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      workerStats: workerStats ?? this.workerStats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
