/// Aggregated counts of active farm alerts across all modules.
class DashboardAlertCounts {
  final int treatmentDueDoses;
  final int criticalCases;
  final int milkVariances;
  final int lowMedicalStock;
  final int expiringMedicines;
  final int lowFeedStock;
  final int totalAlerts;

  const DashboardAlertCounts({
    this.treatmentDueDoses = 0,
    this.criticalCases = 0,
    this.milkVariances = 0,
    this.lowMedicalStock = 0,
    this.expiringMedicines = 0,
    this.lowFeedStock = 0,
    this.totalAlerts = 0,
  });

  factory DashboardAlertCounts.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is num) return val.toInt();
      return int.tryParse(val?.toString() ?? '') ?? 0;
    }

    final treatmentDoses = parseInt(json['treatmentDueDoses'] ?? json['treatment_due_doses']);
    final critical = parseInt(json['criticalCases'] ?? json['critical_cases']);
    final milk = parseInt(json['milkAlerts'] ?? json['milkVariances'] ?? json['milk_variances']);
    final lowMed = parseInt(json['lowMedicalStock'] ?? json['low_medical_stock']);
    final expMed = parseInt(json['expiringMedicines'] ?? json['expiringBatches'] ?? json['expiring_medicines']);
    final lowFeed = parseInt(json['lowFeedStock'] ?? json['low_feed_stock']);
    final total = parseInt(json['totalAlerts'] ?? json['total_alerts']);

    final calculatedTotal = total > 0
        ? total
        : (treatmentDoses + critical + milk + lowMed + expMed + lowFeed);

    return DashboardAlertCounts(
      treatmentDueDoses: treatmentDoses,
      criticalCases: critical,
      milkVariances: milk,
      lowMedicalStock: lowMed,
      expiringMedicines: expMed,
      lowFeedStock: lowFeed,
      totalAlerts: calculatedTotal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'treatmentDueDoses': treatmentDueDoses,
      'criticalCases': criticalCases,
      'milkVariances': milkVariances,
      'lowMedicalStock': lowMedicalStock,
      'expiringMedicines': expiringMedicines,
      'lowFeedStock': lowFeedStock,
      'totalAlerts': totalAlerts,
    };
  }
}

/// Alert item representing an urgent treatment dose or critical health case.
class TreatmentAlertItem {
  final String treatmentId;
  final String cowTag;
  final String? calfName;
  final String? shedNumber;
  final String diseaseName;
  final String severity; // CRITICAL, MODERATE, MILD
  final int dueDoseNumber;
  final int totalDoses;
  final DateTime? nextDoseDate;
  final String? status;

  const TreatmentAlertItem({
    required this.treatmentId,
    required this.cowTag,
    this.calfName,
    this.shedNumber,
    required this.diseaseName,
    this.severity = 'MODERATE',
    this.dueDoseNumber = 1,
    this.totalDoses = 1,
    this.nextDoseDate,
    this.status,
  });

  bool get isCritical => severity.toUpperCase() == 'CRITICAL';

