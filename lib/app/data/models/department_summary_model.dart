/// Model representing department breakdown in summary metrics.
class DepartmentBreakdownItem {
  final String departmentId;
  final String departmentName;
  final String departmentCode;
  final int totalWorkers;
  final int activeWorkers;
  final int inactiveWorkers;

  const DepartmentBreakdownItem({
    required this.departmentId,
    required this.departmentName,
    required this.departmentCode,
    this.totalWorkers = 0,
    this.activeWorkers = 0,
    this.inactiveWorkers = 0,
  });

  factory DepartmentBreakdownItem.fromJson(Map<String, dynamic> json) {
    return DepartmentBreakdownItem(
      departmentId: (json['departmentId'] ?? json['_id'] ?? json['id'])?.toString() ?? '',
      departmentName: (json['departmentName'] ?? json['name'])?.toString() ?? '',
      departmentCode: ((json['departmentCode'] ?? json['code'])?.toString() ?? '').toUpperCase(),
      totalWorkers: (json['totalWorkers'] ?? json['total'] ?? json['count'] as num?)?.toInt() ?? 0,
      activeWorkers: (json['activeWorkers'] ?? json['active'] as num?)?.toInt() ?? 0,
      inactiveWorkers: (json['inactiveWorkers'] ?? json['inactive'] ?? json['left'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'departmentId': departmentId,
      'departmentName': departmentName,
      'departmentCode': departmentCode,
      'totalWorkers': totalWorkers,
      'activeWorkers': activeWorkers,
      'inactiveWorkers': inactiveWorkers,
    };
  }
}

/// Model representing the overall Department & Worker Summary metrics.
class DepartmentSummaryModel {
  final int totalDepartments;
  final int totalWorkers;
  final int activeWorkers;
  final int inactiveWorkers;
  final List<DepartmentBreakdownItem> departmentBreakdown;

  const DepartmentSummaryModel({
    this.totalDepartments = 0,
    this.totalWorkers = 0,
    this.activeWorkers = 0,
    this.inactiveWorkers = 0,
    this.departmentBreakdown = const [],
  });

  factory DepartmentSummaryModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : (json['data'] is Map)
            ? Map<String, dynamic>.from(json['data'] as Map)
            : json;

    final List<DepartmentBreakdownItem> breakdowns = [];
    final rawBreakdown = data['departmentBreakdown'] ??
        data['breakdown'] ??
        data['departments'] ??
        data['departmentStats'];

    if (rawBreakdown is List) {
      for (final item in rawBreakdown) {
        if (item is Map) {
          breakdowns.add(DepartmentBreakdownItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final totalDepts = (data['totalDepartments'] ?? data['departmentCount'] as num?)?.toInt() ??
        (breakdowns.isNotEmpty ? breakdowns.length : 0);

    final totalW = (data['totalWorkers'] ?? data['overallWorkers'] ?? data['total'] as num?)?.toInt() ??
        (breakdowns.isNotEmpty ? breakdowns.fold<int>(0, (sum, b) => sum + b.totalWorkers) : 0);

    final activeW = (data['activeWorkers'] ?? data['active'] as num?)?.toInt() ??
        (breakdowns.isNotEmpty ? breakdowns.fold<int>(0, (sum, b) => sum + b.activeWorkers) : 0);

    final inactiveW = (data['inactiveWorkers'] ?? data['inactive'] ?? data['leftWorkers'] ?? data['left'] as num?)?.toInt() ??
        (breakdowns.isNotEmpty ? breakdowns.fold<int>(0, (sum, b) => sum + b.inactiveWorkers) : (totalW - activeW));

    return DepartmentSummaryModel(
      totalDepartments: totalDepts,
      totalWorkers: totalW,
      activeWorkers: activeW,
      inactiveWorkers: inactiveW,
      departmentBreakdown: breakdowns,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDepartments': totalDepartments,
      'totalWorkers': totalWorkers,
      'activeWorkers': activeWorkers,
      'inactiveWorkers': inactiveWorkers,
      'departmentBreakdown': departmentBreakdown.map((b) => b.toJson()).toList(),
    };
  }
}
