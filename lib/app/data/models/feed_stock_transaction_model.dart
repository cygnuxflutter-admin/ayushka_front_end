import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/values/app_colors.dart';
import 'feed_item_model.dart';

/// Transaction types for Stock Movement:
/// INWARD (Stock received/purchased/donated)
/// OUTWARD (Stock consumed/fed/transferred)
enum FeedStockTransactionType {
  inward(
    'INWARD',
    'Inward',
    AppColors.primary,
    PhosphorIconsRegular.arrowDownLeft,
  ),
  outward(
    'OUTWARD',
    'Outward',
    Color(0xFFF59E0B),
    PhosphorIconsRegular.arrowUpRight,
  );

  final String code;
  final String label;
  final Color color;
  final IconData icon;

  const FeedStockTransactionType(this.code, this.label, this.color, this.icon);

  static FeedStockTransactionType fromCode(String? code) {
    if (code == null) return FeedStockTransactionType.inward;
    final upper = code.trim().toUpperCase();
    return FeedStockTransactionType.values.firstWhere(
      (t) => t.code == upper,
      orElse: () => FeedStockTransactionType.inward,
    );
  }
}

/// Reasons for Stock Transactions:
/// Inward allowed: PURCHASE, DONATION, OTHER
/// Outward allowed: DAILY_FEEDING, OTHER
enum FeedStockTransactionReason {
  purchase('PURCHASE', 'Purchase', AppColors.primary),
  donation('DONATION', 'Donation', Color(0xFF3B82F6)),
  dailyFeeding('DAILY_FEEDING', 'Daily Feeding', Color(0xFFF97316)),
  other('OTHER', 'Other', Color(0xFF6B7280));

  final String code;
  final String label;
  final Color color;

  const FeedStockTransactionReason(this.code, this.label, this.color);

  static FeedStockTransactionReason fromCode(String? code) {
    if (code == null) return FeedStockTransactionReason.other;
    final upper = code.trim().toUpperCase();
    return FeedStockTransactionReason.values.firstWhere(
      (r) => r.code == upper,
      orElse: () => FeedStockTransactionReason.other,
    );
  }

  static List<FeedStockTransactionReason> get inwardReasons => [
        FeedStockTransactionReason.purchase,
        FeedStockTransactionReason.donation,
        FeedStockTransactionReason.other,
      ];

  static List<FeedStockTransactionReason> get outwardReasons => [
        FeedStockTransactionReason.dailyFeeding,
        FeedStockTransactionReason.other,
      ];
}

