import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Severity of the clinical condition
enum TreatmentSeverity {
  mild('MILD', 'Mild', Color(0xFF10B981), Color(0xFFECFDF5), PhosphorIconsRegular.info),
  moderate('MODERATE', 'Moderate', Color(0xFFF59E0B), Color(0xFFFFFBEB), PhosphorIconsRegular.warning),
  critical('CRITICAL', 'Critical', Color(0xFFEF4444), Color(0xFFFEF2F2), PhosphorIconsRegular.warningCircle);

  final String code;
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const TreatmentSeverity(this.code, this.label, this.color, this.bgColor, this.icon);

  static TreatmentSeverity fromCode(String? code) {
    if (code == null) return TreatmentSeverity.mild;
    final upper = code.trim().toUpperCase();
    return TreatmentSeverity.values.firstWhere(
      (s) => s.code == upper,
      orElse: () => TreatmentSeverity.mild,
    );
  }
}

/// Case status of Cow Treatment
enum TreatmentStatus {
  underTreatment('UNDER_TREATMENT', 'Under Treatment', Color(0xFF3B82F6), Color(0xFFEFF6FF), PhosphorIconsRegular.firstAid),
  recovered('RECOVERED', 'Recovered', Color(0xFF10B981), Color(0xFFECFDF5), PhosphorIconsRegular.checkCircle),
  critical('CRITICAL', 'Critical', Color(0xFFEF4444), Color(0xFFFEF2F2), PhosphorIconsRegular.warningOctagon),
  deceased('DECEASED', 'Deceased', Color(0xFF6B7280), Color(0xFFF3F4F6), PhosphorIconsRegular.skull),
  closed('CLOSED', 'Closed', Color(0xFF9CA3AF), Color(0xFFF9FAFB), PhosphorIconsRegular.archive);

  final String code;
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const TreatmentStatus(this.code, this.label, this.color, this.bgColor, this.icon);

  static TreatmentStatus fromCode(String? code) {
    if (code == null) return TreatmentStatus.underTreatment;
    final upper = code.trim().toUpperCase();
    return TreatmentStatus.values.firstWhere(
      (s) => s.code == upper,
      orElse: () => TreatmentStatus.underTreatment,
    );
  }
}

/// Type of treating veterinary doctor
enum DoctorType {
  inHouse('IN_HOUSE', 'In-House Vet'),
  visitingVet('VISITING_VET', 'Visiting Vet'),
  government('GOVERNMENT', 'Government Vet'),
  other('OTHER', 'Other');

  final String code;
  final String label;

  const DoctorType(this.code, this.label);

  static DoctorType fromCode(String? code) {
    if (code == null) return DoctorType.inHouse;
    final upper = code.trim().toUpperCase();
    return DoctorType.values.firstWhere(
      (d) => d.code == upper,
      orElse: () => DoctorType.inHouse,
    );
  }
}

/// Status of a dose in the schedule
enum DoseStatus {
  pending('PENDING', 'Pending', Color(0xFFF59E0B), Color(0xFFFFFBEB), PhosphorIconsRegular.clock),
  given('GIVEN', 'Given', Color(0xFF10B981), Color(0xFFECFDF5), PhosphorIconsRegular.checkCircle),
  skipped('SKIPPED', 'Skipped', Color(0xFF9CA3AF), Color(0xFFF3F4F6), PhosphorIconsRegular.prohibit);

  final String code;
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const DoseStatus(this.code, this.label, this.color, this.bgColor, this.icon);

  static DoseStatus fromCode(String? code) {
    if (code == null) return DoseStatus.pending;
    final upper = code.trim().toUpperCase();
    return DoseStatus.values.firstWhere(
      (s) => s.code == upper,
      orElse: () => DoseStatus.pending,
    );
  }
}

/// Model for a prescribed/administered medicine
class DoseMedicineModel {
  final String? id;
  final bool isStockItem;
  final String? itemId;
  final String medicineName;
  final String dosage;
  final String unit;
  final String route;
  final String? notes;

  const DoseMedicineModel({
    this.id,
    this.isStockItem = false,
    this.itemId,
    required this.medicineName,
    required this.dosage,
    this.unit = 'ML',
    this.route = 'IM',
    this.notes,
  });

