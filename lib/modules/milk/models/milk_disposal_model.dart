import 'package:flutter/material.dart';
import 'package:ayushka/app/core/values/app_colors.dart';

/// Reasons for Disposing / Wasting Milk
enum DisposalReason {
  spoiled('spoiled', 'Spoiled / Curdled', AppColors.error, Icons.warning_rounded),
  sour('sour', 'Sour Taste / High Acidity', Color(0xFFF97316), Icons.report_problem_rounded),
  temperatureFailure('temperature_failure', 'Chiller / Temperature Failure', Color(0xFFEAB308), Icons.device_thermostat_rounded),
  contamination('contamination', 'Contamination Detected', AppColors.error, Icons.coronavirus_rounded),
  other('other', 'Other Reason', Color(0xFF6B7280), Icons.help_outline_rounded);

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const DisposalReason(this.value, this.label, this.color, this.icon);

  static DisposalReason fromString(String? val) {
    if (val == null) return DisposalReason.spoiled;
    final clean = val.trim().toLowerCase();
    return DisposalReason.values.firstWhere(
      (r) => r.value == clean,
      orElse: () => DisposalReason.spoiled,
    );
  }
}

/// Model representing a Spoiled Milk Disposal record
class MilkDisposalModel {
  final String id;
  final String gaushalaId;
  final String milkDate;
  final String disposalDate;
  final double quantity;
  final String reason;
  final String reportedBy;
  final String? reportedByName;
  final String? remarks;
  final DateTime? createdAt;

  const MilkDisposalModel({
    required this.id,
    required this.gaushalaId,
    required this.milkDate,
    required this.disposalDate,
    required this.quantity,
    required this.reason,
    required this.reportedBy,
    this.reportedByName,
    this.remarks,
    this.createdAt,
  });

  DisposalReason get disposalReasonEnum => DisposalReason.fromString(reason);

  static bool isMongoHexId(String? str) {
    if (str == null || str.trim().isEmpty) return false;
    return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(str.trim());
  }

  MilkDisposalModel copyWith({
    String? id,
    String? gaushalaId,
    String? milkDate,
    String? disposalDate,
    double? quantity,
    String? reason,
    String? reportedBy,
    String? reportedByName,
    String? remarks,
    DateTime? createdAt,
  }) {
    return MilkDisposalModel(
      id: id ?? this.id,
      gaushalaId: gaushalaId ?? this.gaushalaId,
      milkDate: milkDate ?? this.milkDate,
      disposalDate: disposalDate ?? this.disposalDate,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedByName: reportedByName ?? this.reportedByName,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MilkDisposalModel.fromJson(Map<String, dynamic> json) {
    // Handle reportedBy populated object or direct ID
    String rId = '';
    String? rName;

    void parseReporter(dynamic rep) {
      if (rep is Map) {
        rId = (rep['_id'] ?? rep['id'] ?? rId).toString();
        final name = (rep['name'] ?? rep['workerName'] ?? rep['worker_name'] ?? rep['fullName'])?.toString();
        if (name != null && name.isNotEmpty && !isMongoHexId(name)) rName = name;
      } else if (rep != null) {
        rId = rep.toString();
      }
    }

    if (json['reportedBy'] != null) {
      parseReporter(json['reportedBy']);
    } else if (json['reported_by'] != null) {
      parseReporter(json['reported_by']);
    } else if (json['worker'] != null) {
      parseReporter(json['worker']);
    } else if (json['user'] != null) {
      parseReporter(json['user']);
    }

    if (rName == null || rName!.isEmpty) {
      final fbName = json['reportedByName']?.toString() ??
          json['reported_by_name']?.toString() ??
          json['workerName']?.toString();
      if (fbName != null && !isMongoHexId(fbName) && !fbName.startsWith('Worker #')) {
        rName = fbName;
      }
    }

    return MilkDisposalModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      gaushalaId: json['gaushalaId']?.toString() ?? json['gaushala_id']?.toString() ?? '',
      milkDate: json['milkDate']?.toString() ?? json['milk_date']?.toString() ?? '',
      disposalDate: json['disposalDate']?.toString() ?? json['disposal_date']?.toString() ?? '',
      quantity: _toDouble(json['quantity']),
      reason: json['reason']?.toString() ?? 'spoiled',
      reportedBy: rId,
      reportedByName: rName,
      remarks: json['remarks']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gaushalaId': gaushalaId,
      'milkDate': milkDate,
      'disposalDate': disposalDate,
      'quantity': quantity,
      'reason': reason,
      'reportedBy': reportedBy,
      if (reportedByName != null) 'reportedByName': reportedByName,
      if (remarks != null) 'remarks': remarks,
    };
  }
}

/// Paginated result wrapper for Milk Disposal
class MilkDisposalPaginatedResult {
  final List<MilkDisposalModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const MilkDisposalPaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory MilkDisposalPaginatedResult.empty() {
    return const MilkDisposalPaginatedResult(
      items: [],
      total: 0,
      page: 1,
      limit: 10,
      totalPages: 1,
    );
  }
}

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}
