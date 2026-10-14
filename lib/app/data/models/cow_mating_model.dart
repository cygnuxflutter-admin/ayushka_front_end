import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Breeding & Pregnancy check status for Cow Mating records.
enum MatingStatus {
  pendingPd('PENDING_PD', 'Pending PD Check', Color(0xFFF59E0B), Color(0xFFFFFBEB), PhosphorIconsRegular.clock),
  pregnant('PREGNANT', 'Confirmed Pregnant', Color(0xFF10B981), Color(0xFFECFDF5), PhosphorIconsRegular.heartStraight),
  failed('FAILED', 'Failed / Open', Color(0xFFEF4444), Color(0xFFFEF2F2), PhosphorIconsRegular.xCircle),
  calved('CALVED', 'Calved Successfully', Color(0xFF0D9488), Color(0xFFF0FDFA), PhosphorIconsRegular.sparkle),
  aborted('ABORTED', 'Aborted / Loss', Color(0xFF6B7280), Color(0xFFF3F4F6), PhosphorIconsRegular.prohibit);

  final String code;
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const MatingStatus(this.code, this.label, this.color, this.bgColor, this.icon);

  static MatingStatus fromCode(String? code) {
    if (code == null) return MatingStatus.pendingPd;
    final upper = code.trim().toUpperCase();
    return MatingStatus.values.firstWhere(
      (s) => s.code == upper,
      orElse: () => MatingStatus.pendingPd,
    );
  }
}

/// Insemination / Mating type.
enum MatingType {
  natural('NATURAL', 'Natural Service', PhosphorIconsRegular.cow),
  artificial('ARTIFICIAL', 'Artificial Insemination (AI)', PhosphorIconsRegular.syringe);

  final String code;
  final String label;
  final IconData icon;

  const MatingType(this.code, this.label, this.icon);

  static MatingType fromCode(String? code) {
    if (code == null) return MatingType.natural;
    final upper = code.trim().toUpperCase();
    return MatingType.values.firstWhere(
      (t) => t.code == upper,
      orElse: () => MatingType.natural,
    );
  }
}

/// Pregnancy Diagnosis (PD) check outcome.
enum PDResult {
  positive('POSITIVE', 'Positive (Pregnant)', Color(0xFF10B981), Color(0xFFECFDF5)),
  negative('NEGATIVE', 'Negative (Failed / Open)', Color(0xFFEF4444), Color(0xFFFEF2F2));

  final String code;
  final String label;
  final Color color;
  final Color bgColor;

  const PDResult(this.code, this.label, this.color, this.bgColor);

  static PDResult fromCode(String? code) {
    if (code == null) return PDResult.positive;
    final upper = code.trim().toUpperCase();
    return PDResult.values.firstWhere(
      (r) => r.code == upper,
      orElse: () => PDResult.positive,
    );
  }
}