  factory TreatmentAlertItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return null;
      }
    }

    int parseInt(dynamic val, int defaultVal) {
      if (val is num) return val.toInt();
      return int.tryParse(val?.toString() ?? '') ?? defaultVal;
    }

    String tag = 'Cattle';
    String? calf;
    String? shed;

    if (json['cowId'] is Map) {
      final cMap = json['cowId'] as Map;
      tag = (cMap['tag_id'] ?? cMap['tagId'] ?? cMap['tag'] ?? 'Cattle').toString();
      calf = (cMap['calf_name'] ?? cMap['calfName'] ?? cMap['name'])?.toString();
    } else if (json['cowTag'] != null || json['cow_tag'] != null || json['tag_id'] != null || json['tagId'] != null) {
      tag = (json['cowTag'] ?? json['cow_tag'] ?? json['tag_id'] ?? json['tagId']).toString();
    }
    calf ??= (json['calfName'] ?? json['calf_name'] ?? json['cowCalfName'] ?? json['cowName'] ?? json['name'])?.toString();

    if (json['shedId'] is Map) {
      final sMap = json['shedId'] as Map;
      shed = (sMap['shedNumber'] ?? sMap['shed_number'] ?? sMap['shedName'] ?? sMap['name'])?.toString();
    } else if (json['cowId'] is Map && (json['cowId'] as Map)['shed_id'] is Map) {
      final sMap = (json['cowId'] as Map)['shed_id'] as Map;
      shed = (sMap['shedNumber'] ?? sMap['shed_number'] ?? sMap['shedName'])?.toString();
    }
    shed ??= (json['shedNumber'] ?? json['shed_number'] ?? json['cowShedName'] ?? json['shedName'] ?? json['shed_name'])?.toString();

    return TreatmentAlertItem(
      treatmentId: (json['treatmentId'] ?? json['treatment_id'] ?? json['_id'] ?? json['id'] ?? '').toString(),
      cowTag: tag,
      calfName: calf,
      shedNumber: shed,
      diseaseName: (json['diseaseName'] ?? json['disease_name'] ?? json['disease'] ?? 'Medical Condition').toString(),
      severity: (json['severity'] ?? 'MODERATE').toString().toUpperCase(),
      dueDoseNumber: parseInt(json['dueDoseNumber'] ?? json['due_dose_number'] ?? json['nextDoseNumber'], 1),
      totalDoses: parseInt(json['totalDoses'] ?? json['total_doses'], 1),
      nextDoseDate: parseDate(json['nextDoseDate'] ?? json['next_dose_date'] ?? json['scheduledDate']),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'treatmentId': treatmentId,
      'cowTag': cowTag,
      if (calfName != null) 'calfName': calfName,
      if (shedNumber != null) 'shedNumber': shedNumber,
      'diseaseName': diseaseName,
      'severity': severity,
      'dueDoseNumber': dueDoseNumber,
      'totalDoses': totalDoses,
      if (nextDoseDate != null) 'nextDoseDate': nextDoseDate!.toIso8601String(),
      if (status != null) 'status': status,
    };
  }
}

/// Alert item representing milk variance drops, leftover fridge stock, or milking notifications.
class MilkAlertItem {
  final String notificationId;
  final String cowTag;
  final String? shift;
  final String message;
  final DateTime? createdAt;
  final String? title;
  final bool isRead;

  const MilkAlertItem({
    required this.notificationId,
    required this.cowTag,
    this.shift,
    required this.message,
    this.createdAt,
    this.title,
    this.isRead = false,
  });

  factory MilkAlertItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return null;
      }
    }

    String tag = 'General';
    if (json['cowId'] is Map) {
      final cMap = json['cowId'] as Map;
      tag = (cMap['tag_id'] ?? cMap['tagId'] ?? cMap['tag'] ?? 'General').toString();
    } else if (json['cowTag'] != null || json['cow_tag'] != null || json['cowTagId'] != null) {
      tag = (json['cowTag'] ?? json['cow_tag'] ?? json['cowTagId']).toString();
    }

    return MilkAlertItem(
      notificationId: (json['notificationId'] ?? json['notification_id'] ?? json['_id'] ?? json['id'] ?? '').toString(),
      cowTag: tag,
      shift: (json['shift'] ?? json['milkingShift'])?.toString(),
      message: (json['message'] ?? json['title'] ?? 'Milk alert detected').toString(),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      title: json['title']?.toString(),
      isRead: json['isRead'] == true || json['is_read'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'cowTag': cowTag,
      if (shift != null) 'shift': shift,
      'message': message,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (title != null) 'title': title,
      'isRead': isRead,
    };
  }
}

/// Alert item representing a medical stock item below minimum threshold.
class MedicalLowStockAlertItem {
  final String itemId;
  final String itemName;
  final String category;
  final double totalStock;
  final double minStockAlert;
  final String unit;

  const MedicalLowStockAlertItem({
    required this.itemId,
    required this.itemName,
    this.category = 'OTHER',
    required this.totalStock,
    required this.minStockAlert,
    required this.unit,
  });

  factory MedicalLowStockAlertItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '') ?? 0.0;
    }

    String id = '';
    String name = 'Medicine';
    String cat = (json['category'] ?? 'OTHER').toString();

    if (json['itemId'] is Map) {
      final iMap = json['itemId'] as Map;
      id = (iMap['_id'] ?? iMap['id'] ?? '').toString();
      name = (iMap['itemName'] ?? iMap['item_name'] ?? iMap['name'] ?? name).toString();
      if (iMap['category'] != null) cat = iMap['category'].toString();
    } else {
      id = (json['itemId'] ?? json['item_id'] ?? json['_id'] ?? json['id'] ?? '').toString();
      name = (json['itemName'] ?? json['item_name'] ?? json['name'] ?? name).toString();
    }

    return MedicalLowStockAlertItem(
      itemId: id,
      itemName: name,
      category: cat,
      totalStock: parseDouble(json['totalStock'] ?? json['total_stock'] ?? json['currentStock']),
      minStockAlert: parseDouble(json['minStockAlert'] ?? json['min_stock_alert'] ?? json['minStock']),
      unit: (json['unit'] ?? 'UNIT').toString().toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'category': category,
      'totalStock': totalStock,
      'minStockAlert': minStockAlert,
      'unit': unit,
    };
  }
}

