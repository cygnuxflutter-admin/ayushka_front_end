import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ayushka/app/data/models/notification_model.dart';
import 'package:ayushka/app/data/services/api_service.dart';
import '../models/fridge_stock_model.dart';
import '../models/milk_daily_summary_model.dart';
import '../models/milk_disposal_model.dart';
import '../models/milk_distribution_model.dart';
import '../models/milk_production_model.dart';

/// Centralized API service for the Milk Production & Distribution module.
/// Interacts with the backend REST endpoints under `/milk/*` using the existing ApiService Dio client.
class MilkApiService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  // ---------------------------------------------------------------------------
  // 1. DAILY BALANCE SHEET & SUMMARY
  // ---------------------------------------------------------------------------

  /// GET /api/v1/milk/daily-summary?gaushalaId={id}&date={YYYY-MM-DD}
  Future<MilkDailySummaryModel> getDailySummary({
    required String gaushalaId,
    required String date,
  }) async {
    try {
      final response = await _apiService.get(
        '/milk/daily-summary',
        queryParameters: {
          'gaushalaId': gaushalaId.trim(),
          'date': date.trim(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> raw = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final dynamic payload = raw['data'] ?? raw;
        if (payload is Map) {
          return MilkDailySummaryModel.fromJson(Map<String, dynamic>.from(payload));
        }
      }
      return const MilkDailySummaryModel();
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[MilkApiService] getDailySummary DioException: ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('[MilkApiService] getDailySummary Exception: $e');
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 2. MILK PRODUCTION (COW-WISE & SHIFT-WISE)
  // ---------------------------------------------------------------------------

  /// GET /api/v1/milk/production?gaushalaId={id}&date={date}&shift={morning|evening}&page={page}&limit={limit}
  Future<MilkProductionPaginatedResult> getProductionList({
    required String gaushalaId,
    required String date,
    String? shift,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final Map<String, dynamic> query = {
        'gaushalaId': gaushalaId.trim(),
        'date': date.trim(),
        'page': page,
        'limit': limit,
      };

      if (shift != null && shift.isNotEmpty && shift.toLowerCase() != 'all') {
        query['shift'] = shift.trim().toLowerCase();
      }

      final response = await _apiService.get(
        '/milk/production',
        queryParameters: query,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> raw = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final dynamic dataField = raw['data'] ?? raw;

        List<MilkProductionModel> items = [];
        int total = 0;
        int currentPage = page;
        int currentLimit = limit;
        int totalPages = 1;

        if (dataField is Map) {
          final map = Map<String, dynamic>.from(dataField);
          final listRaw = map['items'] ?? map['productions'] ?? map['records'] ?? map['data'];
          if (listRaw is List) {
            items = listRaw.map((e) => MilkProductionModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          }
          total = _toInt(map['total'] ?? map['totalItems'] ?? map['count'] ?? items.length);
          currentPage = _toInt(map['page'] ?? map['currentPage'] ?? page);
          currentLimit = _toInt(map['limit'] ?? limit);
          totalPages = _toInt(map['totalPages'] ?? ((total / currentLimit).ceil() <= 0 ? 1 : (total / currentLimit).ceil()));
        } else if (dataField is List) {
          items = dataField.map((e) => MilkProductionModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          total = items.length;
          totalPages = (total / limit).ceil() <= 0 ? 1 : (total / limit).ceil();
        }

        return MilkProductionPaginatedResult(
          items: items,
          total: total,
          page: currentPage,
          limit: currentLimit,
          totalPages: totalPages,
        );
      }
      return MilkProductionPaginatedResult.empty();
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[MilkApiService] getProductionList DioException: ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('[MilkApiService] getProductionList Exception: $e');
      }
      rethrow;
    }
  }

  /// Single Cow Entry: POST /api/v1/milk/production
  Future<MilkProductionModel> createSingleProduction(Map<String, dynamic> body) async {
    try {
      final response = await _apiService.post(
        '/milk/production',
        data: body,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final Map<String, dynamic> raw = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final dynamic dataField = raw['data'] ?? raw;
        if (dataField is Map) {
          return MilkProductionModel.fromJson(Map<String, dynamic>.from(dataField));
        }
      }
      throw Exception('Unexpected response format when recording milk production');
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Bulk Production Entry: POST /api/v1/milk/production/bulk
  Future<Map<String, dynamic>> createBulkProduction(Map<String, dynamic> body) async {
    try {
      final response = await _apiService.post(
        '/milk/production/bulk',
        data: body,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final Map<String, dynamic> raw = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return raw;
      }
      return {'success': true};
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  // ---------------------------------------------------------------------------
  // 3. MILK DISTRIBUTION
  // ---------------------------------------------------------------------------

  /// GET /api/v1/milk/distribution?gaushalaId={id}&milkDate={date}&shift={shift}&page={page}&limit={limit}
  Future<MilkDistributionPaginatedResult> getDistributionList({
    required String gaushalaId,
    required String milkDate,
    String? shift,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final Map<String, dynamic> query = {
        'gaushalaId': gaushalaId.trim(),
        'milkDate': milkDate.trim(),
        'page': page,
        'limit': limit,
      };

      if (shift != null && shift.isNotEmpty && shift.toLowerCase() != 'all') {
        query['shift'] = shift.trim().toLowerCase();
      }

      final response = await _apiService.get(
        '/milk/distribution',
        queryParameters: query,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> raw = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final dynamic dataField = raw['data'] ?? raw;

        List<MilkDistributionModel> items = [];
        int total = 0;
        int currentPage = page;
        int currentLimit = limit;
        int totalPages = 1;

        if (dataField is Map) {
          final map = Map<String, dynamic>.from(dataField);
          final listRaw = map['items'] ?? map['distributions'] ?? map['records'] ?? map['data'];
          if (listRaw is List) {
            items = listRaw.map((e) => MilkDistributionModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          }
          total = _toInt(map['total'] ?? map['totalItems'] ?? map['count'] ?? items.length);
          currentPage = _toInt(map['page'] ?? map['currentPage'] ?? page);
          currentLimit = _toInt(map['limit'] ?? limit);
          totalPages = _toInt(map['totalPages'] ?? ((total / currentLimit).ceil() <= 0 ? 1 : (total / currentLimit).ceil()));
        } else if (dataField is List) {
          items = dataField.map((e) => MilkDistributionModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          total = items.length;
          totalPages = (total / limit).ceil() <= 0 ? 1 : (total / limit).ceil();
        }

        return MilkDistributionPaginatedResult(
          items: items,
          total: total,
          page: currentPage,
          limit: currentLimit,
          totalPages: totalPages,
        );
      }
      return MilkDistributionPaginatedResult.empty();
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[MilkApiService] getDistributionList DioException: ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('[MilkApiService] getDistributionList Exception: $e');
      }
      rethrow;
    }
  }

  /// Record Distribution: POST /api/v1/milk/distribution
  Future<MilkDistributionModel> createDistribution(Map<String, dynamic> body) async {
    try {
      final response = await _apiService.post(
        '/milk/distribution',
        data: body,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final Map<String, dynamic> raw = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final dynamic dataField = raw['data'] ?? raw;
        if (dataField is Map) {
          return MilkDistributionModel.fromJson(Map<String, dynamic>.from(dataField));
        }
      }
      throw Exception('Unexpected response format when recording milk distribution');
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  // ---------------------------------------------------------------------------
  // 4. FRIDGE / LEFTOVER MILK STOCK & DISPOSAL
  // ---------------------------------------------------------------------------

  /// GET /api/v1/milk/fridge-stock?gaushalaId={id}
  Future<List<FridgeStockModel>> getFridgeStockList({
    required String gaushalaId,
  }) async {
    try {
      final response = await _apiService.get(
        '/milk/fridge-stock',
        queryParameters: {
          'gaushalaId': gaushalaId.trim(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> raw = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final dynamic dataField = raw['data'] ?? raw;
        if (dataField is List) {
          return dataField.map((e) => FridgeStockModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        } else if (dataField is Map && dataField['items'] is List) {
          return (dataField['items'] as List)
              .map((e) => FridgeStockModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[MilkApiService] getFridgeStockList DioException: ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('[MilkApiService] getFridgeStockList Exception: $e');
      }
      rethrow;
    }
  }

  /// POST /api/v1/milk/dispose
  Future<MilkDisposalModel> createDisposal(Map<String, dynamic> body) async {
    try {
      final response = await _apiService.post(
        '/milk/dispose',
        data: body,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final Map<String, dynamic> raw = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final dynamic dataField = raw['data'] ?? raw;
        if (dataField is Map) {
          return MilkDisposalModel.fromJson(Map<String, dynamic>.from(dataField));
        }
      }
      throw Exception('Unexpected response format when recording milk disposal');
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// GET /api/v1/milk/dispose?gaushalaId={id}&milkDate={date}&page={page}&limit={limit}
  Future<MilkDisposalPaginatedResult> getDisposalList({
    required String gaushalaId,
    String? milkDate,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final Map<String, dynamic> query = {
        'gaushalaId': gaushalaId.trim(),
        'page': page,
        'limit': limit,
      };

      if (milkDate != null && milkDate.isNotEmpty) {
        query['milkDate'] = milkDate.trim();
      }

      final response = await _apiService.get(
        '/milk/dispose',
        queryParameters: query,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> raw = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final dynamic dataField = raw['data'] ?? raw;

        List<MilkDisposalModel> items = [];
        int total = 0;
        int currentPage = page;
        int currentLimit = limit;
        int totalPages = 1;

        if (dataField is Map) {
          final map = Map<String, dynamic>.from(dataField);
          final listRaw = map['items'] ?? map['disposals'] ?? map['records'] ?? map['data'];
          if (listRaw is List) {
            items = listRaw.map((e) => MilkDisposalModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          }
          total = _toInt(map['total'] ?? map['totalItems'] ?? map['count'] ?? items.length);
          currentPage = _toInt(map['page'] ?? map['currentPage'] ?? page);
          currentLimit = _toInt(map['limit'] ?? limit);
          totalPages = _toInt(map['totalPages'] ?? ((total / currentLimit).ceil() <= 0 ? 1 : (total / currentLimit).ceil()));
        } else if (dataField is List) {
          items = dataField.map((e) => MilkDisposalModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          total = items.length;
          totalPages = (total / limit).ceil() <= 0 ? 1 : (total / limit).ceil();
        }

        return MilkDisposalPaginatedResult(
          items: items,
          total: total,
          page: currentPage,
          limit: currentLimit,
          totalPages: totalPages,
        );
      }
      return MilkDisposalPaginatedResult.empty();
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[MilkApiService] getDisposalList DioException: ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('[MilkApiService] getDisposalList Exception: $e');
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 5. MONTHLY VARIANCE & NOTIFICATIONS
  // ---------------------------------------------------------------------------

  /// Trigger Monthly Check: POST /api/v1/milk/alerts/check-monthly
  /// Body: { "gaushalaId": "...", "year": 2026, "month": 9 }
  Future<Map<String, dynamic>> checkMonthlyAlerts({
    required String gaushalaId,
    required int year,
    required int month,
  }) async {
    try {
      final response = await _apiService.post(
        '/milk/alerts/check-monthly',
        data: {
          'gaushalaId': gaushalaId.trim(),
          'year': year,
          'month': month,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> raw = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
        return raw;
      }
      return {'success': true};
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Fetch in-app milk production notifications:
  /// GET /api/v1/notifications?type=MILK_PRODUCTION_ALERT
  Future<List<NotificationModel>> getMilkAlertNotifications({String? gaushalaId}) async {
    try {
      final Map<String, dynamic> query = {
        'type': 'MILK_PRODUCTION_ALERT',
      };
      if (gaushalaId != null && gaushalaId.isNotEmpty) {
        query['gaushalaId'] = gaushalaId;
      }

      final response = await _apiService.get(
        '/notifications',
        queryParameters: query,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> raw = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final dynamic dataField = raw['data'] ?? raw;
        if (dataField is List) {
          return dataField.map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        } else if (dataField is Map) {
          final list = dataField['notifications'] ?? dataField['items'] ?? dataField['data'];
          if (list is List) {
            return list.map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          }
        }
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('[MilkApiService] getMilkAlertNotifications error: $e');
      }
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // ERROR PARSER
  // ---------------------------------------------------------------------------
  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        if (data['message'] != null) return data['message'].toString();
        if (data['error'] != null) return data['error'].toString();
      }
    }
    return e.message ?? 'An unexpected network error occurred';
  }
}

int _toInt(dynamic val) {
  if (val == null) return 0;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString()) ?? 0;
}
