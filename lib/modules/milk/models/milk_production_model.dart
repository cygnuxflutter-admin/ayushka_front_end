import 'package:flutter/material.dart';

/// Shift types for Milk Production
enum MilkShift {
  morning('morning', 'Morning', Color(0xFFE98324), Icons.wb_sunny_rounded),
  evening('evening', 'Evening', Color(0xFF384C28), Icons.nights_stay_rounded),
  all('all', 'All Shifts', Color(0xFF5A7542), Icons.timelapse_rounded);

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const MilkShift(this.value, this.label, this.color, this.icon);

  static MilkShift fromString(String? val) {
    if (val == null) return MilkShift.morning;
    final clean = val.trim().toLowerCase();
    return MilkShift.values.firstWhere(
      (s) => s.value == clean,
      orElse: () => MilkShift.morning,
    );
  }
}

/// Model representing a single Milk Production entry
class MilkProductionModel {
  final String id;
  final String gaushalaId;
  final String date;
  final String shift;
  final String cowId;
  final String cowTag;
  final String? cowName;
  final String workerId;
  final String? workerName;
  final double quantity;
  final String? remarks;
  final double? variance;
  final bool alertGenerated;
  final DateTime? createdAt;

  const MilkProductionModel({
    required this.id,
    required this.gaushalaId,
    required this.date,
    required this.shift,
    required this.cowId,
    required this.cowTag,
    this.cowName,
    required this.workerId,
    this.workerName,
    required this.quantity,
    this.remarks,
    this.variance,
    this.alertGenerated = false,
    this.createdAt,
  });

  bool get isMorning => shift.toLowerCase() == 'morning';
  bool get isEvening => shift.toLowerCase() == 'evening';

  MilkShift get milkShift => MilkShift.fromString(shift);

  static bool isMongoHexId(String? str) {
    if (str == null || str.trim().isEmpty) return false;
    return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(str.trim());
  }

  String get displayCowTitle {
    final hasValidName = cowName != null && cowName!.trim().isNotEmpty && !isMongoHexId(cowName);
    final hasValidTag = cowTag.trim().isNotEmpty && !isMongoHexId(cowTag);

    if (hasValidTag && hasValidName) {
      return '$cowTag ($cowName)';
    } else if (hasValidName) {
      return cowName!;
    } else if (hasValidTag) {
      return cowTag;
    }
    return 'Cattle Record';
  }

