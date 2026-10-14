import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Status of the detected Cow Heat cycle.
enum HeatStatus {
  observed('OBSERVED', 'Observed', Color(0xFF3B82F6), Color(0xFFEFF6FF), PhosphorIconsRegular.eye),
  readyForMating('READY_FOR_MATING', 'Ready for Mating', Color(0xFFF59E0B), Color(0xFFFFFBEB), PhosphorIconsRegular.heart),
  mated('MATED', 'Mated', Color(0xFF10B981), Color(0xFFECFDF5), PhosphorIconsRegular.checkCircle),
  missed('MISSED', 'Missed', Color(0xFFEF4444), Color(0xFFFEF2F2), PhosphorIconsRegular.warningCircle),
  expired('EXPIRED', 'Expired', Color(0xFF9CA3AF), Color(0xFFF3F4F6), PhosphorIconsRegular.clock);

  final String code;
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const HeatStatus(this.code, this.label, this.color, this.bgColor, this.icon);

  static HeatStatus fromCode(String? code) {
    if (code == null) return HeatStatus.observed;
    final upper = code.trim().toUpperCase();
    return HeatStatus.values.firstWhere(
      (s) => s.code == upper,
      orElse: () => HeatStatus.observed,
    );
  }
}

/// Stage in the estrus cycle when heat was observed.
enum HeatStage {
  early('EARLY', 'Early'),
  standing('STANDING', 'Standing (Peak)'),
  late('LATE', 'Late');

  final String code;
  final String label;

  const HeatStage(this.code, this.label);

  static HeatStage fromCode(String? code) {
    if (code == null) return HeatStage.standing;
    final upper = code.trim().toUpperCase();
    return HeatStage.values.firstWhere(
      (s) => s.code == upper,
      orElse: () => HeatStage.standing,
    );
  }
}

/// Clinical intensity of estrus signs.
enum HeatIntensity {
  mild('MILD', 'Mild', Color(0xFF10B981), Color(0xFFECFDF5)),
  moderate('MODERATE', 'Moderate', Color(0xFFF59E0B), Color(0xFFFFFBEB)),
  strong('STRONG', 'Strong', Color(0xFFEF4444), Color(0xFFFEF2F2));

  final String code;
  final String label;
  final Color color;
  final Color bgColor;

  const HeatIntensity(this.code, this.label, this.color, this.bgColor);

  static HeatIntensity fromCode(String? code) {
    if (code == null) return HeatIntensity.moderate;
    final upper = code.trim().toUpperCase();
    return HeatIntensity.values.firstWhere(
      (s) => s.code == upper,
      orElse: () => HeatIntensity.moderate,
    );
  }
}

/// Standardized estrus behavioral signs.
class HeatSignDefinition {
  final String code;
  final String label;

  const HeatSignDefinition(this.code, this.label);

  static const List<HeatSignDefinition> all = [
    HeatSignDefinition('MOUNTING', 'Standing to be Mounted / Mounting'),
    HeatSignDefinition('MUCUS_DISCHARGE', 'Clear Mucus Discharge'),
    HeatSignDefinition('BELLOWING', 'Frequent Bellowing / Vocalization'),
    HeatSignDefinition('RESTLESSNESS', 'Restlessness / Hyperactivity'),
    HeatSignDefinition('VULVA_SWELLING', 'Swollen & Reddened Vulva'),
    HeatSignDefinition('FREQUENT_URINATION', 'Frequent Urination'),
    HeatSignDefinition('REDUCED_APPETITE', 'Reduced Appetite / Milk Drop'),
    HeatSignDefinition('CHIN_RESTING', 'Chin Resting on Companions'),
    HeatSignDefinition('SNIFFING_GENITALS', 'Sniffing Genitals of Other Cows'),
  ];

  static String getLabel(String code) {
    final match = all.firstWhere(
      (s) => s.code == code.trim().toUpperCase(),
      orElse: () => HeatSignDefinition(code, code),
    );
    return match.label;
  }
}

