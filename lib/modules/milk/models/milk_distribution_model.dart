import 'package:flutter/material.dart';

/// Recipient types for Milk Distribution
enum RecipientType {
  customer('customer', 'Customer', Color(0xFF384C28), Icons.person_rounded),
  dairyPlant('dairy_plant', 'Dairy Plant', Color(0xFFE98324), Icons.factory_rounded),
  calfFeeding('calf_feeding', 'Calf Feeding', Color(0xFF5A7542), Icons.pets_rounded),
  staff('staff', 'Staff & Workers', Color(0xFF3B82F6), Icons.badge_rounded),
  other('other', 'Other', Color(0xFF6B7280), Icons.category_rounded);

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const RecipientType(this.value, this.label, this.color, this.icon);

  static RecipientType fromString(String? val) {
    if (val == null) return RecipientType.customer;
    final clean = val.trim().toLowerCase();
    return RecipientType.values.firstWhere(
      (r) => r.value == clean,
      orElse: () => RecipientType.customer,
    );
  }
}

/// Model representing a Milk Distribution transaction
class MilkDistributionModel {
  final String id;
  final String gaushalaId;
  final String milkDate;
  final String? distributionDate;
  final String shift; // morning | evening | all
  final double quantity;
  final String recipientType;
  final String recipientName;
  final String? customerId;
  final double ratePerLiter;
  final double totalAmount;
  final bool isDelayed;
  final String? remarks;
  final DateTime? createdAt;

  const MilkDistributionModel({
    required this.id,
    required this.gaushalaId,
    required this.milkDate,
    this.distributionDate,
    required this.shift,
    required this.quantity,
    required this.recipientType,
    required this.recipientName,
    this.customerId,
    required this.ratePerLiter,
    required this.totalAmount,
    this.isDelayed = false,
    this.remarks,
    this.createdAt,
  });

  RecipientType get recipientTypeEnum => RecipientType.fromString(recipientType);

  bool get isAllShiftPool => shift.toLowerCase() == 'all';
  bool get isDelayedDistribution => isDelayed || isAllShiftPool;

  static bool isMongoHexId(String? str) {
    if (str == null || str.trim().isEmpty) return false;
    return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(str.trim());
  }

  MilkDistributionModel copyWith({
    String? id,
    String? gaushalaId,
    String? milkDate,
    String? distributionDate,
    String? shift,
    double? quantity,
    String? recipientType,
    String? recipientName,
    String? customerId,
    double? ratePerLiter,
    double? totalAmount,
    bool? isDelayed,
    String? remarks,
    DateTime? createdAt,
  }) {
    return MilkDistributionModel(
      id: id ?? this.id,
      gaushalaId: gaushalaId ?? this.gaushalaId,
      milkDate: milkDate ?? this.milkDate,
      distributionDate: distributionDate ?? this.distributionDate,
      shift: shift ?? this.shift,
      quantity: quantity ?? this.quantity,
      recipientType: recipientType ?? this.recipientType,
      recipientName: recipientName ?? this.recipientName,
      customerId: customerId ?? this.customerId,
      ratePerLiter: ratePerLiter ?? this.ratePerLiter,
      totalAmount: totalAmount ?? this.totalAmount,
      isDelayed: isDelayed ?? this.isDelayed,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MilkDistributionModel.fromJson(Map<String, dynamic> json) {
    final qty = _toDouble(json['quantity']);
    final rate = _toDouble(json['ratePerLiter'] ?? json['rate_per_liter'] ?? json['rate']);
    final amt = json['totalAmount'] != null || json['total_amount'] != null
        ? _toDouble(json['totalAmount'] ?? json['total_amount'])
        : (qty * rate);

    final s = json['shift']?.toString().toLowerCase() ?? 'morning';
    final mDate = json['milkDate']?.toString() ?? json['milk_date']?.toString() ?? '';
    final dDate = json['distributionDate']?.toString() ?? json['distribution_date']?.toString() ?? json['entryDate']?.toString();

    bool delayed = json['isDelayed'] == true || json['is_delayed'] == true || s == 'all';
    if (!delayed && mDate.isNotEmpty && dDate != null && dDate.isNotEmpty && mDate != dDate) {
      delayed = true;
    }

    String rName = 'Customer';
    if (json['recipientName'] != null && json['recipientName'].toString().trim().isNotEmpty) {
      rName = json['recipientName'].toString().trim();
    } else if (json['recipient_name'] != null && json['recipient_name'].toString().trim().isNotEmpty) {
      rName = json['recipient_name'].toString().trim();
    } else if (json['customer'] is Map && json['customer']['name'] != null) {
      rName = json['customer']['name'].toString().trim();
    } else if (json['recipient'] is Map && json['recipient']['name'] != null) {
      rName = json['recipient']['name'].toString().trim();
    }

    String? cId;
    if (json['customerId'] != null) {
      cId = json['customerId'].toString();
    } else if (json['customer_id'] != null) {
      cId = json['customer_id'].toString();
    } else if (json['customer'] is Map && json['customer']['_id'] != null) {
      cId = json['customer']['_id'].toString();
    }

    return MilkDistributionModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      gaushalaId: json['gaushalaId']?.toString() ?? json['gaushala_id']?.toString() ?? '',
      milkDate: mDate,
      distributionDate: dDate,
      shift: s,
      quantity: qty,
      recipientType: json['recipientType']?.toString() ?? json['recipient_type']?.toString() ?? 'customer',
      recipientName: rName,
      customerId: cId,
      ratePerLiter: rate,
      totalAmount: amt,
      isDelayed: delayed,
      remarks: json['remarks']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gaushalaId': gaushalaId,
      'milkDate': milkDate,
      if (distributionDate != null) 'distributionDate': distributionDate,
      'shift': shift,
      'quantity': quantity,
      'recipientType': recipientType,
      'recipientName': recipientName,
      if (customerId != null) 'customerId': customerId,
      'ratePerLiter': ratePerLiter,
      'totalAmount': totalAmount,
      'isDelayed': isDelayed,
      if (remarks != null) 'remarks': remarks,
    };
  }
}

/// Paginated result wrapper for Milk Distribution
class MilkDistributionPaginatedResult {
  final List<MilkDistributionModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const MilkDistributionPaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory MilkDistributionPaginatedResult.empty() {
    return const MilkDistributionPaginatedResult(
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