/// Alert item representing a medicine batch approaching or past expiration date.
class MedicalExpiringAlertItem {
  final String itemId;
  final String itemName;
  final String batchNumber;
  final DateTime? expiryDate;
  final int daysRemaining;
  final String? category;
  final double quantity;

  const MedicalExpiringAlertItem({
    required this.itemId,
    required this.itemName,
    this.batchNumber = 'N/A',
    this.expiryDate,
    this.daysRemaining = 0,
    this.category,
    this.quantity = 0.0,
  });

  bool get isExpired => daysRemaining <= 0;

  factory MedicalExpiringAlertItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return null;
      }
    }

    int parseInt(dynamic val) {
      if (val is num) return val.toInt();
      return int.tryParse(val?.toString() ?? '') ?? 0;
    }

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '') ?? 0.0;
    }

    final expDate = parseDate(json['expiryDate'] ?? json['expiry_date']);
    int days = parseInt(json['daysRemaining'] ?? json['days_remaining']);
    if (days == 0 && expDate != null) {
      final now = DateTime.now();
      days = expDate.difference(now).inDays;
    }

    String expId = '';
    String expName = 'Medicine';
    String? expCat = json['category']?.toString();

    if (json['itemId'] is Map) {
      final iMap = json['itemId'] as Map;
      expId = (iMap['_id'] ?? iMap['id'] ?? '').toString();
      expName = (iMap['itemName'] ?? iMap['item_name'] ?? iMap['name'] ?? expName).toString();
      expCat ??= iMap['category']?.toString();
    } else {
      expId = (json['itemId'] ?? json['item_id'] ?? json['_id'] ?? json['id'] ?? '').toString();
      expName = (json['itemName'] ?? json['item_name'] ?? json['name'] ?? expName).toString();
    }

    return MedicalExpiringAlertItem(
      itemId: expId,
      itemName: expName,
      batchNumber: (json['batchNumber'] ?? json['batch_number'] ?? 'N/A').toString(),
      expiryDate: expDate,
      daysRemaining: days,
      category: expCat,
      quantity: parseDouble(json['quantity'] ?? json['availableQuantity'] ?? json['currentStock']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'batchNumber': batchNumber,
      if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
      'daysRemaining': daysRemaining,
      if (category != null) 'category': category,
      'quantity': quantity,
    };
  }
}

/// Alert item representing feed inventory below safety buffer.
class FeedStockAlertItem {
  final String itemId;
  final String itemName;
  final double currentStock;
  final double minStockAlert;
  final String unit;
  final String? category;

  const FeedStockAlertItem({
    required this.itemId,
    required this.itemName,
    required this.currentStock,
    required this.minStockAlert,
    required this.unit,
    this.category,
  });

  factory FeedStockAlertItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '') ?? 0.0;
    }

    return FeedStockAlertItem(
      itemId: (json['itemId'] ?? json['item_id'] ?? json['_id'] ?? json['id'] ?? '').toString(),
      itemName: (json['itemName'] ?? json['item_name'] ?? json['name'] ?? 'Unnamed Feed').toString(),
      currentStock: parseDouble(json['currentStock'] ?? json['current_stock'] ?? json['stock']),
      minStockAlert: parseDouble(json['minStockAlert'] ?? json['min_stock_alert'] ?? json['minStock']),
      unit: (json['unit'] ?? 'KG').toString().toUpperCase(),
      category: json['category']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'currentStock': currentStock,
      'minStockAlert': minStockAlert,
      'unit': unit,
      if (category != null) 'category': category,
    };
  }
}

/// Root aggregated alerts response model.
class DashboardAlertsSummaryResponse {
  final DashboardAlertCounts counts;
  final List<TreatmentAlertItem> treatmentAlerts;
  final List<MilkAlertItem> milkAlerts;
  final List<MedicalLowStockAlertItem> medicalLowStock;
  final List<MedicalExpiringAlertItem> medicalExpiring;
  final List<FeedStockAlertItem> feedAlerts;