/// Model representing a single Feed Stock Transaction (Inward or Outward)
/// in Ayushka Admin Portal.
class FeedStockTransactionModel {
  final String id;
  final String? gaushalaId;
  final String? gaushalaName;
  final String itemId;
  final String itemName;
  final String itemCode;
  final String category;
  final String type; // INWARD or OUTWARD
  final String reason; // PURCHASE, DONATION, DAILY_FEEDING, OTHER
  final double quantity;
  final String unit;
  final double ratePerUnit;
  final double totalAmount;
  final String? shedId;
  final String? shedName;
  final String? shedNumber;
  final DateTime? transactionDate;
  final String supplierOrDonorName;
  final String billOrReceiptNo;
  final String vehicleNumber;
  final String notes;
  final double stockBefore;
  final double stockAfter;
  final String? recordedById;
  final String? recordedByName;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FeedStockTransactionModel({
    required this.id,
    this.gaushalaId,
    this.gaushalaName,
    required this.itemId,
    required this.itemName,
    this.itemCode = '',
    this.category = 'GREEN_FODDER',
    required this.type,
    required this.reason,
    required this.quantity,
    this.unit = 'KG',
    this.ratePerUnit = 0.0,
    this.totalAmount = 0.0,
    this.shedId,
    this.shedName,
    this.shedNumber,
    this.transactionDate,
    this.supplierOrDonorName = '',
    this.billOrReceiptNo = '',
    this.vehicleNumber = '',
    this.notes = '',
    this.stockBefore = 0.0,
    this.stockAfter = 0.0,
    this.recordedById,
    this.recordedByName,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  FeedStockTransactionType get typeEnum => FeedStockTransactionType.fromCode(type);
  FeedStockTransactionReason get reasonEnum => FeedStockTransactionReason.fromCode(reason);
  FeedItemCategory get categoryEnum => FeedItemCategory.fromCode(category);
  FeedItemUnit get unitEnum => FeedItemUnit.fromCode(unit);

  bool get isInward => typeEnum == FeedStockTransactionType.inward;
  bool get isOutward => typeEnum == FeedStockTransactionType.outward;

  /// Quantity with signed representation: positive for inward, negative for outward
  double get signedQuantity => isInward ? quantity : -quantity;

  factory FeedStockTransactionModel.fromJson(Map<String, dynamic> json) {
    // 1. Gaushala parsing
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
    } else if (json['gaushala_id'] != null) {
      if (json['gaushala_id'] is Map) {
        final m = json['gaushala_id'] as Map;
        gId = (m['_id'] ?? m['id'])?.toString();
        gName = (m['gaushalaName'] ?? m['name'])?.toString();
      } else {
        gId = json['gaushala_id']?.toString();
      }
    }
    if (gName == null && json['gaushalaName'] != null) {
      gName = json['gaushalaName']?.toString();
    }

    // 2. Item parsing
    String itId = '';
    String itName = '';
    String itCode = '';
    String itCategory = 'GREEN_FODDER';
    String itUnit = 'KG';

    if (json['itemId'] != null) {
      if (json['itemId'] is Map) {
        final m = json['itemId'] as Map;
        itId = (m['_id'] ?? m['id'])?.toString() ?? '';
        itName = (m['itemName'] ?? m['name'])?.toString() ?? '';
        itCode = (m['itemCode'] ?? m['code'])?.toString() ?? '';
        itCategory = (m['category'])?.toString() ?? 'GREEN_FODDER';
        itUnit = (m['unit'])?.toString() ?? 'KG';
      } else {
        itId = json['itemId']?.toString() ?? '';
      }
    } else if (json['item_id'] != null) {
      itId = json['item_id']?.toString() ?? '';
    }

    if (itName.isEmpty && json['itemName'] != null) {
      itName = json['itemName']?.toString() ?? '';
    }
    if (itCode.isEmpty && json['itemCode'] != null) {
      itCode = json['itemCode']?.toString() ?? '';
    }
    if (json['category'] != null) {
      itCategory = json['category']?.toString() ?? itCategory;
    }
    if (json['unit'] != null) {
      itUnit = json['unit']?.toString() ?? itUnit;
    }

    // 3. Shed parsing
    String? sId;
    String? sName;
    String? sNumber;
    if (json['shedId'] != null) {
      if (json['shedId'] is Map) {
        final m = json['shedId'] as Map;
        sId = (m['_id'] ?? m['id'])?.toString();
        sName = (m['shedName'] ?? m['name'])?.toString();
        sNumber = (m['shedNumber'] ?? m['number'])?.toString();
      } else {
        sId = json['shedId']?.toString();
      }
    }
    if (sName == null && json['shedName'] != null) {
      sName = json['shedName']?.toString();
    }
    if (sNumber == null && json['shedNumber'] != null) {
      sNumber = json['shedNumber']?.toString();
    }

    // 4. Recorded By parsing
    String? recId;
    String? recName;
    if (json['recordedBy'] != null) {
      if (json['recordedBy'] is Map) {
        final m = json['recordedBy'] as Map;
        recId = (m['_id'] ?? m['id'])?.toString();
        recName = (m['name'] ?? m['username'])?.toString();
      } else {
        recId = json['recordedBy']?.toString();
      }
    } else if (json['createdBy'] != null) {
      if (json['createdBy'] is Map) {
        final m = json['createdBy'] as Map;
        recId = (m['_id'] ?? m['id'])?.toString();
        recName = (m['name'] ?? m['username'])?.toString();
      } else {
        recId = json['createdBy']?.toString();
      }
    }

    double parseNum(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? defaultValue;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return FeedStockTransactionModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      gaushalaId: gId,
      gaushalaName: gName,
      itemId: itId,
      itemName: itName,
      itemCode: itCode,
      category: itCategory,
      type: (json['type']?.toString() ?? 'INWARD').toUpperCase(),
      reason: (json['reason']?.toString() ?? 'PURCHASE').toUpperCase(),
      quantity: parseNum(json['quantity']),
      unit: itUnit,
      ratePerUnit: parseNum(json['ratePerUnit']),
      totalAmount: parseNum(json['totalAmount']),
      shedId: sId,
      shedName: sName,
      shedNumber: sNumber,
      transactionDate: parseDate(json['transactionDate'] ?? json['createdAt']),
      supplierOrDonorName: (json['supplierOrDonorName'] ?? json['supplierName'])?.toString() ?? '',
      billOrReceiptNo: (json['billOrReceiptNo'] ?? json['invoiceNumber'] ?? json['receiptNo'])?.toString() ?? '',
      vehicleNumber: json['vehicleNumber']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      stockBefore: parseNum(json['stockBefore']),
      stockAfter: parseNum(json['stockAfter']),
      recordedById: recId,
      recordedByName: recName,
      isDeleted: json['isDeleted'] == true,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
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
      'type': type,
      'reason': reason,
      'quantity': quantity,
      'unit': unit,
      'ratePerUnit': ratePerUnit,
      'totalAmount': totalAmount,
      if (shedId != null) 'shedId': shedId,
      if (shedName != null) 'shedName': shedName,
      if (shedNumber != null) 'shedNumber': shedNumber,
      if (transactionDate != null) 'transactionDate': transactionDate!.toIso8601String(),
      'supplierOrDonorName': supplierOrDonorName,
      'billOrReceiptNo': billOrReceiptNo,
      'vehicleNumber': vehicleNumber,
      'notes': notes,
      'stockBefore': stockBefore,
      'stockAfter': stockAfter,
      if (recordedById != null) 'recordedById': recordedById,
      if (recordedByName != null) 'recordedByName': recordedByName,
      'isDeleted': isDeleted,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

/// Request DTO for recording Inward Stock (Purchase, Donation, etc.)
class FeedStockInwardRequest {
  final String gaushalaId;
  final String itemId;
  final double quantity;
  final String unit;
  final String reason; // PURCHASE, DONATION, OTHER
  final double? ratePerUnit;
  final String? supplierOrDonorName;
  final String? billOrReceiptNo;
  final String? vehicleNumber;
  final DateTime? transactionDate;
  final String? notes;

  const FeedStockInwardRequest({
    required this.gaushalaId,
    required this.itemId,
    required this.quantity,
    required this.unit,
    required this.reason,
    this.ratePerUnit,
    this.supplierOrDonorName,
    this.billOrReceiptNo,
    this.vehicleNumber,
    this.transactionDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'gaushalaId': gaushalaId.trim(),
      'itemId': itemId.trim(),
      'quantity': quantity,
      'unit': unit.trim(),
      'reason': reason.trim(),
    };

    if (ratePerUnit != null) data['ratePerUnit'] = ratePerUnit;
    if (supplierOrDonorName != null && supplierOrDonorName!.trim().isNotEmpty) {
      data['supplierOrDonorName'] = supplierOrDonorName!.trim();
    }
    if (billOrReceiptNo != null && billOrReceiptNo!.trim().isNotEmpty) {
      data['billOrReceiptNo'] = billOrReceiptNo!.trim();
    }
    if (vehicleNumber != null && vehicleNumber!.trim().isNotEmpty) {
      data['vehicleNumber'] = vehicleNumber!.trim();
    }
    if (transactionDate != null) {
      data['transactionDate'] = transactionDate!.toUtc().toIso8601String();
    }
    if (notes != null && notes!.trim().isNotEmpty) {
      data['notes'] = notes!.trim();
    }

    return data;
  }
}

/// Request DTO for recording Outward Stock (Daily Feeding, etc.)
class FeedStockOutwardRequest {
  final String gaushalaId;
  final String itemId;
  final double quantity;
  final String unit;
  final String? shedId;
  final String reason; // DAILY_FEEDING, OTHER
  final DateTime? transactionDate;
  final String? notes;

  const FeedStockOutwardRequest({
    required this.gaushalaId,
    required this.itemId,
    required this.quantity,
    required this.unit,
    this.shedId,
    required this.reason,
    this.transactionDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'gaushalaId': gaushalaId.trim(),
      'itemId': itemId.trim(),
      'quantity': quantity,
      'unit': unit.trim(),
      'reason': reason.trim(),
    };

    if (shedId != null && shedId!.trim().isNotEmpty) {
      data['shedId'] = shedId!.trim();
    }
    if (transactionDate != null) {
      data['transactionDate'] = transactionDate!.toUtc().toIso8601String();
    }
    if (notes != null && notes!.trim().isNotEmpty) {
      data['notes'] = notes!.trim();
    }

    return data;
  }
}

/// Paginated result wrapper for Stock Transactions
class FeedStockTransactionPaginatedResult {
  final List<FeedStockTransactionModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const FeedStockTransactionPaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });
}