/// Comprehensive model for Cow Mating & Breeding Management.
class CowMatingModel {
  final String id;
  final String gaushalaId;
  final String? gaushalaName;
  final String cowId;
  final String cowTagId;
  final String? cowCalfName;
  final String? cowShedName;
  final String? cowBreedName;
  final String? heatId;
  final DateTime? heatDate;
  final DateTime? matingDate;
  final String? matingTime;
  final MatingType matingType;
  final String? bullId;
  final String? bullNameOrTag;
  final String? semenStrawCode;
  final String? semenBreedId;
  final String? semenBreedName;
  final String? semenSource;
  final String? inseminatorName;
  final String? inseminatorWorkerId;
  final String? remarks;
  final MatingStatus status;
  final int attemptCount;
  final bool isRepeatBreederAlert;
  final DateTime? expectedPDDate;
  final DateTime? pdDate;
  final PDResult? pdResult;
  final String? pdPerformedBy;
  final String? pdRemarks;
  final DateTime? expectedCalvingDate;
  final DateTime? actualCalvingDate;
  final String? calvingRemarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CowMatingModel({
    required this.id,
    required this.gaushalaId,
    this.gaushalaName,
    required this.cowId,
    required this.cowTagId,
    this.cowCalfName,
    this.cowShedName,
    this.cowBreedName,
    this.heatId,
    this.heatDate,
    this.matingDate,
    this.matingTime,
    this.matingType = MatingType.natural,
    this.bullId,
    this.bullNameOrTag,
    this.semenStrawCode,
    this.semenBreedId,
    this.semenBreedName,
    this.semenSource,
    this.inseminatorName,
    this.inseminatorWorkerId,
    this.remarks,
    this.status = MatingStatus.pendingPd,
    this.attemptCount = 1,
    this.isRepeatBreederAlert = false,
    this.expectedPDDate,
    this.pdDate,
    this.pdResult,
    this.pdPerformedBy,
    this.pdRemarks,
    this.expectedCalvingDate,
    this.actualCalvingDate,
    this.calvingRemarks,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPendingPD => status == MatingStatus.pendingPd;
  bool get isPregnant => status == MatingStatus.pregnant;
  bool get isCalved => status == MatingStatus.calved;
  bool get isFailed => status == MatingStatus.failed;
  bool get isHighAlert => isRepeatBreederAlert || attemptCount >= 3;
  bool get isDueForPD => isPDDue;
  int get failedMatingAttempts => attemptCount;
  String? get breedName => semenBreedName;
  String get bullDisplayName => bullNameOrTag?.isNotEmpty == true
      ? bullNameOrTag!
      : (bullId?.isNotEmpty == true ? bullId! : 'Natural Sire');

  /// Check whether PD is overdue or due today
  bool get isPDDue {
    if (!isPendingPD || expectedPDDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return expectedPDDate!.isBefore(today);
  }

  String get formattedMatingDate {
    if (matingDate == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(matingDate!);
  }

  String get formattedExpectedPDDate {
    if (expectedPDDate == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(expectedPDDate!);
  }

  String get formattedExpectedCalvingDate {
    if (expectedCalvingDate == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(expectedCalvingDate!);
  }

  String get formattedActualCalvingDate {
    if (actualCalvingDate == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(actualCalvingDate!);
  }

  /// Number of days elapsed between mating and actual calving.
  int? get actualGestationDays {
    if (matingDate == null || actualCalvingDate == null) return null;
    return actualCalvingDate!.difference(matingDate!).inDays;
  }

  /// Number of days elapsed since the mating event.
  int? get daysSinceMating {
    if (matingDate == null) return null;
    return DateTime.now().difference(matingDate!).inDays;
  }

  /// Number of days between mating and pregnancy diagnosis check.
  int? get daysToPDCheck {
    if (matingDate == null || pdDate == null) return null;
    return pdDate!.difference(matingDate!).inDays;
  }

  /// Inconsistency flag: Calving recorded too early (< 240 days; standard is ~282 days).
  bool get hasGestationInconsistency {
    if (!isCalved || actualGestationDays == null) return false;
    return actualGestationDays! < 240;
  }

  /// Inconsistency flag: PD check conducted prematurely (< 28 days post-mating).
  bool get hasPDInconsistency {
    if (pdDate == null || matingDate == null) return false;
    return daysToPDCheck! < 28;
  }

  factory CowMatingModel.fromJson(Map<String, dynamic> json) {
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

    // Extract Cow
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

    // Extract Bull (Sire)
    String? bId;
    String? bName;
    final bullMap = json['bull'] is Map
        ? json['bull'] as Map
        : (json['bullId'] is Map ? json['bullId'] as Map : null);

    if (bullMap != null) {
      bId = (bullMap['_id'] ?? bullMap['id'])?.toString();
      bName = (bullMap['name'] ?? bullMap['tag_id'] ?? bullMap['tagId'] ?? bullMap['calf_name'])?.toString();
    } else {
      bId = (json['bullId'] ?? json['bull_id'])?.toString();
      bName = (json['bullNameOrTag'] ?? json['bull_name_or_tag'] ?? json['bullName'] ?? json['bullTag'])?.toString();
    }

    final explicitBull = (json['bullNameOrTag'] ?? json['bull_name_or_tag'] ?? json['bullName'] ?? json['bullTag'])?.toString();
    if (explicitBull != null && explicitBull.isNotEmpty) {
      bName = explicitBull;
    }

    // Extract Semen Breed
    String? sBreedId;
    String? sBreedName;
    final breedMap = json['breed'] is Map
        ? json['breed'] as Map
        : (json['semenBreedId'] is Map ? json['semenBreedId'] as Map : null);

    if (breedMap != null) {
      sBreedId = (breedMap['_id'] ?? breedMap['id'])?.toString();
      sBreedName = (breedMap['name'] ?? breedMap['breedName'])?.toString();
    } else {
      sBreedId = (json['semenBreedId'] ?? json['semen_breed_id'])?.toString();
      sBreedName = (json['semenBreedName'] ?? json['semen_breed_name'])?.toString();
    }

    // Extract Heat reference
    String? hId;
    DateTime? hDate;
    if (json['heatId'] is Map) {
      final hMap = json['heatId'] as Map;
      hId = (hMap['_id'] ?? hMap['id'])?.toString();
      hDate = parseDate(hMap['heatDate'] ?? hMap['heat_date']);
    } else {
      hId = (json['heatId'] ?? json['heat_id'])?.toString();
      hDate = parseDate(json['heatDate'] ?? json['heat_date']);
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

    final attempts = parseInt(
      json['attemptCount'] ??
          json['attempt_count'] ??
          json['matingAttempt'] ??
          json['failedMatingAttempts'] ??
          json['failed_mating_attempts'],
      1,
    );
    final isRepeat = parseBool(json['isRepeatBreederAlert'] ?? json['is_repeat_breeder_alert']) || attempts >= 3;

    PDResult? parsedPdResult;
    final rawPdResult = (json['pdResult'] ?? json['pd_result'])?.toString();
    if (rawPdResult != null && rawPdResult.isNotEmpty) {
      parsedPdResult = PDResult.fromCode(rawPdResult);
    }

    return CowMatingModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      gaushalaId: gId,
      gaushalaName: gName,
      cowId: rawCowId,
      cowTagId: rawCowTag,
      cowCalfName: rawCalfName,
      cowShedName: rawShedName,
      cowBreedName: rawBreedName,
      heatId: hId,
      heatDate: hDate,
      matingDate: parseDate(json['matingDate'] ?? json['mating_date']),
      matingTime: (json['matingTime'] ?? json['mating_time'])?.toString(),
      matingType: MatingType.fromCode((json['matingType'] ?? json['mating_type'])?.toString()),
      bullId: bId,
      bullNameOrTag: bName,
      semenStrawCode: (json['semenStrawCode'] ?? json['semen_straw_code'])?.toString(),
      semenBreedId: sBreedId,
      semenBreedName: sBreedName,
      semenSource: (json['semenSource'] ?? json['semen_source'])?.toString(),
      inseminatorName: (json['inseminatorName'] ?? json['inseminator_name'])?.toString(),
      inseminatorWorkerId: (json['inseminatorWorkerId'] ?? json['inseminator_worker_id'])?.toString(),
      remarks: (json['remarks'] ?? json['remark'])?.toString(),
      status: MatingStatus.fromCode(json['status']?.toString()),
      attemptCount: attempts,
      isRepeatBreederAlert: isRepeat,
      expectedPDDate: parseDate(json['expectedPDDate'] ?? json['expected_pd_date'] ?? json['expectedPdDate']),
      pdDate: parseDate(json['pdDate'] ?? json['pd_date']),
      pdResult: parsedPdResult,
      pdPerformedBy: (json['pdPerformedBy'] ?? json['pd_performed_by'])?.toString(),
      pdRemarks: (json['pdRemarks'] ?? json['pd_remarks'])?.toString(),
      expectedCalvingDate: parseDate(json['expectedCalvingDate'] ?? json['expected_calving_date']),
      actualCalvingDate: parseDate(json['actualCalvingDate'] ?? json['actual_calving_date'] ?? json['calvingDate']),
      calvingRemarks: (json['calvingRemarks'] ?? json['calving_remarks'])?.toString(),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'gaushalaId': gaushalaId,
      'cowId': cowId,
      if (heatId != null && heatId!.isNotEmpty) 'heatId': heatId,
      if (matingDate != null) 'matingDate': DateFormat('yyyy-MM-dd').format(matingDate!),
      if (matingTime != null && matingTime!.isNotEmpty) 'matingTime': matingTime,
      'matingType': matingType.code,
      if (bullId != null && bullId!.isNotEmpty) 'bullId': bullId,
      if (bullNameOrTag != null && bullNameOrTag!.isNotEmpty) 'bullNameOrTag': bullNameOrTag,
      if (semenStrawCode != null && semenStrawCode!.isNotEmpty) 'semenStrawCode': semenStrawCode,
      if (semenBreedId != null && semenBreedId!.isNotEmpty) 'semenBreedId': semenBreedId,
      if (semenSource != null && semenSource!.isNotEmpty) 'semenSource': semenSource,
      if (inseminatorName != null && inseminatorName!.isNotEmpty) 'inseminatorName': inseminatorName,
      if (inseminatorWorkerId != null && inseminatorWorkerId!.isNotEmpty)
        'inseminatorWorkerId': inseminatorWorkerId,
      if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
    };
  }

  CowMatingModel copyWith({
    String? id,
    String? gaushalaId,
    String? gaushalaName,
    String? cowId,
    String? cowTagId,
    String? cowCalfName,
    String? cowShedName,
    String? cowBreedName,
    String? heatId,
    DateTime? heatDate,
    DateTime? matingDate,
    String? matingTime,
    MatingType? matingType,
    String? bullId,
    String? bullNameOrTag,
    String? semenStrawCode,
    String? semenBreedId,
    String? semenBreedName,
    String? semenSource,
    String? inseminatorName,
    String? inseminatorWorkerId,
    String? remarks,
    MatingStatus? status,
    int? attemptCount,
    bool? isRepeatBreederAlert,
    DateTime? expectedPDDate,
    DateTime? pdDate,
    PDResult? pdResult,
    String? pdPerformedBy,
    String? pdRemarks,
    DateTime? expectedCalvingDate,
    DateTime? actualCalvingDate,
    String? calvingRemarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CowMatingModel(
      id: id ?? this.id,
      gaushalaId: gaushalaId ?? this.gaushalaId,
      gaushalaName: gaushalaName ?? this.gaushalaName,
      cowId: cowId ?? this.cowId,
      cowTagId: cowTagId ?? this.cowTagId,
      cowCalfName: cowCalfName ?? this.cowCalfName,
      cowShedName: cowShedName ?? this.cowShedName,
      cowBreedName: cowBreedName ?? this.cowBreedName,
      heatId: heatId ?? this.heatId,
      heatDate: heatDate ?? this.heatDate,
      matingDate: matingDate ?? this.matingDate,
      matingTime: matingTime ?? this.matingTime,
      matingType: matingType ?? this.matingType,
      bullId: bullId ?? this.bullId,
      bullNameOrTag: bullNameOrTag ?? this.bullNameOrTag,
      semenStrawCode: semenStrawCode ?? this.semenStrawCode,
      semenBreedId: semenBreedId ?? this.semenBreedId,
      semenBreedName: semenBreedName ?? this.semenBreedName,
      semenSource: semenSource ?? this.semenSource,
      inseminatorName: inseminatorName ?? this.inseminatorName,
      inseminatorWorkerId: inseminatorWorkerId ?? this.inseminatorWorkerId,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      isRepeatBreederAlert: isRepeatBreederAlert ?? this.isRepeatBreederAlert,
      expectedPDDate: expectedPDDate ?? this.expectedPDDate,
      pdDate: pdDate ?? this.pdDate,
      pdResult: pdResult ?? this.pdResult,
      pdPerformedBy: pdPerformedBy ?? this.pdPerformedBy,
      pdRemarks: pdRemarks ?? this.pdRemarks,
      expectedCalvingDate: expectedCalvingDate ?? this.expectedCalvingDate,
      actualCalvingDate: actualCalvingDate ?? this.actualCalvingDate,
      calvingRemarks: calvingRemarks ?? this.calvingRemarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Paginated result container for Cow Mating lists.
class MatingPaginatedResult {
  final List<CowMatingModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const MatingPaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory MatingPaginatedResult.fromJson(Map<String, dynamic> json) {
    final list = <CowMatingModel>[];
    final rawList = json['data'] ?? json['items'] ?? json['matings'] ?? [];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          list.add(CowMatingModel.fromJson(item));
        } else if (item is Map) {
          list.add(CowMatingModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    int parseInt(dynamic v, [int fallback = 0]) =>
        int.tryParse(v?.toString() ?? '$fallback') ?? fallback;
    return MatingPaginatedResult(
      items: list,
      total: parseInt(json['total'] ?? json['totalRecords'] ?? json['count'], list.length),
      page: parseInt(json['page'], 1),
      limit: parseInt(json['limit'], list.length),
      totalPages: parseInt(json['totalPages'] ?? json['total_pages'], 1),
    );
  }
}

/// Summary metrics for Cow Mating management dashboard strip.
class MatingSummaryMetrics {
  final int pendingPDChecks;
  final int confirmedPregnant;
  final int repeatBreeders;
  final int calvedTotal;
  final int totalMatings;

  const MatingSummaryMetrics({
    this.pendingPDChecks = 0,
    this.confirmedPregnant = 0,
    this.repeatBreeders = 0,
    this.calvedTotal = 0,
    this.totalMatings = 0,
  });

  factory MatingSummaryMetrics.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) => int.tryParse(val?.toString() ?? '0') ?? 0;
    return MatingSummaryMetrics(
      pendingPDChecks: parseInt(json['pendingPDChecks'] ?? json['pending_pd_checks'] ?? json['pendingPD']),
      confirmedPregnant: parseInt(json['confirmedPregnant'] ?? json['confirmed_pregnant'] ?? json['pregnant']),
      repeatBreeders: parseInt(json['repeatBreeders'] ?? json['repeat_breeders'] ?? json['repeatBreederAlerts']),
      calvedTotal: parseInt(json['calvedTotal'] ?? json['calved_total'] ?? json['calved']),
      totalMatings: parseInt(json['totalMatings'] ?? json['total_matings'] ?? json['total']),
    );
  }
}
