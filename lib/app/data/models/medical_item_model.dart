import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/values/app_colors.dart';

/// Categories supported for Veterinary / Medical Items
enum MedicalItemCategory {
  tablet('TABLET', 'Tablet', Color(0xFF3B82F6), PhosphorIconsRegular.pill),
  injection('INJECTION', 'Injection', Color(0xFF8B5CF6), PhosphorIconsRegular.syringe),
  syrup('SYRUP', 'Syrup', Color(0xFFF59E0B), PhosphorIconsRegular.drop),
  vaccine('VACCINE', 'Vaccine', Color(0xFF10B981), PhosphorIconsRegular.firstAid),
  ointment('OINTMENT', 'Ointment', Color(0xFFEC4899), PhosphorIconsRegular.handSoap),
  powder('POWDER', 'Powder', Color(0xFFF97316), PhosphorIconsRegular.sparkle),
  drops('DROPS', 'Drops', Color(0xFF06B6D4), PhosphorIconsRegular.dropHalf),
  bolus('BOLUS', 'Bolus', Color(0xFF14B8A6), PhosphorIconsRegular.pill),
  antibiotic('ANTIBIOTIC', 'Antibiotic', Color(0xFF6366F1), PhosphorIconsRegular.shieldCheck),
  other('OTHER', 'Other', Color(0xFF6B7280), PhosphorIconsRegular.package);

  final String code;
  final String label;
  final Color color;
  final IconData icon;

  const MedicalItemCategory(this.code, this.label, this.color, this.icon);

  static MedicalItemCategory fromCode(String? code) {
    if (code == null) return MedicalItemCategory.other;
    final upper = code.trim().toUpperCase();
    return MedicalItemCategory.values.firstWhere(
      (c) => c.code == upper,
      orElse: () => MedicalItemCategory.other,
    );
  }
}

/// Measurement and packaging units supported for Veterinary / Medical Items
enum MedicalItemUnit {
  vial('VIAL', 'Vial', 'VIAL'),
  strip('STRIP', 'Strip', 'STP'),
  bottle('BOTTLE', 'Bottle', 'BTL'),
  ampul('AMPUL', 'Ampul', 'AMP'),
  tube('TUBE', 'Tube', 'TUB'),
  box('BOX', 'Box', 'BOX'),
  pack('PACK', 'Pack', 'PCK'),
  ml('ML', 'Milliliter (ML)', 'ML'),
  gm('GM', 'Gram (GM)', 'GM'),
  kg('KG', 'Kilogram (KG)', 'KG'),
  tablet('TABLET', 'Tablet', 'TAB'),
  piece('PIECE', 'Piece', 'PCS'),
  bolus('BOLUS', 'Bolus', 'BLS'),
  other('OTHER', 'Other', 'UNIT');

  final String code;
  final String label;
  final String shortLabel;

  const MedicalItemUnit(this.code, this.label, this.shortLabel);

  static MedicalItemUnit fromCode(String? code) {
    if (code == null) return MedicalItemUnit.piece;
    final upper = code.trim().toUpperCase();
    return MedicalItemUnit.values.firstWhere(
      (u) => u.code == upper,
      orElse: () => MedicalItemUnit.other,
    );
  }
}

/// Transaction types for Stock Movement
enum MedicalTransactionType {
  inward(
    'INWARD',
    'Inward (Purchase / Receipt)',
    AppColors.primary,
    PhosphorIconsRegular.arrowDownLeft,
  ),
  outward(
    'OUTWARD',
    'Outward (Dispense / Treatment)',
    Color(0xFFF59E0B),
    PhosphorIconsRegular.arrowUpRight,
  ),
  expiredDisposal(
    'EXPIRED_DISPOSAL',
    'Expired Stock Disposal',
    AppColors.error,
    PhosphorIconsRegular.trash,
  ),
  adjustment(
    'ADJUSTMENT',
    'Audit Adjustment',
    Color(0xFF6366F1),
    PhosphorIconsRegular.slidersHorizontal,
  );

  final String code;
  final String label;
  final Color color;
  final IconData icon;

  const MedicalTransactionType(this.code, this.label, this.color, this.icon);

  static MedicalTransactionType fromCode(String? code) {
    if (code == null) return MedicalTransactionType.inward;
    final upper = code.trim().toUpperCase();
    return MedicalTransactionType.values.firstWhere(
      (t) => t.code == upper,
      orElse: () => MedicalTransactionType.inward,
    );
  }
}