  factory DoseMedicineModel.fromJson(Map<String, dynamic> json) {
    return DoseMedicineModel(
      id: (json['_id'] ?? json['id'])?.toString(),
      isStockItem: json['isStockItem'] == true || json['is_stock_item'] == true,
      itemId: (json['itemId'] ?? json['item_id'])?.toString(),
      medicineName: (json['medicineName'] ?? json['medicine_name'] ?? json['name'] ?? '').toString(),
      dosage: (json['dosage'] ?? '').toString(),
      unit: (json['unit'] ?? 'ML').toString().toUpperCase(),
      route: (json['route'] ?? 'IM').toString().toUpperCase(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'isStockItem': isStockItem,
      if (itemId != null && itemId!.isNotEmpty) 'itemId': itemId,
      'medicineName': medicineName,
      'dosage': dosage,
      'unit': unit,
      'route': route,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  DoseMedicineModel copyWith({
    String? id,
    bool? isStockItem,
    String? itemId,
    String? medicineName,
    String? dosage,
    String? unit,
    String? route,
    String? notes,
  }) {
    return DoseMedicineModel(
      id: id ?? this.id,
      isStockItem: isStockItem ?? this.isStockItem,
      itemId: itemId ?? this.itemId,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
      route: route ?? this.route,
      notes: notes ?? this.notes,
    );
  }
}

/// Model for an individual dose event in a treatment
class TreatmentDoseModel {
  final String id;
  final int doseNumber;
  final DateTime? scheduledDate;
  final DoseStatus status;
  final DateTime? administeredDate;
  final String? administeredBy;
  final String? notes;
  final String? recoveryNotes;
  final List<DoseMedicineModel> medicines;

  const TreatmentDoseModel({
    required this.id,
    required this.doseNumber,
    this.scheduledDate,
    this.status = DoseStatus.pending,
    this.administeredDate,
    this.administeredBy,
    this.notes,
    this.recoveryNotes,
    this.medicines = const [],
  });

  bool get isGiven => status == DoseStatus.given;
  bool get isPending => status == DoseStatus.pending;
  bool get isSkipped => status == DoseStatus.skipped;

  bool get isDueToday {
    if (!isPending || scheduledDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sched = DateTime(scheduledDate!.year, scheduledDate!.month, scheduledDate!.day);
    return sched.compareTo(today) <= 0;
  }

  factory TreatmentDoseModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return null;
      }
    }

    final rawMedicines = json['medicines'];
    List<DoseMedicineModel> meds = [];
    if (rawMedicines is List) {
      meds = rawMedicines
          .whereType<Map>()
          .map((m) => DoseMedicineModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    return TreatmentDoseModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      doseNumber: int.tryParse(json['doseNumber']?.toString() ?? json['dose_number']?.toString() ?? '1') ?? 1,
      scheduledDate: parseDate(json['scheduledDate'] ?? json['scheduled_date']),
      status: DoseStatus.fromCode(json['status']?.toString()),
      administeredDate: parseDate(json['administeredDate'] ?? json['administered_date']),
      administeredBy: (json['administeredBy'] ?? json['administered_by'])?.toString(),
      notes: json['notes']?.toString(),
      recoveryNotes: (json['recoveryNotes'] ?? json['recovery_notes'])?.toString(),
      medicines: meds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'doseNumber': doseNumber,
      if (scheduledDate != null) 'scheduledDate': scheduledDate!.toIso8601String(),
      'status': status.code,
      if (administeredDate != null) 'administeredDate': administeredDate!.toIso8601String(),
      if (administeredBy != null) 'administeredBy': administeredBy,
      if (notes != null) 'notes': notes,
      if (recoveryNotes != null) 'recoveryNotes': recoveryNotes,
      'medicines': medicines.map((m) => m.toJson()).toList(),
    };
  }
}

/// Comprehensive Cow Treatment Model
class CowTreatmentModel {
  final String id;
  final String treatmentNumber;
  final String gaushalaId;
  final String cowId;
  final String? cowTagId;
  final String? cowCalfName;
  final String? cowShedName;
  final String? cowBreedName;
  final num? cowWeight;
  final String? cowDob;
  final bool cowIsFemale;
  final String? shedId;
  final String diseaseName;
  final List<String> symptoms;
  final String? diagnosisNotes;
  final TreatmentSeverity severity;
  final String doctorName;
  final String doctorContact;
  final DoctorType doctorType;
  final TreatmentStatus status;
  final DateTime? treatmentStartDate;
  final int totalDoses;
  final int completedDoses;
  final int doseIntervalDays;
  final DateTime? nextDoseDate;
  final int? nextDoseNumber;
  final List<TreatmentDoseModel> doses;
  final List<DoseMedicineModel> medicines;
  final String? recoveryNotes;
  final String? recordedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CowTreatmentModel({
    required this.id,
    required this.treatmentNumber,
    required this.gaushalaId,
    required this.cowId,
    this.cowTagId,
    this.cowCalfName,
    this.cowShedName,
    this.cowBreedName,
    this.cowWeight,
    this.cowDob,
    this.cowIsFemale = true,
    this.shedId,
    required this.diseaseName,
    this.symptoms = const [],
    this.diagnosisNotes,
    this.severity = TreatmentSeverity.mild,
    this.doctorName = '',
    this.doctorContact = '',
    this.doctorType = DoctorType.inHouse,
    this.status = TreatmentStatus.underTreatment,
    this.treatmentStartDate,
    this.totalDoses = 1,
    this.completedDoses = 0,
    this.doseIntervalDays = 1,
    this.nextDoseDate,
    this.nextDoseNumber,
    this.doses = const [],
    this.medicines = const [],
    this.recoveryNotes,
    this.recordedBy,
    this.createdAt,
    this.updatedAt,
  });

  // Helpful computed getters
  String get displayCowTag => (cowTagId?.isNotEmpty == true) ? cowTagId! : 'COW';
  String get displayCowName => (cowCalfName?.isNotEmpty == true) ? cowCalfName! : displayCowTag;
  
  double get progressRatio {
    if (totalDoses <= 0) return 0.0;
    final ratio = completedDoses / totalDoses;
    return ratio > 1.0 ? 1.0 : (ratio < 0 ? 0.0 : ratio);
  }

  int get progressPercent => (progressRatio * 100).round();

  bool get isUnderTreatment => status == TreatmentStatus.underTreatment;
  bool get isRecovered => status == TreatmentStatus.recovered;
  bool get isCritical => status == TreatmentStatus.critical || severity == TreatmentSeverity.critical;

  bool get hasDosesPending => completedDoses < totalDoses && isUnderTreatment;

  bool get isDoseDueToday {
    if (!isUnderTreatment || nextDoseDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next = DateTime(nextDoseDate!.year, nextDoseDate!.month, nextDoseDate!.day);
    return next.compareTo(today) <= 0;
  }

  factory CowTreatmentModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return null;
      }
    }

    // Extract cow details if populated
    String rawCowId = '';
    String? rawCowTag;
    String? rawCalfName;
    String? rawShedName;
    String? rawBreedName;
    num? rawWeight;
    String? rawDob;
    bool rawIsFemale = true;

    if (json['cowId'] is Map) {
      final cowMap = Map<String, dynamic>.from(json['cowId'] as Map);
      rawCowId = (cowMap['_id'] ?? cowMap['id'] ?? '').toString();
      rawCowTag = cowMap['tag_id']?.toString() ?? cowMap['tagId']?.toString();
      rawCalfName = cowMap['calf_name']?.toString() ?? cowMap['calfName']?.toString();
      rawWeight = cowMap['calf_weight'] is num ? cowMap['calf_weight'] as num : null;
      rawDob = cowMap['dob']?.toString();
      rawIsFemale = cowMap['isFemale'] == true || cowMap['is_female'] == true;

      if (cowMap['shed_id'] is Map) {
        rawShedName = cowMap['shed_id']['shed_name']?.toString() ?? cowMap['shed_id']['name']?.toString();
      } else if (cowMap['shed'] is Map) {
        rawShedName = cowMap['shed']['shed_name']?.toString() ?? cowMap['shed']['name']?.toString();
      }

      if (cowMap['breed'] is Map) {
        rawBreedName = cowMap['breed']['breed_name']?.toString() ?? cowMap['breed']['name']?.toString();
      }
    } else if (json['cow'] is Map) {
      final cowMap = Map<String, dynamic>.from(json['cow'] as Map);
      rawCowId = (cowMap['_id'] ?? cowMap['id'] ?? '').toString();
      rawCowTag = cowMap['tag_id']?.toString() ?? cowMap['tagId']?.toString();
      rawCalfName = cowMap['calf_name']?.toString() ?? cowMap['calfName']?.toString();
    } else {
      rawCowId = json['cowId']?.toString() ?? json['cow_id']?.toString() ?? '';
    }

    // Fallbacks from root if populated directly
    if (rawCowTag == null && json['cowTag'] != null) rawCowTag = json['cowTag'].toString();
    if (rawCowTag == null && json['tag_id'] != null) rawCowTag = json['tag_id'].toString();

    // Extract shed details if populated
    String? rawShedId;
    if (json['shedId'] is Map) {
      final shedMap = Map<String, dynamic>.from(json['shedId'] as Map);
      rawShedId = (shedMap['_id'] ?? shedMap['id'])?.toString();
      rawShedName ??= shedMap['shed_name']?.toString() ?? shedMap['name']?.toString();
    } else if (json['shed'] is Map) {
      final shedMap = Map<String, dynamic>.from(json['shed'] as Map);
      rawShedId = (shedMap['_id'] ?? shedMap['id'])?.toString();
      rawShedName ??= shedMap['shed_name']?.toString() ?? shedMap['name']?.toString();
    } else {
      rawShedId = json['shedId']?.toString() ?? json['shed_id']?.toString();
    }

    // Parse symptoms
    List<String> parsedSymptoms = [];
    if (json['symptoms'] is List) {
      parsedSymptoms = (json['symptoms'] as List)
          .map((s) => s.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Parse doses
    List<TreatmentDoseModel> parsedDoses = [];
    if (json['doses'] is List) {
      parsedDoses = (json['doses'] as List)
          .whereType<Map>()
          .map((d) => TreatmentDoseModel.fromJson(Map<String, dynamic>.from(d)))
          .toList();
    }

    // Parse medicines
    List<DoseMedicineModel> parsedMedicines = [];
    if (json['medicines'] is List) {
      parsedMedicines = (json['medicines'] as List)
          .whereType<Map>()
          .map((m) => DoseMedicineModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    // Parse recordedBy
    String? recBy;
    if (json['recordedBy'] is Map) {
      recBy = json['recordedBy']['name']?.toString() ?? json['recordedBy']['username']?.toString();
    } else {
      recBy = json['recordedBy']?.toString() ?? json['addedBy']?.toString();
    }

    // Calculate completed doses if not directly in json
    int compDoses = int.tryParse(json['completedDoses']?.toString() ?? '') ??
        parsedDoses.where((d) => d.status == DoseStatus.given).length;

    int totDoses = int.tryParse(json['totalDoses']?.toString() ?? '') ??
        (parsedDoses.isNotEmpty ? parsedDoses.length : 1);

    // If nextDoseNumber or nextDoseDate missing, calculate from doses
    DateTime? nextDate = parseDate(json['nextDoseDate'] ?? json['next_dose_date']);
    int? nextNum = int.tryParse(json['nextDoseNumber']?.toString() ?? '');

    if (nextDate == null && parsedDoses.isNotEmpty) {
      final pendingDoses = parsedDoses.where((d) => d.status == DoseStatus.pending).toList()
        ..sort((a, b) => a.doseNumber.compareTo(b.doseNumber));
      if (pendingDoses.isNotEmpty) {
        nextDate = pendingDoses.first.scheduledDate;
        nextNum ??= pendingDoses.first.doseNumber;
      }
    }

    return CowTreatmentModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      treatmentNumber: (json['treatmentNumber'] ?? json['treatment_number'] ?? json['caseNumber'] ?? '').toString(),
      gaushalaId: (json['gaushalaId'] ?? json['gaushala_id'] ?? '').toString(),
      cowId: rawCowId,
      cowTagId: rawCowTag,
      cowCalfName: rawCalfName,
      cowShedName: rawShedName,
      cowBreedName: rawBreedName,
      cowWeight: rawWeight,
      cowDob: rawDob,
      cowIsFemale: rawIsFemale,
      shedId: rawShedId,
      diseaseName: (json['diseaseName'] ?? json['disease_name'] ?? json['disease'] ?? '').toString(),
      symptoms: parsedSymptoms,
      diagnosisNotes: json['diagnosisNotes']?.toString() ?? json['diagnosis_notes']?.toString(),
      severity: TreatmentSeverity.fromCode(json['severity']?.toString()),
      doctorName: (json['doctorName'] ?? json['doctor_name'] ?? '').toString(),
      doctorContact: (json['doctorContact'] ?? json['doctor_contact'] ?? '').toString(),
      doctorType: DoctorType.fromCode(json['doctorType']?.toString() ?? json['doctor_type']?.toString()),
      status: TreatmentStatus.fromCode(json['status']?.toString()),
      treatmentStartDate: parseDate(json['treatmentStartDate'] ?? json['treatment_start_date'] ?? json['startDate']),
      totalDoses: totDoses,
      completedDoses: compDoses,
      doseIntervalDays: int.tryParse(json['doseIntervalDays']?.toString() ?? json['dose_interval_days']?.toString() ?? '1') ?? 1,
      nextDoseDate: nextDate,
      nextDoseNumber: nextNum,
      doses: parsedDoses,
      medicines: parsedMedicines,
      recoveryNotes: json['recoveryNotes']?.toString() ?? json['recovery_notes']?.toString(),
      recordedBy: recBy,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'treatmentNumber': treatmentNumber,
      'gaushalaId': gaushalaId,
      'cowId': cowId,
      if (shedId != null) 'shedId': shedId,
      'diseaseName': diseaseName,
      'symptoms': symptoms,
      if (diagnosisNotes != null) 'diagnosisNotes': diagnosisNotes,
      'severity': severity.code,
      'doctorName': doctorName,
      'doctorContact': doctorContact,
      'doctorType': doctorType.code,
      'status': status.code,
      if (treatmentStartDate != null) 'treatmentStartDate': treatmentStartDate!.toIso8601String(),
      'totalDoses': totalDoses,
      'completedDoses': completedDoses,
      'doseIntervalDays': doseIntervalDays,
      if (nextDoseDate != null) 'nextDoseDate': nextDoseDate!.toIso8601String(),
      if (nextDoseNumber != null) 'nextDoseNumber': nextDoseNumber,
      'doses': doses.map((d) => d.toJson()).toList(),
      'medicines': medicines.map((m) => m.toJson()).toList(),
      if (recoveryNotes != null) 'recoveryNotes': recoveryNotes,
    };
  }
}

/// Model for the Treatment Dashboard Summary Card metrics
class TreatmentSummaryModel {
  final int activeCases;
  final int criticalCases;
  final int todayDueDoses;
  final int recoveredThisMonth;
  final int totalTreatments;

  const TreatmentSummaryModel({
    this.activeCases = 0,
    this.criticalCases = 0,
    this.todayDueDoses = 0,
    this.recoveredThisMonth = 0,
    this.totalTreatments = 0,
  });

  factory TreatmentSummaryModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) => int.tryParse(val?.toString() ?? '0') ?? 0;

    return TreatmentSummaryModel(
      activeCases: parseInt(json['activeCases'] ?? json['active_cases']),
      criticalCases: parseInt(json['criticalCases'] ?? json['critical_cases']),
      todayDueDoses: parseInt(json['todayDueDoses'] ?? json['today_due_doses'] ?? json['dueDosesToday']),
      recoveredThisMonth: parseInt(json['recoveredThisMonth'] ?? json['recovered_this_month']),
      totalTreatments: parseInt(json['totalTreatments'] ?? json['total_treatments'] ?? json['total']),
    );
  }
}

/// Paginated result wrapper for Treatment List
class TreatmentPaginatedResult {
  final List<CowTreatmentModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const TreatmentPaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });
}
