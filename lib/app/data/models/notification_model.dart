import 'package:intl/intl.dart';

/// Notification Alert Model
class NotificationModel {
  final String id;
  final String? gaushalaId;
  final String title;
  final String message;
  final String? type;
  final String? treatmentId;
  final String? cowId;
  final String? cowTagId;
  final int? doseNumber;
  final int? totalDoses;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? scheduledDate;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    this.gaushalaId,
    required this.title,
    required this.message,
    this.type,
    this.treatmentId,
    this.cowId,
    this.cowTagId,
    this.doseNumber,
    this.totalDoses,
    this.isRead = false,
    this.readAt,
    this.scheduledDate,
    this.createdAt,
  });

  String get timeAgo {
    if (createdAt == null) return '';
    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('dd MMM, hh:mm a').format(createdAt!);
    }
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return null;
      }
    }

    // Extract treatment id if nested
    String? tId;
    if (json['treatmentId'] is Map) {
      tId = (json['treatmentId']['_id'] ?? json['treatmentId']['id'])?.toString();
    } else {
      tId = json['treatmentId']?.toString() ?? json['treatment_id']?.toString();
    }

    // Extract cow details
    String? cId;
    String? cTag;
    if (json['cowId'] is Map) {
      final cowMap = Map<String, dynamic>.from(json['cowId'] as Map);
      cId = (cowMap['_id'] ?? cowMap['id'])?.toString();
      cTag = cowMap['tag_id']?.toString() ?? cowMap['tagId']?.toString();
    } else {
      cId = json['cowId']?.toString() ?? json['cow_id']?.toString();
      cTag = json['cowTag']?.toString() ?? json['tag_id']?.toString();
    }

    final bool read = json['isRead'] == true ||
        json['is_read'] == true ||
        json['read'] == true;

    return NotificationModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      gaushalaId: (json['gaushalaId'] ?? json['gaushala_id'])?.toString(),
      title: (json['title'] ?? 'Alert').toString(),
      message: (json['message'] ?? '').toString(),
      type: json['type']?.toString(),
      treatmentId: tId,
      cowId: cId,
      cowTagId: cTag,
      doseNumber: int.tryParse(json['doseNumber']?.toString() ?? json['dose_number']?.toString() ?? ''),
      totalDoses: int.tryParse(json['totalDoses']?.toString() ?? json['total_doses']?.toString() ?? ''),
      isRead: read,
      readAt: parseDate(json['readAt'] ?? json['read_at']),
      scheduledDate: parseDate(json['scheduledDate'] ?? json['scheduled_date']),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      if (gaushalaId != null) 'gaushalaId': gaushalaId,
      'title': title,
      'message': message,
      if (type != null) 'type': type,
      if (treatmentId != null) 'treatmentId': treatmentId,
      if (cowId != null) 'cowId': cowId,
      if (doseNumber != null) 'doseNumber': doseNumber,
      if (totalDoses != null) 'totalDoses': totalDoses,
      'isRead': isRead,
      if (readAt != null) 'readAt': readAt!.toIso8601String(),
      if (scheduledDate != null) 'scheduledDate': scheduledDate!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? gaushalaId,
    String? title,
    String? message,
    String? type,
    String? treatmentId,
    String? cowId,
    String? cowTagId,
    int? doseNumber,
    int? totalDoses,
    bool? isRead,
    DateTime? readAt,
    DateTime? scheduledDate,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      gaushalaId: gaushalaId ?? this.gaushalaId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      treatmentId: treatmentId ?? this.treatmentId,
      cowId: cowId ?? this.cowId,
      cowTagId: cowTagId ?? this.cowTagId,
      doseNumber: doseNumber ?? this.doseNumber,
      totalDoses: totalDoses ?? this.totalDoses,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Paginated notifications result
class NotificationPaginatedResult {
  final List<NotificationModel> items;
  final int unreadCount;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const NotificationPaginatedResult({
    required this.items,
    this.unreadCount = 0,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });
}