/// Transaction reasons
enum MedicalTransactionReason {
  purchase('PURCHASE', 'Purchase', AppColors.primary),
  donation('DONATION', 'Donation', Color(0xFF3B82F6)),
  openingStock('OPENING_STOCK', 'Opening Stock', Color(0xFF8B5CF6)),
  treatment('TREATMENT', 'Treatment', Color(0xFFF59E0B)),
  emergency('EMERGENCY', 'Emergency Care', Color(0xFFEF4444)),
  dailyCare('DAILY_CARE', 'Daily Preventive Care', Color(0xFF06B6D4)),
  expiredDisposal('EXPIRED_DISPOSAL', 'Expired Disposal', Color(0xFFDC2626)),
  auditCorrection('AUDIT_CORRECTION', 'Audit Correction', Color(0xFF6366F1)),
  other('OTHER', 'Other', Color(0xFF6B7280));

  final String code;
  final String label;
  final Color color;

  const MedicalTransactionReason(this.code, this.label, this.color);

  static MedicalTransactionReason fromCode(String? code) {
    if (code == null) return MedicalTransactionReason.other;
    final upper = code.trim().toUpperCase();
    return MedicalTransactionReason.values.firstWhere(
      (r) => r.code == upper,
      orElse: () => MedicalTransactionReason.other,
    );
  }

  static List<MedicalTransactionReason> get inwardReasons => [
        MedicalTransactionReason.purchase,
        MedicalTransactionReason.donation,
        MedicalTransactionReason.openingStock,
        MedicalTransactionReason.other,
      ];

  static List<MedicalTransactionReason> get outwardReasons => [
        MedicalTransactionReason.treatment,
        MedicalTransactionReason.emergency,
        MedicalTransactionReason.dailyCare,
        MedicalTransactionReason.other,
      ];

  static List<MedicalTransactionReason> get adjustmentReasons => [
        MedicalTransactionReason.expiredDisposal,
        MedicalTransactionReason.auditCorrection,
        MedicalTransactionReason.other,
      ];
}

/// Expiry status calculation category
enum ExpiryStatus {
  expired('Expired', Color(0xFFDC2626), Color(0xFFFDE8E8)),
  critical('Expiring in < 30d', Color(0xFFEA580C), Color(0xFFFFF0E6)),
  warning('Expiring in 30-60d', Color(0xFFD97706), Color(0xFFFEF9C3)),
  safe('Safe (> 60d)', Color(0xFF16A34A), Color(0xFFDCFCE7));

  final String label;
  final Color color;
  final Color backgroundColor;

  const ExpiryStatus(this.label, this.color, this.backgroundColor);
}

/// Model representing a specific production batch of a medical item.
class MedicalBatchModel {
  final String id;
  final String itemId;
  final String itemName;
  final String itemCode;
  final String batchNumber;
  final DateTime expiryDate;
  final DateTime? mfgDate;
  final double quantity; // initial inward quantity
  final double availableQuantity; // current remaining quantity
  final double unitPrice;
  final double mrp;
  final String status; // ACTIVE, EXHAUSTED, EXPIRED, DISPOSED
  final String? gaushalaId;
  final String? supplierOrDonorName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MedicalBatchModel({
    required this.id,
    required this.itemId,
    this.itemName = '',
    this.itemCode = '',
    required this.batchNumber,
    required this.expiryDate,
    this.mfgDate,
    this.quantity = 0.0,
    this.availableQuantity = 0.0,
    this.unitPrice = 0.0,
    this.mrp = 0.0,
    this.status = 'ACTIVE',
    this.gaushalaId,
    this.supplierOrDonorName,
    this.createdAt,
    this.updatedAt,
  });

