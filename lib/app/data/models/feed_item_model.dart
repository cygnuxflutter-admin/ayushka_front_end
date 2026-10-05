import 'package:flutter/material.dart';

/// Categories supported by backend for Feed Items:
/// GREEN_FODDER, DRY_FODDER, CONCENTRATE_FEED, SUPPLEMENT, OTHER
enum FeedItemCategory {
  greenFodder('GREEN_FODDER', 'Green Fodder', Color(0xFF10B981)),
  dryFodder('DRY_FODDER', 'Dry Fodder', Color(0xFFF59E0B)),
  concentrateFeed('CONCENTRATE_FEED', 'Concentrate Feed', Color(0xFF6366F1)),
  supplement('SUPPLEMENT', 'Supplement', Color(0xFF8B5CF6)),
  other('OTHER', 'Other', Color(0xFF6B7280));

  final String code;
  final String label;
  final Color color;

  const FeedItemCategory(this.code, this.label, this.color);

  static FeedItemCategory fromCode(String? code) {
    if (code == null) return FeedItemCategory.other;
    final upper = code.trim().toUpperCase();
    return FeedItemCategory.values.firstWhere(
      (c) => c.code == upper,
      orElse: () => FeedItemCategory.other,
    );
  }
}

/// Measurement units supported by backend for Feed Items:
/// KG, TON, QUINTAL, BAG, BUNDLE, LITER, OTHER
enum FeedItemUnit {
  kg('KG', 'Kilogram (KG)', 'KG'),
  ton('TON', 'Ton', 'TON'),
  quintal('QUINTAL', 'Quintal', 'QTL'),
  bag('BAG', 'Bag', 'BAG'),
  bundle('BUNDLE', 'Bundle', 'BND'),
  liter('LITER', 'Liter', 'L'),
  other('OTHER', 'Other', 'UNIT');

  final String code;
  final String label;
  final String shortLabel;

  const FeedItemUnit(this.code, this.label, this.shortLabel);

  static FeedItemUnit fromCode(String? code) {
    if (code == null) return FeedItemUnit.kg;
    final upper = code.trim().toUpperCase();
    return FeedItemUnit.values.firstWhere(
      (u) => u.code == upper,
      orElse: () => FeedItemUnit.other,
    );
  }
}

/// Model representing a Feed Item / Stock Master item in Ayushka Admin Portal.
class FeedItemModel {
  final String id;
  final String? gaushalaId;
  final String? gaushalaName;
  final String itemName;
  final String itemCode;
  final String category;
  final String unit;
  final double currentStock;
  final double minStockAlert;
  final double unitPrice;
  final String description;
  final bool isActive;
  final bool isDeleted;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FeedItemModel({
    required this.id,
    this.gaushalaId,
    this.gaushalaName,
    required this.itemName,
    this.itemCode = '',
    this.category = 'GREEN_FODDER',
    this.unit = 'KG',
    this.currentStock = 0.0,
    this.minStockAlert = 50.0,
    this.unitPrice = 0.0,
    this.description = '',
    this.isActive = true,
    this.isDeleted = false,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  FeedItemCategory get categoryEnum => FeedItemCategory.fromCode(category);
  FeedItemUnit get unitEnum => FeedItemUnit.fromCode(unit);

  bool get isLowStock => currentStock <= minStockAlert;
  bool get isOutOfStock => currentStock <= 0.0;

  factory FeedItemModel.fromJson(Map<String, dynamic> json) {
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
    } else if (json['gaushala'] != null) {
      if (json['gaushala'] is Map) {
        final m = json['gaushala'] as Map;
        gId = (m['_id'] ?? m['id'])?.toString();
        gName = (m['gaushalaName'] ?? m['name'])?.toString();
      } else {
        gId = json['gaushala']?.toString();
      }
    }

    if (gName == null && json['gaushalaName'] != null) {
      gName = json['gaushalaName']?.toString();
    }

    String? createdByStr;
    if (json['createdBy'] != null) {
      if (json['createdBy'] is Map) {
        final m = json['createdBy'] as Map;
        createdByStr = (m['name'] ?? m['_id'])?.toString();
      } else {
        createdByStr = json['createdBy']?.toString();
      }
    }

    double parseNum(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? defaultValue;
    }

    return FeedItemModel(
      id: (json['_id'] ?? json['id']) as String? ?? '',
      gaushalaId: gId,
      gaushalaName: gName,
      itemName: (json['itemName'] ?? json['name']) as String? ?? '',
      itemCode: (json['itemCode'] ?? json['code']) as String? ?? '',
      category: (json['category'] as String?)?.toUpperCase() ?? 'GREEN_FODDER',
      unit: (json['unit'] as String?)?.toUpperCase() ?? 'KG',
      currentStock: parseNum(json['currentStock'] ?? json['initialStock']),
      minStockAlert: parseNum(json['minStockAlert'], 50.0),
      unitPrice: parseNum(json['unitPrice']),
      description: (json['description'] as String?) ?? '',
      isActive: (json['isActive'] as bool?) ?? true,
      isDeleted: (json['isDeleted'] as bool?) ?? false,
      createdBy: createdByStr,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson({bool includeInitialStock = false}) {
    return {
      if (id.isNotEmpty) '_id': id,
      if (gaushalaId != null && gaushalaId!.isNotEmpty) 'gaushalaId': gaushalaId,
      'itemName': itemName.trim(),
      'itemCode': itemCode.trim(),
      'category': category,
      'unit': unit,
      if (includeInitialStock) 'initialStock': currentStock,
      'minStockAlert': minStockAlert,
      'unitPrice': unitPrice,
      'description': description.trim(),
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  FeedItemModel copyWith({
    String? id,
    String? gaushalaId,
    String? gaushalaName,
    String? itemName,
    String? itemCode,
    String? category,
    String? unit,
    double? currentStock,
    double? minStockAlert,
    double? unitPrice,
    String? description,
    bool? isActive,
    bool? isDeleted,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FeedItemModel(
      id: id ?? this.id,
      gaushalaId: gaushalaId ?? this.gaushalaId,
      gaushalaName: gaushalaName ?? this.gaushalaName,
      itemName: itemName ?? this.itemName,
      itemCode: itemCode ?? this.itemCode,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      unitPrice: unitPrice ?? this.unitPrice,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
