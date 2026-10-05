library;

/// Models for Cattle Shed Transfer History API (GET /cows/shed-transfer-history)
/// Supports both Gaushala-wide and Cow-specific transfer records.

class ShedTransferHistoryResponse {
  final bool success;
  final String message;
  final ShedTransferHistoryData? data;

  const ShedTransferHistoryResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ShedTransferHistoryResponse.fromJson(Map<String, dynamic> json) {
    return ShedTransferHistoryResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? ShedTransferHistoryData.fromJson(json['data'] as Map<String, dynamic>)
          : (json['data'] != null && json['data'] is Map
              ? ShedTransferHistoryData.fromJson(Map<String, dynamic>.from(json['data'] as Map))
              : null),
    );
  }
}

class ShedTransferHistoryData {
  final TransferGaushalaSummary? gaushala;
  final TransferCowHeader? cow;
  final List<ShedTransferRecord> records;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const ShedTransferHistoryData({
    this.gaushala,
    this.cow,
    this.records = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 5,
    this.totalPages = 1,
  });

  factory ShedTransferHistoryData.fromJson(Map<String, dynamic> json) {
    TransferGaushalaSummary? gaushala;
    if (json['gaushala'] != null && json['gaushala'] is Map) {
      gaushala = TransferGaushalaSummary.fromJson(
        Map<String, dynamic>.from(json['gaushala'] as Map),
      );
    }

    TransferCowHeader? cow;
    if (json['cow'] != null && json['cow'] is Map) {
      cow = TransferCowHeader.fromJson(
        Map<String, dynamic>.from(json['cow'] as Map),
      );
    }

    final List<ShedTransferRecord> recordsList = [];
    if (json['records'] != null && json['records'] is List) {
      for (final item in json['records'] as List) {
        if (item is Map) {
          recordsList.add(
            ShedTransferRecord.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return ShedTransferHistoryData(
      gaushala: gaushala,
      cow: cow,
      records: recordsList,
      total: (json['total'] as num?)?.toInt() ?? recordsList.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? recordsList.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class ShedTransferRecord {
  final String id;
  final TransferCowSummary? cow;
  final TransferShedSummary? fromShed;
  final TransferShedSummary? toShed;
  final TransferGaushalaSummary? gaushala;
  final TransferUserSummary? transferredBy;
  final DateTime? transferDate;
  final String reason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShedTransferRecord({
    required this.id,
    this.cow,
    this.fromShed,
    this.toShed,
    this.gaushala,
    this.transferredBy,
    this.transferDate,
    this.reason = '',
    this.createdAt,
    this.updatedAt,
  });

  factory ShedTransferRecord.fromJson(Map<String, dynamic> json) {
    TransferCowSummary? cow;
    if (json['cow_id'] != null && json['cow_id'] is Map) {
      cow = TransferCowSummary.fromJson(
        Map<String, dynamic>.from(json['cow_id'] as Map),
      );
    }

    TransferShedSummary? fromShed;
    if (json['from_shed_id'] != null && json['from_shed_id'] is Map) {
      fromShed = TransferShedSummary.fromJson(
        Map<String, dynamic>.from(json['from_shed_id'] as Map),
      );
    }

    TransferShedSummary? toShed;
    if (json['to_shed_id'] != null && json['to_shed_id'] is Map) {
      toShed = TransferShedSummary.fromJson(
        Map<String, dynamic>.from(json['to_shed_id'] as Map),
      );
    }

    TransferGaushalaSummary? gaushala;
    if (json['gaushala_id'] != null && json['gaushala_id'] is Map) {
      gaushala = TransferGaushalaSummary.fromJson(
        Map<String, dynamic>.from(json['gaushala_id'] as Map),
      );
    }

    TransferUserSummary? transferredBy;
    if (json['transferredBy'] != null && json['transferredBy'] is Map) {
      transferredBy = TransferUserSummary.fromJson(
        Map<String, dynamic>.from(json['transferredBy'] as Map),
      );
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      try {
        return DateTime.parse(val.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }

    return ShedTransferRecord(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      cow: cow,
      fromShed: fromShed,
      toShed: toShed,
      gaushala: gaushala,
      transferredBy: transferredBy,
      transferDate: parseDate(json['transferDate']),
      reason: json['reason']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}

class TransferCowSummary {
  final String id;
  final String tagId;
  final String? calfName;
  final String? breedName;
  final String? typeName;
  final bool isFemale;
  final String? avatarUrl;
  final bool isDied;

  const TransferCowSummary({
    required this.id,
    required this.tagId,
    this.calfName,
    this.breedName,
    this.typeName,
    this.isFemale = true,
    this.avatarUrl,
    this.isDied = false,
  });

  factory TransferCowSummary.fromJson(Map<String, dynamic> json) {
    String? bName;
    if (json['breed'] != null) {
      if (json['breed'] is Map) {
        final bMap = json['breed'] as Map;
        bName = bMap['breedName']?.toString() ?? bMap['name']?.toString();
      } else {
        bName = json['breed'].toString();
      }
    }

    String? tName;
    if (json['type'] != null) {
      if (json['type'] is Map) {
        final tMap = json['type'] as Map;
        tName = tMap['typeName']?.toString() ?? tMap['name']?.toString();
      } else {
        tName = json['type'].toString();
      }
    }

    return TransferCowSummary(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      tagId: json['tag_id']?.toString() ?? json['tagId']?.toString() ?? 'Unknown',
      calfName: json['calf_name']?.toString() ?? json['calfName']?.toString(),
      breedName: bName,
      typeName: tName,
      isFemale: json['isFemale'] as bool? ?? true,
      avatarUrl: json['avatarUrl']?.toString(),
      isDied: json['isDied'] as bool? ?? false,
    );
  }

  String get displayName {
    if (calfName != null && calfName!.trim().isNotEmpty) {
      return '$tagId ($calfName)';
    }
    return tagId;
  }
}

class TransferShedSummary {
  final String id;
  final String shedName;
  final String shedNumber;

  const TransferShedSummary({
    required this.id,
    required this.shedName,
    required this.shedNumber,
  });

  factory TransferShedSummary.fromJson(Map<String, dynamic> json) {
    return TransferShedSummary(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      shedName: json['shedName']?.toString() ?? json['name']?.toString() ?? 'Unnamed Shed',
      shedNumber: json['shedNumber']?.toString() ?? json['number']?.toString() ?? '',
    );
  }

  String get display {
    if (shedNumber.isNotEmpty) {
      return '$shedName ($shedNumber)';
    }
    return shedName;
  }
}

class TransferGaushalaSummary {
  final String id;
  final String gaushalaName;

  const TransferGaushalaSummary({
    required this.id,
    required this.gaushalaName,
  });

  factory TransferGaushalaSummary.fromJson(Map<String, dynamic> json) {
    return TransferGaushalaSummary(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      gaushalaName: json['gaushalaName']?.toString() ?? json['name']?.toString() ?? '',
    );
  }
}

class TransferUserSummary {
  final String id;
  final String name;
  final String? emailId;
  final String? username;

  const TransferUserSummary({
    required this.id,
    required this.name,
    this.emailId,
    this.username,
  });

  factory TransferUserSummary.fromJson(Map<String, dynamic> json) {
    return TransferUserSummary(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Staff Member',
      emailId: json['emailId']?.toString() ?? json['email']?.toString(),
      username: json['username']?.toString(),
    );
  }
}

class TransferCowHeader {
  final String id;
  final String tagId;
  final String? calfName;

  const TransferCowHeader({
    required this.id,
    required this.tagId,
    this.calfName,
  });

  factory TransferCowHeader.fromJson(Map<String, dynamic> json) {
    return TransferCowHeader(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      tagId: json['tag_id']?.toString() ?? json['tagId']?.toString() ?? '',
      calfName: json['calf_name']?.toString() ?? json['calfName']?.toString(),
    );
  }

  String get displayName {
    if (calfName != null && calfName!.trim().isNotEmpty) {
      return '$tagId ($calfName)';
    }
    return tagId;
  }
}