  bool get isExpired {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return exp.isBefore(today);
  }

  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return exp.difference(today).inDays;
  }

  bool get isExpiringSoon => !isExpired && daysUntilExpiry <= 30;
  bool get isExpiringWarning => !isExpired && daysUntilExpiry > 30 && daysUntilExpiry <= 60;
  bool get isSafe => !isExpired && daysUntilExpiry > 60;

  ExpiryStatus get expiryStatus {
    if (isExpired) return ExpiryStatus.expired;
    if (daysUntilExpiry <= 30) return ExpiryStatus.critical;
    if (daysUntilExpiry <= 60) return ExpiryStatus.warning;
    return ExpiryStatus.safe;
  }

  String get daysRemainingLabel {
    final days = daysUntilExpiry;
    if (days < 0) {
      return 'Expired ${(-days)}d ago';
    } else if (days == 0) {
      return 'Expires today';
    } else if (days == 1) {
      return 'Expires tomorrow';
    } else {
      return '$days days left';
    }
  }

  factory MedicalBatchModel.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic value, [double def = 0.0]) {
      if (value == null) return def;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? def;
    }

    DateTime parseDate(dynamic value, [DateTime? fallback]) {
      if (value is DateTime) return value;
      if (value != null) {
        final parsed = DateTime.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
      return fallback ?? DateTime.now().add(const Duration(days: 365));
    }

    String itId = '';
    String itName = '';
    String itCode = '';
    final rawItem = json['itemId'] ?? json['item_id'] ?? json['medicineId'] ?? json['item'] ?? json['medicine'];
    if (rawItem is Map) {
      itId = (rawItem['_id'] ?? rawItem['id'])?.toString() ?? '';
      itName = (rawItem['itemName'] ?? rawItem['name'] ?? rawItem['medicineName'])?.toString() ?? '';
      itCode = (rawItem['itemCode'] ?? rawItem['code'] ?? rawItem['sku'])?.toString() ?? '';
    } else if (rawItem != null) {
      itId = rawItem.toString();
    }
    if (itName.isEmpty) {
      itName = (json['itemName'] ?? json['item_name'] ?? json['medicineName'])?.toString() ?? '';
    }
    if (itCode.isEmpty) {
      itCode = (json['itemCode'] ?? json['item_code'] ?? json['sku'])?.toString() ?? '';
    }

    return MedicalBatchModel(
      id: (json['_id'] ?? json['id'] ?? json['batchId'])?.toString() ?? '',
      itemId: itId,
      itemName: itName,
      itemCode: itCode,
      batchNumber: (json['batchNumber'] ?? json['batch_number'] ?? json['batchNo'])?.toString() ?? 'BATCH-001',
      expiryDate: parseDate(json['expiryDate'] ?? json['expiry_date']),
      mfgDate: json['mfgDate'] != null ? parseDate(json['mfgDate']) : null,
      quantity: parseNum(json['quantity']),
      availableQuantity: parseNum(json['availableQuantity'] ?? json['currentStock'] ?? json['quantity']),
      unitPrice: parseNum(json['unitPrice'] ?? json['price'] ?? json['rate']),
      mrp: parseNum(json['mrp'] ?? json['unitPrice']),
      status: (json['status']?.toString() ?? 'ACTIVE').toUpperCase(),
      gaushalaId: (json['gaushalaId'] ?? json['gaushala_id'])?.toString(),
      supplierOrDonorName: (json['supplierOrDonorName'] ?? json['supplierName'])?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'itemId': itemId,
      'itemName': itemName,
      'itemCode': itemCode,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate.toIso8601String(),
      if (mfgDate != null) 'mfgDate': mfgDate!.toIso8601String(),
      'quantity': quantity,
      'availableQuantity': availableQuantity,
      'unitPrice': unitPrice,
      'mrp': mrp,
      'status': status,
      if (gaushalaId != null) 'gaushalaId': gaushalaId,
      if (supplierOrDonorName != null) 'supplierOrDonorName': supplierOrDonorName,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  MedicalBatchModel copyWith({
    String? id,
    String? itemId,
    String? itemName,
    String? itemCode,
    String? batchNumber,
    DateTime? expiryDate,
    DateTime? mfgDate,
    double? quantity,
    double? availableQuantity,
    double? unitPrice,
    double? mrp,
    String? status,
    String? gaushalaId,
    String? supplierOrDonorName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalBatchModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemCode: itemCode ?? this.itemCode,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      mfgDate: mfgDate ?? this.mfgDate,
      quantity: quantity ?? this.quantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      mrp: mrp ?? this.mrp,
      status: status ?? this.status,
      gaushalaId: gaushalaId ?? this.gaushalaId,
      supplierOrDonorName: supplierOrDonorName ?? this.supplierOrDonorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Model representing a Medical Item SKU in the Medicine Master
class MedicalItemModel {
  final String id;
  final String? gaushalaId;
  final String? gaushalaName;
  final String itemName;
  final String itemCode;
  final String category;
  final String unit;
  final double totalStock;
  final double minStockAlert;
  final String manufacturer;
  final String description;
  final int activeBatchesCount;
  final List<MedicalBatchModel> batches;
  final bool isActive;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MedicalItemModel({
    required this.id,
    this.gaushalaId,
    this.gaushalaName,
    required this.itemName,
    this.itemCode = '',
    this.category = 'TABLET',
    this.unit = 'PIECE',
    this.totalStock = 0.0,
    this.minStockAlert = 20.0,
    this.manufacturer = '',
    this.description = '',
    this.activeBatchesCount = 0,
    this.batches = const [],
    this.isActive = true,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  MedicalItemCategory get categoryEnum => MedicalItemCategory.fromCode(category);
  MedicalItemUnit get unitEnum => MedicalItemUnit.fromCode(unit);

  bool get isLowStock => totalStock <= minStockAlert;
  bool get isOutOfStock => totalStock <= 0.0;

  /// Returns batches sorted by FEFO (earliest expiry first, only active with positive stock)
  List<MedicalBatchModel> get fefoBatches {
    final list = batches.where((b) => b.availableQuantity > 0 && !b.isExpired).toList();
    list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return list;
  }

  /// All batches sorted by expiry (including expired ones)
  List<MedicalBatchModel> get sortedBatches {
    final list = batches.toList();
    list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return list;
  }

  MedicalBatchModel? get earliestExpiringBatch {
    final active = fefoBatches;
    return active.isNotEmpty ? active.first : null;
  }

  bool get hasExpiredBatches => batches.any((b) => b.isExpired && b.availableQuantity > 0);
  bool get hasExpiringSoonBatches => batches.any((b) => b.isExpiringSoon && b.availableQuantity > 0);

  factory MedicalItemModel.fromJson(Map<String, dynamic> json) {
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
    }
    if (gName == null && json['gaushalaName'] != null) {
      gName = json['gaushalaName']?.toString();
    }

    double parseNum(dynamic value, [double def = 0.0]) {
      if (value == null) return def;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? def;
    }

    final pId = (json['_id'] ?? json['id'])?.toString() ?? '';
    final pName = (json['itemName'] ?? json['name'] ?? json['medicineName'])?.toString() ?? '';
    final pCode = (json['itemCode'] ?? json['code'] ?? json['sku'])?.toString() ?? '';

    List<MedicalBatchModel> parsedBatches = [];
    if (json['batches'] is List) {
      parsedBatches = (json['batches'] as List)
          .whereType<Map>()
          .map((b) => MedicalBatchModel.fromJson(Map<String, dynamic>.from(b)))
          .toList();
    } else if (json['activeBatches'] is List) {
      parsedBatches = (json['activeBatches'] as List)
          .whereType<Map>()
          .map((b) => MedicalBatchModel.fromJson(Map<String, dynamic>.from(b)))
          .toList();
    }

    parsedBatches = parsedBatches.map((b) {
      return b.copyWith(
        itemId: b.itemId.isNotEmpty ? b.itemId : pId,
        itemName: b.itemName.isNotEmpty ? b.itemName : pName,
        itemCode: b.itemCode.isNotEmpty ? b.itemCode : pCode,
      );
    }).toList();

    double computedStock = parseNum(json['totalStock'] ?? json['currentStock']);
    if (computedStock == 0.0 && parsedBatches.isNotEmpty) {
      computedStock = parsedBatches.fold<double>(0.0, (sum, b) => sum + b.availableQuantity);
    }

    int activeCount = json['activeBatchesCount'] is int
        ? json['activeBatchesCount'] as int
        : parsedBatches.where((b) => b.availableQuantity > 0 && !b.isExpired).length;

    return MedicalItemModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      gaushalaId: gId,
      gaushalaName: gName,
      itemName: (json['itemName'] ?? json['name'] ?? json['medicineName'])?.toString() ?? '',
      itemCode: (json['itemCode'] ?? json['code'] ?? json['sku'])?.toString() ?? '',
      category: (json['category']?.toString() ?? 'TABLET').toUpperCase(),
      unit: (json['unit']?.toString() ?? 'PIECE').toUpperCase(),
      totalStock: computedStock,
      minStockAlert: parseNum(json['minStockAlert'] ?? json['minStockThreshold'] ?? 20.0, 20.0),
      manufacturer: (json['manufacturer'] ?? json['brand'] ?? '')?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      activeBatchesCount: activeCount,
      batches: parsedBatches,
      isActive: json['isActive'] != false,
      isDeleted: json['isDeleted'] == true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      if (gaushalaId != null) 'gaushalaId': gaushalaId,
      if (gaushalaName != null) 'gaushalaName': gaushalaName,
      'itemName': itemName,
      'itemCode': itemCode,
      'category': category,
      'unit': unit,
      'totalStock': totalStock,
      'minStockAlert': minStockAlert,
      'manufacturer': manufacturer,
      'description': description,
      'activeBatchesCount': activeBatchesCount,
      'batches': batches.map((b) => b.toJson()).toList(),
      'isActive': isActive,
      'isDeleted': isDeleted,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  MedicalItemModel copyWith({
    String? id,
    String? gaushalaId,
    String? gaushalaName,
    String? itemName,
    String? itemCode,
    String? category,
    String? unit,
    double? totalStock,
    double? minStockAlert,
    String? manufacturer,
    String? description,
    int? activeBatchesCount,
    List<MedicalBatchModel>? batches,
    bool? isActive,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalItemModel(
      id: id ?? this.id,
      gaushalaId: gaushalaId ?? this.gaushalaId,
      gaushalaName: gaushalaName ?? this.gaushalaName,
      itemName: itemName ?? this.itemName,
      itemCode: itemCode ?? this.itemCode,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      totalStock: totalStock ?? this.totalStock,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      manufacturer: manufacturer ?? this.manufacturer,
      description: description ?? this.description,
      activeBatchesCount: activeBatchesCount ?? this.activeBatchesCount,
      batches: batches ?? this.batches,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// DTO for Batch breakdown in a Transaction (added or deducted)
class MedicalBatchDeductionModel {
  final String? batchId;
  final String batchNumber;
  final double quantity;
  final DateTime? expiryDate;
  final DateTime? mfgDate;
  final double unitPrice;
  final double stockBefore;
  final double stockAfter;

  const MedicalBatchDeductionModel({
    this.batchId,
    required this.batchNumber,
    required this.quantity,
    this.expiryDate,
    this.mfgDate,
    this.unitPrice = 0.0,
    this.stockBefore = 0.0,
    this.stockAfter = 0.0,
  });

  factory MedicalBatchDeductionModel.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val, [double def = 0.0]) {
      if (val == null) return def;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? def;
    }

    DateTime? parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val != null) return DateTime.tryParse(val.toString());
      return null;
    }

    return MedicalBatchDeductionModel(
      batchId: (json['batchId'] ?? json['_id'] ?? json['id'])?.toString(),
      batchNumber: (json['batchNumber'] ?? json['batch_number'] ?? json['batchNo'])?.toString() ?? 'BATCH',
      quantity: parseNum(json['quantity'] ?? json['deductedQuantity']),
      expiryDate: parseDate(json['expiryDate'] ?? json['expiry_date']),
      mfgDate: parseDate(json['mfgDate'] ?? json['mfg_date']),
      unitPrice: parseNum(json['unitPrice'] ?? json['rate']),
      stockBefore: parseNum(json['stockBefore']),
      stockAfter: parseNum(json['stockAfter']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (batchId != null) 'batchId': batchId,
      'batchNumber': batchNumber,
      'quantity': quantity,
      if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
      if (mfgDate != null) 'mfgDate': mfgDate!.toIso8601String(),
      'unitPrice': unitPrice,
      'stockBefore': stockBefore,
      'stockAfter': stockAfter,
    };
  }
}

/// Model representing a Medical Stock Transaction (Inward, Outward, Disposal, Adjustment)
class MedicalTransactionModel {
  final String id;
  final String? gaushalaId;
  final String? gaushalaName;
  final String itemId;
  final String itemName;
  final String itemCode;
  final String category;
  final String unit;
  final String type; // INWARD, OUTWARD, EXPIRED_DISPOSAL, ADJUSTMENT
  final String reason;
  final double quantity;
  final double totalAmount;
  final String? cowId;
  final String? cowTagId;
  final String? shedId;
  final String? shedName;
  final String doctorName;
  final String prescribedFor;
  final String supplierOrDonorName;
  final String billOrReceiptNo;
  final String notes;
  final List<MedicalBatchDeductionModel> batches;
  final String? recordedById;
  final String? recordedByName;
  final double stockBefore;
  final double stockAfter;
  final DateTime? transactionDate;
  final DateTime? createdAt;

  const MedicalTransactionModel({
    required this.id,
    this.gaushalaId,
    this.gaushalaName,
    required this.itemId,
    required this.itemName,
    this.itemCode = '',
    this.category = 'TABLET',
    this.unit = 'PIECE',
    required this.type,
    required this.reason,
    required this.quantity,
    this.totalAmount = 0.0,
    this.cowId,
    this.cowTagId,
    this.shedId,
    this.shedName,
    this.doctorName = '',
    this.prescribedFor = '',
    this.supplierOrDonorName = '',
    this.billOrReceiptNo = '',
    this.notes = '',
    this.batches = const [],
    this.recordedById,
    this.recordedByName,
    this.stockBefore = 0.0,
    this.stockAfter = 0.0,
    this.transactionDate,
    this.createdAt,
  });

  MedicalTransactionType get typeEnum => MedicalTransactionType.fromCode(type);
  MedicalTransactionReason get reasonEnum => MedicalTransactionReason.fromCode(reason);

  bool get isInward => typeEnum == MedicalTransactionType.inward;
  bool get isOutward => typeEnum == MedicalTransactionType.outward;
  bool get isDisposal => typeEnum == MedicalTransactionType.expiredDisposal;
  bool get isAdjustment => typeEnum == MedicalTransactionType.adjustment;

  factory MedicalTransactionModel.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val, [double def = 0.0]) {
      if (val == null) return def;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? def;
    }

    DateTime? parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val != null) return DateTime.tryParse(val.toString());
      return null;
    }

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
    }
    if (gName == null && json['gaushalaName'] != null) {
      gName = json['gaushalaName']?.toString();
    }

    String itId = '';
    String itName = '';
    String itCode = '';
    String itCat = 'TABLET';
    String itUnit = 'PIECE';
    if (json['itemId'] != null) {
      if (json['itemId'] is Map) {
        final m = json['itemId'] as Map;
        itId = (m['_id'] ?? m['id'])?.toString() ?? '';
        itName = (m['itemName'] ?? m['name'])?.toString() ?? '';
        itCode = (m['itemCode'] ?? m['code'])?.toString() ?? '';
        itCat = (m['category'])?.toString() ?? 'TABLET';
        itUnit = (m['unit'])?.toString() ?? 'PIECE';
      } else {
        itId = json['itemId']?.toString() ?? '';
      }
    }
    if (itName.isEmpty && json['itemName'] != null) {
      itName = json['itemName']?.toString() ?? '';
    }
    if (itCode.isEmpty && json['itemCode'] != null) {
      itCode = json['itemCode']?.toString() ?? '';
    }
    if (json['category'] != null) itCat = json['category'].toString();
    if (json['unit'] != null) itUnit = json['unit'].toString();

    String? cowId;
    String? cowTag;
    if (json['cowId'] != null) {
      if (json['cowId'] is Map) {
        final m = json['cowId'] as Map;
        cowId = (m['_id'] ?? m['id'])?.toString();
        cowTag = (m['tagId'] ?? m['tag_id'] ?? m['calfName'])?.toString();
      } else {
        cowId = json['cowId']?.toString();
      }
    }
    if (cowTag == null && json['cowTagId'] != null) {
      cowTag = json['cowTagId']?.toString();
    }

    String? sId;
    String? sName;
    if (json['shedId'] != null) {
      if (json['shedId'] is Map) {
        final m = json['shedId'] as Map;
        sId = (m['_id'] ?? m['id'])?.toString();
        sName = (m['shedName'] ?? m['name'] ?? m['shedNumber'])?.toString();
      } else {
        sId = json['shedId']?.toString();
      }
    }
    if (sName == null && json['shedName'] != null) {
      sName = json['shedName']?.toString();
    }

    List<MedicalBatchDeductionModel> parsedBatches = [];
    final rawBatches = json['batches'] ?? json['deductedBatches'];
    if (rawBatches is List) {
      parsedBatches = rawBatches
          .whereType<Map>()
          .map((b) => MedicalBatchDeductionModel.fromJson(Map<String, dynamic>.from(b)))
          .toList();
    }

    return MedicalTransactionModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      gaushalaId: gId,
      gaushalaName: gName,
      itemId: itId,
      itemName: itName,
      itemCode: itCode,
      category: itCat,
      unit: itUnit,
      type: (json['type']?.toString() ?? 'INWARD').toUpperCase(),
      reason: (json['reason']?.toString() ?? 'PURCHASE').toUpperCase(),
      quantity: parseNum(json['quantity']),
      totalAmount: parseNum(json['totalAmount']),
      cowId: cowId,
      cowTagId: cowTag,
      shedId: sId,
      shedName: sName,
      doctorName: (json['doctorName'] ?? json['prescribedBy'])?.toString() ?? '',
      prescribedFor: (json['prescribedFor'] ?? json['diagnosis'])?.toString() ?? '',
      supplierOrDonorName: (json['supplierOrDonorName'] ?? json['supplierName'])?.toString() ?? '',
      billOrReceiptNo: (json['billOrReceiptNo'] ?? json['invoiceNumber'])?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      batches: parsedBatches,
      recordedById: (json['recordedBy'] is Map ? (json['recordedBy'] as Map)['_id'] : json['recordedBy'])?.toString(),
      recordedByName: (json['recordedBy'] is Map ? (json['recordedBy'] as Map)['name'] : json['recordedByName'])?.toString(),
      stockBefore: parseNum(json['stockBefore']),
      stockAfter: parseNum(json['stockAfter']),
      transactionDate: parseDate(json['transactionDate'] ?? json['createdAt']),
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      if (gaushalaId != null) 'gaushalaId': gaushalaId,
      if (gaushalaName != null) 'gaushalaName': gaushalaName,
      'itemId': itemId,
      'itemName': itemName,
      'itemCode': itemCode,
      'category': category,
      'unit': unit,
      'type': type,
      'reason': reason,
      'quantity': quantity,
      'totalAmount': totalAmount,
      if (cowId != null) 'cowId': cowId,
      if (cowTagId != null) 'cowTagId': cowTagId,
      if (shedId != null) 'shedId': shedId,
      if (shedName != null) 'shedName': shedName,
      'doctorName': doctorName,
      'prescribedFor': prescribedFor,
      'supplierOrDonorName': supplierOrDonorName,
      'billOrReceiptNo': billOrReceiptNo,
      'notes': notes,
      'batches': batches.map((b) => b.toJson()).toList(),
      if (recordedById != null) 'recordedById': recordedById,
      if (recordedByName != null) 'recordedByName': recordedByName,
      'stockBefore': stockBefore,
      'stockAfter': stockAfter,
      if (transactionDate != null) 'transactionDate': transactionDate!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}

/// Dashboard summary metric card data
class MedicalSummaryModel {
  final int totalItems;
  final int lowStockItemsCount;
  final int expiringSoonBatchesCount;
  final int expiredBatchesCount;
  final int totalBatchesCount;
  final double totalStockValue;

  const MedicalSummaryModel({
    this.totalItems = 0,
    this.lowStockItemsCount = 0,
    this.expiringSoonBatchesCount = 0,
    this.expiredBatchesCount = 0,
    this.totalBatchesCount = 0,
    this.totalStockValue = 0.0,
  });

  factory MedicalSummaryModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val, [int def = 0]) {
      if (val == null) return def;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? def;
    }

    double parseDouble(dynamic val, [double def = 0.0]) {
      if (val == null) return def;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? def;
    }

    return MedicalSummaryModel(
      totalItems: parseInt(json['totalItems'] ?? json['totalSKUs']),
      lowStockItemsCount: parseInt(json['lowStockItemsCount'] ?? json['lowStockCount']),
      expiringSoonBatchesCount: parseInt(json['expiringSoonBatchesCount'] ?? json['expiringCount']),
      expiredBatchesCount: parseInt(json['expiredBatchesCount'] ?? json['expiredCount']),
      totalBatchesCount: parseInt(json['totalBatchesCount']),
      totalStockValue: parseDouble(json['totalStockValue']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalItems': totalItems,
      'lowStockItemsCount': lowStockItemsCount,
      'expiringSoonBatchesCount': expiringSoonBatchesCount,
      'expiredBatchesCount': expiredBatchesCount,
      'totalBatchesCount': totalBatchesCount,
      'totalStockValue': totalStockValue,
    };
  }
}

/// DTO for entering a single batch in Stock Inward
class MedicalInwardBatchDto {
  String batchNumber;
  DateTime? expiryDate;
  DateTime? mfgDate;
  double quantity;
  double unitPrice;
  double mrp;

  MedicalInwardBatchDto({
    this.batchNumber = '',
    this.expiryDate,
    this.mfgDate,
    this.quantity = 0.0,
    this.unitPrice = 0.0,
    this.mrp = 0.0,
  });

  double get lineTotal => quantity * unitPrice;

  Map<String, dynamic> toJson() {
    return {
      'batchNumber': batchNumber.trim(),
      if (expiryDate != null)
        'expiryDate': "${expiryDate!.year.toString().padLeft(4, '0')}-${expiryDate!.month.toString().padLeft(2, '0')}-${expiryDate!.day.toString().padLeft(2, '0')}",
      if (mfgDate != null)
        'mfgDate': "${mfgDate!.year.toString().padLeft(4, '0')}-${mfgDate!.month.toString().padLeft(2, '0')}-${mfgDate!.day.toString().padLeft(2, '0')}",
      'quantity': quantity,
      'unitPrice': unitPrice,
      'mrp': mrp > 0 ? mrp : unitPrice,
    };
  }
}

/// Request DTO for Stock Inward
class MedicalStockInwardRequest {
  final String gaushalaId;
  final String itemId;
  final String reason;
  final String supplierOrDonorName;
  final String billOrReceiptNo;
  final DateTime? transactionDate;
  final List<MedicalInwardBatchDto> batches;

  const MedicalStockInwardRequest({
    required this.gaushalaId,
    required this.itemId,
    required this.reason,
    required this.supplierOrDonorName,
    required this.billOrReceiptNo,
    this.transactionDate,
    required this.batches,
  });

  Map<String, dynamic> toJson() {
    return {
      'gaushalaId': gaushalaId.trim(),
      'itemId': itemId.trim(),
      'reason': reason.trim(),
      'supplierOrDonorName': supplierOrDonorName.trim(),
      'billOrReceiptNo': billOrReceiptNo.trim(),
      if (transactionDate != null) 'transactionDate': transactionDate!.toIso8601String(),
      'batches': batches.map((b) => b.toJson()).toList(),
    };
  }
}

/// Request DTO for Stock Outward (FEFO automatic backend deduction)
class MedicalStockOutwardRequest {
  final String gaushalaId;
  final String itemId;
  final double quantity;
  final String reason; // TREATMENT, EMERGENCY, DAILY_CARE, OTHER
  final String? cowId;
  final String? shedId;
  final String? doctorName;
  final String? prescribedFor;
  final String? notes;
  final DateTime? transactionDate;

  const MedicalStockOutwardRequest({
    required this.gaushalaId,
    required this.itemId,
    required this.quantity,
    required this.reason,
    this.cowId,
    this.shedId,
    this.doctorName,
    this.prescribedFor,
    this.notes,
    this.transactionDate,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {
      'gaushalaId': gaushalaId.trim(),
      'itemId': itemId.trim(),
      'quantity': quantity,
      'reason': reason.trim(),
    };
    if (cowId != null && cowId!.trim().isNotEmpty) map['cowId'] = cowId!.trim();
    if (shedId != null && shedId!.trim().isNotEmpty) map['shedId'] = shedId!.trim();
    if (doctorName != null && doctorName!.trim().isNotEmpty) map['doctorName'] = doctorName!.trim();
    if (prescribedFor != null && prescribedFor!.trim().isNotEmpty) map['prescribedFor'] = prescribedFor!.trim();
    if (notes != null && notes!.trim().isNotEmpty) map['notes'] = notes!.trim();
    if (transactionDate != null) map['transactionDate'] = transactionDate!.toIso8601String();
    return map;
  }
}

/// Response payload from Stock Outward containing detailed deduction breakdown
class MedicalStockOutwardResponse {
  final MedicalItemModel? item;
  final MedicalTransactionModel? transaction;
  final List<MedicalBatchDeductionModel> deductedBatches;
  final bool lowStockAlert;

  const MedicalStockOutwardResponse({
    this.item,
    this.transaction,
    this.deductedBatches = const [],
    this.lowStockAlert = false,
  });

  factory MedicalStockOutwardResponse.fromJson(Map<String, dynamic> json) {
    MedicalItemModel? item;
    if (json['item'] is Map) {
      item = MedicalItemModel.fromJson(Map<String, dynamic>.from(json['item'] as Map));
    }

    MedicalTransactionModel? txn;
    if (json['transaction'] is Map) {
      txn = MedicalTransactionModel.fromJson(Map<String, dynamic>.from(json['transaction'] as Map));
    }

    List<MedicalBatchDeductionModel> deductions = [];
    if (json['deductedBatches'] is List) {
      deductions = (json['deductedBatches'] as List)
          .whereType<Map>()
          .map((b) => MedicalBatchDeductionModel.fromJson(Map<String, dynamic>.from(b)))
          .toList();
    } else if (txn != null && txn.batches.isNotEmpty) {
      deductions = txn.batches;
    }

    return MedicalStockOutwardResponse(
      item: item,
      transaction: txn,
      deductedBatches: deductions,
      lowStockAlert: json['lowStockAlert'] == true,
    );
  }
}

/// Request DTO for stock adjustment / disposal
class MedicalStockAdjustmentRequest {
  final String gaushalaId;
  final String itemId;
  final String? batchId;
  final String? batchNumber;
  final double quantity;
  final String reason; // EXPIRED_DISPOSAL or AUDIT_CORRECTION
  final String? notes;

  const MedicalStockAdjustmentRequest({
    required this.gaushalaId,
    required this.itemId,
    this.batchId,
    this.batchNumber,
    required this.quantity,
    required this.reason,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {
      'gaushalaId': gaushalaId.trim(),
      'itemId': itemId.trim(),
      'quantity': quantity,
      'reason': reason.trim(),
    };
    if (batchId != null && batchId!.trim().isNotEmpty) map['batchId'] = batchId!.trim();
    if (batchNumber != null && batchNumber!.trim().isNotEmpty) map['batchNumber'] = batchNumber!.trim();
    if (notes != null && notes!.trim().isNotEmpty) map['notes'] = notes!.trim();
    return map;
  }
}

/// Paginated result wrapper for Medical Items Master
class MedicalItemPaginatedResult {
  final List<MedicalItemModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const MedicalItemPaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });
}

/// Paginated result wrapper for Medical Transactions
class MedicalTransactionPaginatedResult {
  final List<MedicalTransactionModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const MedicalTransactionPaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });
}