  MilkProductionModel copyWith({
    String? id,
    String? gaushalaId,
    String? date,
    String? shift,
    String? cowId,
    String? cowTag,
    String? cowName,
    String? workerId,
    String? workerName,
    double? quantity,
    String? remarks,
    double? variance,
    bool? alertGenerated,
    DateTime? createdAt,
  }) {
    return MilkProductionModel(
      id: id ?? this.id,
      gaushalaId: gaushalaId ?? this.gaushalaId,
      date: date ?? this.date,
      shift: shift ?? this.shift,
      cowId: cowId ?? this.cowId,
      cowTag: cowTag ?? this.cowTag,
      cowName: cowName ?? this.cowName,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      quantity: quantity ?? this.quantity,
      remarks: remarks ?? this.remarks,
      variance: variance ?? this.variance,
      alertGenerated: alertGenerated ?? this.alertGenerated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MilkProductionModel.fromJson(Map<String, dynamic> json) {
    // Handle populated cow object or direct ID
    String cId = '';
    String cTag = '';
    String? cName;

    void parseCowData(dynamic cowData) {
      if (cowData is Map) {
        cId = (cowData['_id'] ?? cowData['id'] ?? cId).toString();
        final tag = (cowData['tagId'] ?? cowData['tag_id'] ?? cowData['tag'])?.toString();
        if (tag != null && tag.isNotEmpty && !isMongoHexId(tag)) cTag = tag;
        final name = (cowData['calfName'] ?? cowData['calf_name'] ?? cowData['name'] ?? cowData['cowName'] ?? cowData['cow_name'])?.toString();
        if (name != null && name.isNotEmpty && !isMongoHexId(name)) cName = name;
      } else if (cowData != null) {
        cId = cowData.toString();
      }
    }

    if (json['cow'] != null) {
      parseCowData(json['cow']);
    } else if (json['cowId'] != null) {
      parseCowData(json['cowId']);
    } else if (json['cow_id'] != null) {
      parseCowData(json['cow_id']);
    } else if (json['cow_details'] != null) {
      parseCowData(json['cow_details']);
    } else if (json['cowDetails'] != null) {
      parseCowData(json['cowDetails']);
    }

    if (cTag.isEmpty) {
      final fallbackTag = json['cowTag']?.toString() ??
          json['cow_tag']?.toString() ??
          json['cowTagId']?.toString() ??
          json['tagId']?.toString() ??
          json['tag_id']?.toString() ??
          json['tag']?.toString() ??
          '';
      if (!isMongoHexId(fallbackTag)) {
        cTag = fallbackTag;
      }
    }
    if (cName == null || cName!.isEmpty) {
      final fallbackName = json['cowName']?.toString() ??
          json['cow_name']?.toString() ??
          json['calfName']?.toString() ??
          json['calf_name']?.toString();
      if (fallbackName != null && !isMongoHexId(fallbackName)) {
        cName = fallbackName;
      }
    }

    // Handle populated worker object or direct ID
    String wId = '';
    String? wName;

    void parseWorkerData(dynamic workerData) {
      if (workerData is Map) {
        wId = (workerData['_id'] ?? workerData['id'] ?? wId).toString();
        final name = (workerData['name'] ?? workerData['workerName'] ?? workerData['worker_name'])?.toString();
        if (name != null && name.isNotEmpty && !isMongoHexId(name)) wName = name;
      } else if (workerData != null) {
        wId = workerData.toString();
      }
    }

    if (json['worker'] != null) {
      parseWorkerData(json['worker']);
    } else if (json['workerId'] != null) {
      parseWorkerData(json['workerId']);
    } else if (json['worker_id'] != null) {
      parseWorkerData(json['worker_id']);
    } else if (json['worker_details'] != null) {
      parseWorkerData(json['worker_details']);
    } else if (json['workerDetails'] != null) {
      parseWorkerData(json['workerDetails']);
    }

    if (wName == null || wName!.isEmpty) {
      final fallbackWorker = json['workerName']?.toString() ?? json['worker_name']?.toString() ?? json['name']?.toString();
      if (fallbackWorker != null && !isMongoHexId(fallbackWorker) && !fallbackWorker.startsWith('Worker #')) {
        wName = fallbackWorker;
      }
    }

    return MilkProductionModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      gaushalaId: json['gaushalaId']?.toString() ?? json['gaushala_id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      shift: json['shift']?.toString() ?? 'morning',
      cowId: cId,
      cowTag: cTag,
      cowName: cName,
      workerId: wId,
      workerName: wName,
      quantity: _toDouble(json['quantity']),
      remarks: json['remarks']?.toString(),
      variance: json['variance'] != null ? _toDouble(json['variance']) : null,
      alertGenerated: json['alertGenerated'] == true || json['alert_generated'] == true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gaushalaId': gaushalaId,
      'date': date,
      'shift': shift,
      'cowId': cowId,
      'cowTag': cowTag,
      if (cowName != null) 'cowName': cowName,
      'workerId': workerId,
      if (workerName != null) 'workerName': workerName,
      'quantity': quantity,
      if (remarks != null) 'remarks': remarks,
      if (variance != null) 'variance': variance,
      'alertGenerated': alertGenerated,
    };
  }
}

/// Bulk production entry item
class BulkProductionEntryItem {
  final String cowId;
  final String cowTag;
  final String? cowName;
  String workerId;
  double quantity;
  String? remarks;

  BulkProductionEntryItem({
    required this.cowId,
    required this.cowTag,
    this.cowName,
    this.workerId = '',
    this.quantity = 0.0,
    this.remarks,
  });

  Map<String, dynamic> toJson() {
    return {
      'cowId': cowId,
      'workerId': workerId,
      'quantity': quantity,
      if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
    };
  }
}

/// Paginated result wrapper for Milk Production
class MilkProductionPaginatedResult {
  final List<MilkProductionModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const MilkProductionPaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory MilkProductionPaginatedResult.empty() {
    return const MilkProductionPaginatedResult(
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