/// Comprehensive model for Cow Heat Record.
class CowHeatModel {
  final String id;
  final String gaushalaId;
  final String? gaushalaName;
  final String cowId;
  final String cowTagId;
  final String? cowCalfName;
  final String? cowShedName;
  final String? cowBreedName;
  final DateTime? heatDate;
  final String? heatTime;
  final HeatStage heatStage;
  final List<String> heatSigns;
  final HeatIntensity intensity;
  final HeatStatus status;
  final String? observedByWorkerId;
  final String? observedByWorkerName;
  final String? remarks;
  final int consecutiveHeatCount;
  final bool isRepeatHeatAlert;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CowHeatModel({
    required this.id,
    required this.gaushalaId,
    this.gaushalaName,
    required this.cowId,
    required this.cowTagId,
    this.cowCalfName,
    this.cowShedName,
    this.cowBreedName,
    this.heatDate,
    this.heatTime,
    this.heatStage = HeatStage.standing,
    this.heatSigns = const [],
    this.intensity = HeatIntensity.moderate,
    this.status = HeatStatus.readyForMating,
    this.observedByWorkerId,
    this.observedByWorkerName,
    this.remarks,
    this.consecutiveHeatCount = 1,
    this.isRepeatHeatAlert = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get isStanding => heatStage == HeatStage.standing;
  bool get isReadyForMating => status == HeatStatus.readyForMating;
  bool get isHighAlert => isRepeatHeatAlert || consecutiveHeatCount >= 3;
  String? get workerName => observedByWorkerName;

  String get formattedHeatDate {
    if (heatDate == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(heatDate!);
  }

  factory CowHeatModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return null;
      }
    }

    int parseInt(dynamic val, [int defaultVal = 0]) {
      if (val is num) return val.toInt();
      return int.tryParse(val?.toString() ?? '') ?? defaultVal;
    }

    bool parseBool(dynamic val) {
      if (val == true || val == 1 || val == 'true') return true;
      return false;
    }

    // Extract Cow references
    String rawCowId = '';
    String rawCowTag = 'Cattle';
    String? rawCalfName;
    String? rawShedName;
    String? rawBreedName;

    final cowMap = json['cow'] is Map
        ? json['cow'] as Map
        : (json['cowId'] is Map ? json['cowId'] as Map : null);

    if (cowMap != null) {
      rawCowId = (cowMap['_id'] ?? cowMap['id'] ?? json['cowId'] ?? json['cow_id'] ?? '').toString();
      rawCowTag = (cowMap['tag_id'] ?? cowMap['tagId'] ?? cowMap['tag'] ?? 'Cattle').toString();
      rawCalfName = (cowMap['calf_name'] ?? cowMap['calfName'] ?? cowMap['name'])?.toString();

      if (cowMap['shed_id'] is Map) {
        final sMap = cowMap['shed_id'] as Map;
        rawShedName = (sMap['shedNumber'] ?? sMap['shed_number'] ?? sMap['name'])?.toString();
      } else if (cowMap['shed'] is Map) {
        final sMap = cowMap['shed'] as Map;
        rawShedName = (sMap['shedNumber'] ?? sMap['shed_number'] ?? sMap['name'])?.toString();
      }

      if (cowMap['breed'] is Map) {
        final bMap = cowMap['breed'] as Map;
        rawBreedName = (bMap['name'] ?? bMap['breedName'])?.toString();
      }
    } else {
      rawCowId = (json['cowId'] ?? json['cow_id'] ?? '').toString();
      rawCowTag = (json['cowTag'] ?? json['cow_tag'] ?? json['tagId'] ?? json['tag_id'] ?? 'Cattle').toString();
      rawCalfName = (json['calfName'] ?? json['calf_name'])?.toString();
      rawShedName = (json['shedNumber'] ?? json['shed_number'] ?? json['shedName'])?.toString();
      rawBreedName = (json['breedName'] ?? json['breed_name'])?.toString();
    }

    // Extract Worker
    String? workerId;
    String? workerName;
    if (json['observedByWorkerId'] is Map) {
      final wMap = json['observedByWorkerId'] as Map;
      workerId = (wMap['_id'] ?? wMap['id'])?.toString();
      workerName = (wMap['name'] ?? wMap['fullName'])?.toString();
    } else if (json['observedByWorker'] is Map) {
      final wMap = json['observedByWorker'] as Map;
      workerId = (wMap['_id'] ?? wMap['id'])?.toString();
      workerName = (wMap['name'] ?? wMap['fullName'])?.toString();
    } else {
      workerId = (json['observedByWorkerId'] ?? json['observed_by_worker_id'])?.toString();
      workerName = (json['workerName'] ?? json['worker_name'] ?? json['observedByName'])?.toString();
    }

    // Extract Gaushala
    String gId = '';
    String? gName;
    if (json['gaushalaId'] is Map) {
      final gMap = json['gaushalaId'] as Map;
      gId = (gMap['_id'] ?? gMap['id'] ?? '').toString();
      gName = (gMap['name'] ?? gMap['gaushala_name'])?.toString();
    } else {
      gId = (json['gaushalaId'] ?? json['gaushala_id'] ?? '').toString();
      gName = (json['gaushalaName'] ?? json['gaushala_name'])?.toString();
    }

    // Extract Heat signs list
    List<String> parsedSigns = [];
    if (json['heatSigns'] is List) {
      parsedSigns = (json['heatSigns'] as List).map((e) => e.toString().toUpperCase()).toList();
    } else if (json['heat_signs'] is List) {
      parsedSigns = (json['heat_signs'] as List).map((e) => e.toString().toUpperCase()).toList();
    }

    final consecCount = parseInt(json['consecutiveHeatCount'] ?? json['consecutive_heat_count'], 1);
    final isRepeat = parseBool(json['isRepeatHeatAlert'] ?? json['is_repeat_heat_alert']) || consecCount >= 3;

    return CowHeatModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      gaushalaId: gId,
      gaushalaName: gName,
      cowId: rawCowId,
      cowTagId: rawCowTag,
      cowCalfName: rawCalfName,
      cowShedName: rawShedName,
      cowBreedName: rawBreedName,
      heatDate: parseDate(json['heatDate'] ?? json['heat_date']),
      heatTime: (json['heatTime'] ?? json['heat_time'])?.toString(),
      heatStage: HeatStage.fromCode((json['heatStage'] ?? json['heat_stage'])?.toString()),
      heatSigns: parsedSigns,
      intensity: HeatIntensity.fromCode(json['intensity']?.toString()),
      status: HeatStatus.fromCode(json['status']?.toString()),
      observedByWorkerId: workerId,
      observedByWorkerName: workerName,
      remarks: (json['remarks'] ?? json['remark'])?.toString(),
      consecutiveHeatCount: consecCount,
      isRepeatHeatAlert: isRepeat,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'gaushalaId': gaushalaId,
      'cowId': cowId,
      if (heatDate != null) 'heatDate': DateFormat('yyyy-MM-dd').format(heatDate!),
      if (heatTime != null && heatTime!.isNotEmpty) 'heatTime': heatTime,
      'heatStage': heatStage.code,
      'heatSigns': heatSigns,
      'intensity': intensity.code,
      'status': status.code,
      if (observedByWorkerId != null && observedByWorkerId!.isNotEmpty)
        'observedByWorkerId': observedByWorkerId,
      if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
    };
  }

  CowHeatModel copyWith({
    String? id,
    String? gaushalaId,
    String? gaushalaName,
    String? cowId,
    String? cowTagId,
    String? cowCalfName,
    String? cowShedName,
    String? cowBreedName,
    DateTime? heatDate,
    String? heatTime,
    HeatStage? heatStage,
    List<String>? heatSigns,
    HeatIntensity? intensity,
    HeatStatus? status,
    String? observedByWorkerId,
    String? observedByWorkerName,
    String? remarks,
    int? consecutiveHeatCount,
    bool? isRepeatHeatAlert,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CowHeatModel(
      id: id ?? this.id,
      gaushalaId: gaushalaId ?? this.gaushalaId,
      gaushalaName: gaushalaName ?? this.gaushalaName,
      cowId: cowId ?? this.cowId,
      cowTagId: cowTagId ?? this.cowTagId,
      cowCalfName: cowCalfName ?? this.cowCalfName,
      cowShedName: cowShedName ?? this.cowShedName,
      cowBreedName: cowBreedName ?? this.cowBreedName,
      heatDate: heatDate ?? this.heatDate,
      heatTime: heatTime ?? this.heatTime,
      heatStage: heatStage ?? this.heatStage,
      heatSigns: heatSigns ?? this.heatSigns,
      intensity: intensity ?? this.intensity,
      status: status ?? this.status,
      observedByWorkerId: observedByWorkerId ?? this.observedByWorkerId,
      observedByWorkerName: observedByWorkerName ?? this.observedByWorkerName,
      remarks: remarks ?? this.remarks,
      consecutiveHeatCount: consecutiveHeatCount ?? this.consecutiveHeatCount,
      isRepeatHeatAlert: isRepeatHeatAlert ?? this.isRepeatHeatAlert,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Paginated result container for Cow Heat lists.
class HeatPaginatedResult {
  final List<CowHeatModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const HeatPaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory HeatPaginatedResult.fromJson(Map<String, dynamic> json) {
    final list = <CowHeatModel>[];
    final rawList = json['data'] ?? json['items'] ?? json['heats'] ?? [];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          list.add(CowHeatModel.fromJson(item));
        } else if (item is Map) {
          list.add(CowHeatModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    int parseInt(dynamic v, [int fallback = 0]) =>
        int.tryParse(v?.toString() ?? '$fallback') ?? fallback;
    return HeatPaginatedResult(
      items: list,
      total: parseInt(json['total'] ?? json['totalRecords'] ?? json['count'], list.length),
      page: parseInt(json['page'], 1),
      limit: parseInt(json['limit'], list.length),
      totalPages: parseInt(json['totalPages'] ?? json['total_pages'], 1),
    );
  }
}

/// Summary metrics for Cow Heat management dashboard strip.
class HeatSummaryMetrics {
  final int activeHeats;
  final int readyForMating;
  final int repeatHeatAlerts;
  final int matedThisCycle;
  final int totalCycles;

  const HeatSummaryMetrics({
    this.activeHeats = 0,
    this.readyForMating = 0,
    this.repeatHeatAlerts = 0,
    this.matedThisCycle = 0,
    this.totalCycles = 0,
  });

  factory HeatSummaryMetrics.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) => int.tryParse(val?.toString() ?? '0') ?? 0;
    return HeatSummaryMetrics(
      activeHeats: parseInt(json['activeHeats'] ?? json['active_heats']),
      readyForMating: parseInt(json['readyForMating'] ?? json['ready_for_mating']),
      repeatHeatAlerts: parseInt(json['repeatHeatAlerts'] ?? json['repeat_heat_alerts']),
      matedThisCycle: parseInt(json['matedThisCycle'] ?? json['mated_this_cycle']),
      totalCycles: parseInt(json['totalCycles'] ?? json['total_cycles'] ?? json['total']),
    );
  }
}