  const DashboardAlertsSummaryResponse({
    this.counts = const DashboardAlertCounts(),
    this.treatmentAlerts = const [],
    this.milkAlerts = const [],
    this.medicalLowStock = const [],
    this.medicalExpiring = const [],
    this.feedAlerts = const [],
  });

  factory DashboardAlertsSummaryResponse.fromJson(Map<String, dynamic> json) {
    // Extract root or nested data container
    final Map<String, dynamic> data = (json['data'] is Map)
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    final counts = data['counts'] is Map
        ? DashboardAlertCounts.fromJson(Map<String, dynamic>.from(data['counts'] as Map))
        : const DashboardAlertCounts();

    List<TreatmentAlertItem> treatments = [];
    if (data['treatmentAlerts'] is List) {
      treatments = (data['treatmentAlerts'] as List)
          .whereType<Map>()
          .map((m) => TreatmentAlertItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } else if (data['treatmentAlerts'] is Map) {
      final tMap = Map<String, dynamic>.from(data['treatmentAlerts'] as Map);
      final list = <TreatmentAlertItem>[];
      final seenIds = <String>{};
      void addItems(dynamic items) {
        if (items is List) {
          for (final m in items.whereType<Map>()) {
            final item = TreatmentAlertItem.fromJson(Map<String, dynamic>.from(m));
            if (item.treatmentId.isNotEmpty && seenIds.add(item.treatmentId)) {
              list.add(item);
            }
          }
        }
      }
      addItems(tMap['todayDueDoses']);
      addItems(tMap['criticalCases']);
      addItems(tMap['items']);
      treatments = list;
    }

    List<MilkAlertItem> milk = [];
    if (data['milkAlerts'] is List) {
      milk = (data['milkAlerts'] as List)
          .whereType<Map>()
          .map((m) => MilkAlertItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } else if (data['milkAlerts'] is Map) {
      final mMap = Map<String, dynamic>.from(data['milkAlerts'] as Map);
      final rawMilk = mMap['recentVariances'] ?? mMap['variances'] ?? mMap['items'];
      if (rawMilk is List) {
        milk = rawMilk
            .whereType<Map>()
            .map((m) => MilkAlertItem.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    }

    List<MedicalLowStockAlertItem> lowStockMed = [];
    List<MedicalExpiringAlertItem> expiringMed = [];
    if (data['medicalAlerts'] is Map) {
      final medMap = Map<String, dynamic>.from(data['medicalAlerts'] as Map);
      if (medMap['lowStock'] is List) {
        lowStockMed = (medMap['lowStock'] as List)
            .whereType<Map>()
            .map((m) => MedicalLowStockAlertItem.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
      final expBatches = medMap['expiringBatches'] ?? medMap['expiring'] ?? medMap['batches'];
      if (expBatches is List) {
        expiringMed = expBatches
            .whereType<Map>()
            .map((m) => MedicalExpiringAlertItem.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } else if (data['medicalAlerts'] is List) {
      lowStockMed = (data['medicalAlerts'] as List)
          .whereType<Map>()
          .map((m) => MedicalLowStockAlertItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    List<FeedStockAlertItem> feed = [];
    if (data['feedAlerts'] is List) {
      feed = (data['feedAlerts'] as List)
          .whereType<Map>()
          .map((m) => FeedStockAlertItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } else if (data['feedAlerts'] is Map) {
      final fMap = Map<String, dynamic>.from(data['feedAlerts'] as Map);
      final rawFeed = fMap['lowStock'] ?? fMap['items'];
      if (rawFeed is List) {
        feed = rawFeed
            .whereType<Map>()
            .map((m) => FeedStockAlertItem.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    }

    return DashboardAlertsSummaryResponse(
      counts: counts,
      treatmentAlerts: treatments,
      milkAlerts: milk,
      medicalLowStock: lowStockMed,
      medicalExpiring: expiringMed,
      feedAlerts: feed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'counts': counts.toJson(),
      'treatmentAlerts': treatmentAlerts.map((t) => t.toJson()).toList(),
      'milkAlerts': milkAlerts.map((m) => m.toJson()).toList(),
      'medicalAlerts': {
        'lowStock': medicalLowStock.map((l) => l.toJson()).toList(),
        'expiring': medicalExpiring.map((e) => e.toJson()).toList(),
      },
      'feedAlerts': feedAlerts.map((f) => f.toJson()).toList(),
    };
  }
}
