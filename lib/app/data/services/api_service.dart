import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getx;
import '../../core/values/app_constants.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../routes/app_routes.dart';
import '../models/auth_tokens_model.dart';
import '../models/breed_model.dart';
import '../models/cow_model.dart';
import '../models/department_model.dart';
import '../models/department_summary_model.dart';
import '../models/feed_item_model.dart';
import '../models/feed_stock_transaction_model.dart';
import '../models/gaushala_model.dart';
import '../models/role_model.dart';
import '../models/medical_item_model.dart';
import '../models/notification_model.dart';
import '../models/shed_model.dart';
import '../models/shed_transfer_history_model.dart';
import '../models/treatment_model.dart';
import '../models/type_model.dart';
import '../models/user_model.dart';
import '../models/worker_model.dart';
import '../../../models/permission_model.dart';
import '../models/dashboard_alerts_model.dart';
import 'storage_service.dart';

/// Centralized HTTP networking service powered by Dio.
/// Platform-safe for Web, Desktop, and Mobile.
class ApiService extends getx.GetxService {
  late final Dio _dio;
  late final StorageService _storageService;

  Completer<String?>? _refreshTokenCompleter;
  bool _isRedirectingToAuth = false;

  @override
  void onInit() {
    super.onInit();
    _storageService = getx.Get.find<StorageService>();
    _initDio();
  }

  void _initDio() {
    final BaseOptions options = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      sendTimeout: kIsWeb ? null : AppConstants.sendTimeout,
      headers: {
        'Accept': 'application/json',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
      },
    );

    _dio = Dio(options);

    // Request & Response Interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          final isAuthPath = options.path.contains('/auth/login') ||
              options.path.contains('/auth/refresh-token');
          if (!isAuthPath) {
            final String? token = _storageService.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          if (options.data != null) {
            if (options.data is! FormData && !options.headers.containsKey('Content-Type')) {
              options.headers['Content-Type'] = 'application/json';
            }
            if (kIsWeb) {
              options.sendTimeout = AppConstants.sendTimeout;
            }
          } else {
            options.headers.remove('Content-Type');
            if (kIsWeb) {
              options.sendTimeout = null;
            }
          }

          if (kDebugMode) {
            print('[DIO REQUEST] => ${options.method} ${options.uri}');
            if (options.data != null) print('[DIO DATA] => ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          if (kDebugMode) {
            print('[DIO RESPONSE] <= [${response.statusCode}] ${response.requestOptions.uri}');
          }
          return handler.next(response);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          if (kDebugMode) {
            print('[DIO ERROR] !! [${error.response?.statusCode}] ${error.message}');
          }

          final requestPath = error.requestOptions.path;
          final isAuthLogin = requestPath.contains('/auth/login');
          final isRefreshToken = requestPath.contains('/auth/refresh-token');

          // Handle 401 Unauthorized: automatically refresh token and retry request
          if (error.response?.statusCode == 401 && !isAuthLogin && !isRefreshToken) {
            if (_storageService.hasRefreshToken) {
              final newAccessToken = await _performTokenRefresh();
              if (newAccessToken != null && newAccessToken.isNotEmpty) {
                // Retry failed request with new access token
                final retryOptions = error.requestOptions;
                retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                try {
                  final retryResponse = await _dio.fetch(retryOptions);
                  return handler.resolve(retryResponse);
                } on DioException catch (retryError) {
                  return handler.next(retryError);
                }
              }
            }

            // If refresh token doesn't exist or refresh failed:
            _redirectToLogin();
            return handler.next(error);
          }

          if (isRefreshToken) {
            return handler.next(error);
          }

          _handleHttpError(error);
          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _performTokenRefresh() async {
    if (_refreshTokenCompleter != null) {
      return await _refreshTokenCompleter!.future;
    }

    _refreshTokenCompleter = Completer<String?>();
    try {
      final tokens = await refreshToken();
      final newToken = tokens?.accessToken;
      _refreshTokenCompleter!.complete(newToken);
      return newToken;
    } catch (e) {
      _refreshTokenCompleter!.complete(null);
      return null;
    } finally {
      _refreshTokenCompleter = null;
    }
  }

  void _redirectToLogin() {
    if (_isRedirectingToAuth) return; // Guard: already redirecting
    _isRedirectingToAuth = true;
    _storageService.removeToken();
    _storageService.removeUser();
    CustomSnackbar.showError(
      title: 'Session Expired',
      message: 'Your login session has expired. Please sign in again.',
    );
    getx.Get.offAllNamed(AppRoutes.auth);
    // Reset after a short delay to allow future redirects after re-login
    Future.delayed(const Duration(seconds: 2), () {
      _isRedirectingToAuth = false;
    });
  }

  void _handleHttpError(DioException error) {
    final isAuthLogin = error.requestOptions.path.contains('/auth/login');
    if (error.response?.statusCode == 401 && !isAuthLogin) {
      _redirectToLogin();
      return;
    }

    String message = 'An unexpected network error occurred.';
    if (error.response?.statusCode == 429) {
      message = 'Too many requests. Please wait a few seconds before refreshing again.';
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timed out. Please check your network connection.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Cannot connect to server. Please verify network access.';
    } else if (error.response?.data != null && error.response?.data is Map) {
      message = error.response?.data['message']?.toString() ?? message;
    } else if (error.response?.data is String &&
        (error.response?.data as String).trim().isNotEmpty &&
        !(error.response?.data as String).contains('<html')) {
      message = (error.response?.data as String).trim();
    }

    CustomSnackbar.showError(
      title: isAuthLogin ? 'Login Failed' : 'Request Failed',
      message: message,
    );
  }

  // -------------------------------------------------------------
  // GENERIC HTTP METHODS
  // -------------------------------------------------------------
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  // -------------------------------------------------------------
  // AUTHENTICATION
  // -------------------------------------------------------------
  Future<UserModel> login({
    String? username,
    String? userId,
    String? email,
    required String password,
  }) async {
    final String userIdentifier = (username ?? userId ?? email ?? '').trim();

    final response = await _dio.post(
      '/auth/login',
      data: {
        'username': userIdentifier,
        'password': password,
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['success'] == true && responseData['data'] != null) {
        final data = responseData['data'] as Map<String, dynamic>;
        final String? token = data['accessToken'] as String?;
        final String? refreshToken = data['refreshToken'] as String?;
        final userJson = data['user'] as Map<String, dynamic>? ?? {};

        final user = UserModel.fromJson({
          ...userJson,
          'token': token,
          'refreshToken': refreshToken,
        });

        if (token != null && token.isNotEmpty) {
          await _storageService.saveToken(token);
        }
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await _storageService.saveRefreshToken(refreshToken);
        }
        await _storageService.saveUser(user);
        return user;
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Login failed. Please check your credentials.',
    );
  }

  /// Calls the refresh token API: POST /auth/refresh-token
  /// If [token] is provided, uses that token; otherwise retrieves the stored refresh token.
  /// On success, automatically persists new tokens and returns [AuthTokensModel].
  Future<AuthTokensModel?> refreshToken({String? token}) async {
    final String? storedRefreshToken = token ?? _storageService.getRefreshToken();
    if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
      if (kDebugMode) {
        print('[REFRESH TOKEN] No refresh token available');
      }
      return null;
    }

    try {
      final response = await _dio.post(
        '/auth/refresh-token',
        data: {
          'refreshToken': storedRefreshToken,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['success'] == true && responseData['data'] != null) {
          final tokens = AuthTokensModel.fromJson(
            Map<String, dynamic>.from(responseData['data'] as Map),
          );

          if (tokens.accessToken.isNotEmpty) {
            await _storageService.saveToken(tokens.accessToken);
          }
          if (tokens.refreshToken.isNotEmpty) {
            await _storageService.saveRefreshToken(tokens.refreshToken);
          }

          final currentUser = _storageService.getUser();
          if (currentUser != null && tokens.accessToken.isNotEmpty) {
            await _storageService.saveUser(
              currentUser.copyWith(
                token: tokens.accessToken,
                refreshToken: tokens.refreshToken,
              ),
            );
          }

          if (kDebugMode) {
            print('[REFRESH TOKEN] Token refreshed successfully.');
          }
          return tokens;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[REFRESH TOKEN ERROR] $e');
      }
    }
    return null;
  }

  // -------------------------------------------------------------
  // ROLES MASTER
  // -------------------------------------------------------------
  Future<List<RoleModel>> getRoles() async {
    final response = await _dio.get('/roles');
    if (response.statusCode == 200 && response.data != null) {
      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is List) {
        final List list = responseData['data'] as List;
        return list
            .map((item) => RoleModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    }
    return [];
  }

  Future<RoleModel> createRole(String roleName) async {
    final response = await _dio.post(
      '/roles',
      data: {
        'roleName': roleName.trim(),
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return RoleModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to create role.',
    );
  }

  Future<RoleModel> updateRole(String id, String roleName) async {
    Response response;
    try {
      response = await _dio.post(
        '/roles/$id/update',
        data: {
          'roleName': roleName.trim(),
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        try {
          response = await _dio.post(
            '/roles/$id',
            data: {
              'roleName': roleName.trim(),
            },
          );
        } catch (_) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return RoleModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        } else if (responseData['_id'] != null || responseData['roleName'] != null) {
          return RoleModel.fromJson(responseData);
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to update role.',
    );
  }

  Future<bool> deleteRole(String id) async {
    final response = await _dio.delete('/roles/$id');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // -------------------------------------------------------------
  // GAUSHALAS MASTER
  // -------------------------------------------------------------
  Future<List<GaushalaModel>> getGaushalas() async {
    final response = await _dio.get('/gaushalas');
    if (response.statusCode == 200 && response.data != null) {
      if (response.data is List) {
        final List list = response.data as List;
        return list
            .map((item) => GaushalaModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is List) {
        final List list = responseData['data'] as List;
        return list
            .map((item) => GaushalaModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    }
    return [];
  }

  Future<GaushalaModel> createGaushala(String gaushalaName) async {
    final response = await _dio.post(
      '/gaushalas',
      data: {
        'gaushalaName': gaushalaName.trim(),
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return GaushalaModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to create gaushala.',
    );
  }

  // -------------------------------------------------------------
  // SHEDS MASTER
  // -------------------------------------------------------------
  Future<List<ShedModel>> getSheds({String? gaushalaId}) async {
    final Map<String, dynamic> queryParameters = {};
    if (gaushalaId != null && gaushalaId.trim().isNotEmpty && gaushalaId != 'all') {
      queryParameters['gaushalaId'] = gaushalaId.trim();
    }

    final response = await _dio.get(
      '/sheds',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
    if (response.statusCode == 200 && response.data != null) {
      if (response.data is List) {
        final List list = response.data as List;
        return list
            .map((item) => ShedModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is List) {
        final List list = responseData['data'] as List;
        return list
            .map((item) => ShedModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } else if (responseData['data'] is Map && (responseData['data'] as Map)['sheds'] is List) {
        final List list = (responseData['data'] as Map)['sheds'] as List;
        return list
            .map((item) => ShedModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } else if (responseData['sheds'] is List) {
        final List list = responseData['sheds'] as List;
        return list
            .map((item) => ShedModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    }
    return [];
  }

  Future<ShedModel> createShed({
    required String shedName,
    required String shedNumber,
    String? gaushalaId,
  }) async {
    final Map<String, dynamic> data = {
      'shedName': shedName.trim(),
      'shedNumber': shedNumber.trim().toUpperCase(),
    };
    if (gaushalaId != null && gaushalaId.trim().isNotEmpty) {
      data['gaushalaId'] = gaushalaId.trim();
      data['gaushala_id'] = gaushalaId.trim();
      data['gaushala'] = gaushalaId.trim();
    }

    final response = await _dio.post(
      '/sheds',
      data: data,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return ShedModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to create shed.',
    );
  }

  Future<ShedModel> updateShed(
    String id, {
    required String shedName,
    required String shedNumber,
    String? gaushalaId,
  }) async {
    final Map<String, dynamic> data = {
      'shedName': shedName.trim(),
      'shedNumber': shedNumber.trim().toUpperCase(),
    };
    if (gaushalaId != null && gaushalaId.trim().isNotEmpty) {
      data['gaushalaId'] = gaushalaId.trim();
      data['gaushala_id'] = gaushalaId.trim();
      data['gaushala'] = gaushalaId.trim();
    }

    Response response;
    try {
      response = await _dio.post(
        '/sheds/$id/update',
        data: data,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        try {
          response = await _dio.post(
            '/sheds/$id',
            data: data,
          );
        } catch (_) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return ShedModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        } else if (responseData['_id'] != null || responseData['shedName'] != null) {
          return ShedModel.fromJson(responseData);
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to update shed.',
    );
  }

  Future<bool> deleteShed(String id) async {
    final response = await _dio.delete('/sheds/$id');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // -------------------------------------------------------------
  // BREED TYPES MASTER
  // -------------------------------------------------------------
  Future<List<BreedModel>> getBreedTypes() async {
    final response = await _dio.get('/breed-types');
    if (response.statusCode == 200 && response.data != null) {
      if (response.data is List) {
        final List list = response.data as List;
        return list
            .map((item) => BreedModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is List) {
        final List list = responseData['data'] as List;
        return list
            .map((item) => BreedModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    }
    return [];
  }

  Future<BreedModel> createBreedType(String breedName) async {
    final response = await _dio.post(
      '/breed-types',
      data: {
        'breedName': breedName.trim(),
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return BreedModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to create breed.',
    );
  }

  Future<BreedModel> updateBreedType(String id, String breedName) async {
    Response response;
    try {
      response = await _dio.post(
        '/breed-types/$id/update',
        data: {
          'breedName': breedName.trim(),
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        try {
          response = await _dio.post(
            '/breed-types/$id',
            data: {
              'breedName': breedName.trim(),
            },
          );
        } catch (_) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return BreedModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        } else if (responseData['_id'] != null || responseData['breedName'] != null) {
          return BreedModel.fromJson(responseData);
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to update breed.',
    );
  }

  Future<bool> deleteBreedType(String id) async {
    final response = await _dio.delete('/breed-types/$id');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // -------------------------------------------------------------
  // TYPES MASTER
  // -------------------------------------------------------------
  Future<List<TypeModel>> getTypes({String? gaushalaId}) async {
    final cleanGaushalaId = gaushalaId?.trim();
    if (cleanGaushalaId == null || cleanGaushalaId.isEmpty || cleanGaushalaId == 'all') {
      return <TypeModel>[];
    }

    final response = await _dio.get(
      '/types',
      queryParameters: {'gaushalaId': cleanGaushalaId},
    );
    if (response.statusCode == 200 && response.data != null) {
      if (response.data is List) {
        final List list = response.data as List;
        return list
            .map((item) => TypeModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is List) {
        final List list = responseData['data'] as List;
        return list
            .map((item) => TypeModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } else if (responseData['types'] is List) {
        final List list = responseData['types'] as List;
        return list
            .map((item) => TypeModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    }
    return [];
  }

  Future<TypeModel> createType(String typeName, {String? gaushalaId}) async {
    final Map<String, dynamic> data = {
      'typeName': typeName.trim(),
    };
    if (gaushalaId != null && gaushalaId.trim().isNotEmpty) {
      data['gaushalaId'] = gaushalaId.trim();
      data['gaushala_id'] = gaushalaId.trim();
    }

    final response = await _dio.post(
      '/types',
      data: data,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return TypeModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        } else if (responseData['_id'] != null || responseData['typeName'] != null) {
          return TypeModel.fromJson(responseData);
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to create type.',
    );
  }

  Future<TypeModel> updateType(String id, String typeName, {String? gaushalaId}) async {
    final Map<String, dynamic> data = {
      'typeName': typeName.trim(),
    };
    if (gaushalaId != null && gaushalaId.trim().isNotEmpty) {
      data['gaushalaId'] = gaushalaId.trim();
      data['gaushala_id'] = gaushalaId.trim();
    }

    Response response;
    try {
      response = await _dio.post(
        '/types/$id/update',
        data: data,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        try {
          response = await _dio.post(
            '/types/$id',
            data: data,
          );
        } catch (_) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return TypeModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        } else if (responseData['_id'] != null || responseData['typeName'] != null) {
          return TypeModel.fromJson(responseData);
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to update type.',
    );
  }

  Future<bool> deleteType(String id) async {
    final response = await _dio.delete('/types/$id');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // -------------------------------------------------------------
  // FEED STOCK ITEMS MASTER
  // -------------------------------------------------------------
  Future<List<FeedItemModel>> getFeedItems({
    String? gaushalaId,
    String? category,
    String? search,
    bool? isActive,
  }) async {
    final Map<String, dynamic> queryParams = {};
    final cleanGaushalaId = gaushalaId?.trim();
    if (cleanGaushalaId != null && cleanGaushalaId.isNotEmpty && cleanGaushalaId != 'all') {
      queryParams['gaushalaId'] = cleanGaushalaId;
    }
    if (category != null && category.trim().isNotEmpty && category != 'ALL') {
      queryParams['category'] = category.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (isActive != null) {
      queryParams['isActive'] = isActive;
    }

    final response = await _dio.get(
      '/feed-stock/items',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.statusCode == 200 && response.data != null) {
      final responseData = response.data;
      if (responseData is Map && responseData['data'] is List) {
        final List list = responseData['data'] as List;
        return list
            .map((item) => FeedItemModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } else if (responseData is List) {
        return responseData
            .map((item) => FeedItemModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    }
    return <FeedItemModel>[];
  }

  Future<FeedItemModel> createFeedItem({
    required String gaushalaId,
    required String itemName,
    String? itemCode,
    required String category,
    required String unit,
    double initialStock = 0.0,
    double minStockAlert = 50.0,
    double unitPrice = 0.0,
    String? description,
    bool isActive = true,
  }) async {
    final Map<String, dynamic> data = {
      'gaushalaId': gaushalaId.trim(),
      'itemName': itemName.trim(),
      if (itemCode != null && itemCode.trim().isNotEmpty) 'itemCode': itemCode.trim(),
      'category': category.trim(),
      'unit': unit.trim(),
      'initialStock': initialStock,
      'minStockAlert': minStockAlert,
      'unitPrice': unitPrice,
      if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
      'isActive': isActive,
    };

    final response = await _dio.post(
      '/feed-stock/items',
      data: data,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final responseData = response.data;
        if (responseData is Map && responseData['data'] != null) {
          return FeedItemModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to create feed item.',
    );
  }

  Future<FeedItemModel> updateFeedItem(
    String id, {
    String? itemName,
    String? itemCode,
    String? category,
    String? unit,
    double? minStockAlert,
    double? unitPrice,
    String? description,
    bool? isActive,
    String? gaushalaId,
  }) async {
    final Map<String, dynamic> data = {};
    if (itemName != null && itemName.trim().isNotEmpty) data['itemName'] = itemName.trim();
    if (itemCode != null) data['itemCode'] = itemCode.trim();
    if (category != null && category.trim().isNotEmpty) data['category'] = category.trim();
    if (unit != null && unit.trim().isNotEmpty) data['unit'] = unit.trim();
    if (minStockAlert != null) data['minStockAlert'] = minStockAlert;
    if (unitPrice != null) data['unitPrice'] = unitPrice;
    if (description != null) data['description'] = description.trim();
    if (isActive != null) data['isActive'] = isActive;
    if (gaushalaId != null && gaushalaId.trim().isNotEmpty) data['gaushalaId'] = gaushalaId.trim();

    Response response;
    try {
      response = await _dio.post(
        '/feed-stock/items/$id/update',
        data: data,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        response = await _dio.post(
          '/feed-stock/items/$id',
          data: data,
        );
      } else {
        rethrow;
      }
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final responseData = response.data;
        if (responseData is Map && responseData['data'] != null) {
          return FeedItemModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        } else if (responseData is Map) {
          return FeedItemModel.fromJson(Map<String, dynamic>.from(responseData));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to update feed item.',
    );
  }

  Future<bool> deleteFeedItem(String id) async {
    final response = await _dio.delete('/feed-stock/items/$id');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // -------------------------------------------------------------
  // FEED STOCK TRANSACTIONS (INWARD & OUTWARD)
  // -------------------------------------------------------------
  Future<FeedStockTransactionPaginatedResult> getFeedStockTransactions({
    String? gaushalaId,
    String? itemId,
    String? type,
    String? shedId,
    String? reason,
    int page = 1,
    int limit = 5,
    String? search,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'limit': limit,
    };
    final cleanGaushalaId = gaushalaId?.trim();
    if (cleanGaushalaId != null && cleanGaushalaId.isNotEmpty && cleanGaushalaId != 'all') {
      queryParams['gaushalaId'] = cleanGaushalaId;
    }
    if (itemId != null && itemId.trim().isNotEmpty && itemId != 'all') {
      queryParams['itemId'] = itemId.trim();
    }
    if (type != null && type.trim().isNotEmpty && type != 'ALL') {
      queryParams['type'] = type.trim();
    }
    if (shedId != null && shedId.trim().isNotEmpty && shedId != 'all') {
      queryParams['shedId'] = shedId.trim();
    }
    if (reason != null && reason.trim().isNotEmpty && reason != 'ALL') {
      queryParams['reason'] = reason.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _dio.get(
      '/feed-stock/transactions',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data != null) {
      final responseData = response.data;
      List<FeedStockTransactionModel> items = [];
      int total = 0;
      int curPage = page;
      int pageLimit = limit;
      int totalPages = 1;

      if (responseData is Map) {
        if (responseData['data'] is List) {
          final List list = responseData['data'] as List;
          items = list
              .map((item) => FeedStockTransactionModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        }
        if (responseData['pagination'] is Map) {
          final p = responseData['pagination'] as Map;
          total = (p['total'] as num?)?.toInt() ?? items.length;
          curPage = (p['page'] as num?)?.toInt() ?? page;
          pageLimit = (p['limit'] as num?)?.toInt() ?? limit;
          totalPages = (p['totalPages'] as num?)?.toInt() ?? 1;
        } else {
          total = items.length;
        }
      } else if (responseData is List) {
        items = responseData
            .map((item) => FeedStockTransactionModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        total = items.length;
      }

      return FeedStockTransactionPaginatedResult(
        items: items,
        total: total,
        page: curPage,
        limit: pageLimit,
        totalPages: totalPages,
      );
    }

    return FeedStockTransactionPaginatedResult(
      items: <FeedStockTransactionModel>[],
      total: 0,
      page: page,
      limit: limit,
      totalPages: 1,
    );
  }

  Future<FeedStockTransactionModel?> getFeedStockTransactionById(String id) async {
    final response = await _dio.get('/feed-stock/transactions/$id');
    if (response.statusCode == 200 && response.data != null) {
      final responseData = response.data;
      if (responseData is Map && responseData['data'] != null) {
        return FeedStockTransactionModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
      }
    }
    return null;
  }

  Future<FeedStockTransactionModel> recordInwardStock(FeedStockInwardRequest request) async {
    final response = await _dio.post(
      '/feed-stock/transactions/inward',
      data: request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final responseData = response.data;
        if (responseData is Map && responseData['data'] != null) {
          final dataMap = responseData['data'];
          if (dataMap is Map && dataMap['transaction'] != null) {
            return FeedStockTransactionModel.fromJson(Map<String, dynamic>.from(dataMap['transaction'] as Map));
          } else if (dataMap is Map) {
            return FeedStockTransactionModel.fromJson(Map<String, dynamic>.from(dataMap));
          }
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to record inward stock transaction.',
    );
  }

  Future<FeedStockTransactionModel> recordOutwardStock(FeedStockOutwardRequest request) async {
    final response = await _dio.post(
      '/feed-stock/transactions/outward',
      data: request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final responseData = response.data;
        if (responseData is Map && responseData['data'] != null) {
          final dataMap = responseData['data'];
          if (dataMap is Map && dataMap['transaction'] != null) {
            return FeedStockTransactionModel.fromJson(Map<String, dynamic>.from(dataMap['transaction'] as Map));
          } else if (dataMap is Map) {
            return FeedStockTransactionModel.fromJson(Map<String, dynamic>.from(dataMap));
          }
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to record outward stock transaction.',
    );
  }

  // -------------------------------------------------------------
  // COWS
  // -------------------------------------------------------------
  Future<CowModel> addCow(AddCowRequestModel request) async {
    final response = await _dio.post(
      '/cows',
      data: request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return CowModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to add cow.',
    );
  }

  /// Fetches cows for a specific gaushala with optional gender filtering.
  /// GET /cows?gaushalaId=:id&gender=:gender
  Future<CowListResponse> getCows({
    String? gaushalaId,
    String? gender,
  }) async {
    final cleanGaushalaId = gaushalaId?.trim();
    if (cleanGaushalaId == null || cleanGaushalaId.isEmpty) {
      return const CowListResponse();
    }

    final Map<String, dynamic> queryParameters = {
      'gaushalaId': cleanGaushalaId,
    };
    if (gender != null && gender.trim().isNotEmpty && gender.trim().toLowerCase() != 'all') {
      queryParameters['gender'] = gender.trim().toLowerCase();
    }

    final response = await _dio.get(
      '/cows',
      queryParameters: queryParameters,
    );

    if (response.statusCode == 200 && response.data != null) {
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is Map) {
        return CowListResponse.fromJson(
          Map<String, dynamic>.from(responseData['data'] as Map),
        );
      } else if (responseData['data'] is List) {
        final list = (responseData['data'] as List)
            .map((item) => CowModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        return CowListResponse(
          total: list.length,
          femaleCount: list.where((c) => c.isFemale).length,
          maleCount: list.where((c) => !c.isFemale).length,
          counts: CowCounts(
            total: list.length,
            female: list.where((c) => c.isFemale).length,
            male: list.where((c) => !c.isFemale).length,
            cow: list.where((c) => c.isFemale).length,
            bull: list.where((c) => !c.isFemale).length,
          ),
          female: list.where((c) => c.isFemale).toList(),
          male: list.where((c) => !c.isFemale).toList(),
          allCows: list,
        );
      }
    }

    return const CowListResponse();
  }

  /// Updates a cow by ID. POST /cows/:id/update (with fallback to POST /cows/:id)
  Future<CowModel> updateCow(String id, AddCowRequestModel request) async {
    Response response;
    try {
      response = await _dio.post(
        '/cows/$id/update',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        try {
          response = await _dio.post(
            '/cows/$id',
            data: request.toJson(),
          );
        } catch (_) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return CowModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        } else if (responseData['_id'] != null || responseData['id'] != null) {
          return CowModel.fromJson(responseData);
        } else {
          return CowModel.fromJson(responseData);
        }
      }
      return CowModel.fromJson({});
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to update cow.',
    );
  }

  /// Deletes a cow by ID. POST /cows/:id/delete
  Future<bool> deleteCow(String id) async {
    final response = await _dio.post('/cows/$id/delete');
    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      if (response.data is Map && (response.data as Map).containsKey('success')) {
        return response.data['success'] == true;
      }
      return true;
    }
    return false;
  }

  /// Updates cow active status. POST /cows/:id/status
  Future<bool> updateCowStatus(String id, bool isActive) async {
    final response = await _dio.post(
      '/cows/$id/status',
      data: {'isActive': isActive},
    );
    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      if (response.data is Map && (response.data as Map).containsKey('success')) {
        return response.data['success'] == true;
      }
      return true;
    }
    return false;
  }

  /// Marks a cow as died. POST /cows/:id/died
  Future<bool> markCowDied(String id, String sendDiedDate) async {
    final response = await _dio.post(
      '/cows/$id/died',
      data: {'send_died_date': sendDiedDate},
    );
    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      if (response.data is Map && (response.data as Map).containsKey('success')) {
        return response.data['success'] == true;
      }
      return true;
    }
    return false;
  }

  /// Downloads the Excel import template for cattle.
  /// GET /cows/import-template
  Future<List<int>> downloadImportTemplate({
    ProgressCallback? onReceiveProgress,
  }) async {
    final response = await _dio.get<List<int>>(
      '/cows/import-template',
      options: Options(
        responseType: ResponseType.bytes,
      ),
      onReceiveProgress: onReceiveProgress,
    );

    if (response.statusCode == 200 && response.data != null) {
      return response.data!;
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Failed to download cattle import template.',
    );
  }

  /// Uploads filled Excel spreadsheet to batch-import cows.
  /// POST /cows/upload-excel
  /// Returns a Map containing the response data (success, message, imported records count, etc.)
  Future<Map<String, dynamic>> uploadCowsExcel({
    required List<int> fileBytes,
    required String fileName,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
      ),
    });

    final response = await _dio.post(
      '/cows/upload-excel',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
      onSendProgress: onSendProgress,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return {'success': true, 'message': 'Cattle data imported successfully'};
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to upload cattle Excel sheet.',
    );
  }

  /// Transfers cattle to a specified shed.
  /// POST /cows/shed-transfer
  /// Data: { gaushalaId, cow_ids, to_shed_id, reason, transferDate }
  Future<Map<String, dynamic>> transferCowShed(ShedTransferRequestModel request) async {
    final response = await _dio.post(
      '/cows/shed-transfer',
      data: request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return {'success': true, 'message': 'Cattle transferred to shed successfully.'};
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to transfer cattle shed.',
    );
  }

  /// Fetches Cattle Shed Transfer History.
  /// GET /cows/shed-transfer-history
  /// Query Params:
  /// - [gaushalaId]: To fetch all transfer records for a gaushala.
  /// - [cowId]: To fetch transfer records for a specific cattle.
  /// - [page], [limit]: Pagination parameters.
  Future<ShedTransferHistoryResponse> getShedTransferHistory({
    String? gaushalaId,
    String? cowId,
    int? page,
    int? limit,
  }) async {
    final Map<String, dynamic> queryParameters = {};
    if (gaushalaId != null && gaushalaId.trim().isNotEmpty && gaushalaId != 'all') {
      queryParameters['gaushalaId'] = gaushalaId.trim();
    }
    if (cowId != null && cowId.trim().isNotEmpty) {
      queryParameters['cowId'] = cowId.trim();
    }
    if (page != null && page > 0) {
      queryParameters['page'] = page;
    }
    if (limit != null && limit > 0) {
      queryParameters['limit'] = limit;
    }

    final response = await _dio.get(
      '/cows/shed-transfer-history',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );

    if (response.statusCode == 200 && response.data != null) {
      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);
      return ShedTransferHistoryResponse.fromJson(responseData);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to fetch shed transfer history.',
    );
  }



  // -------------------------------------------------------------
  // USERS MANAGEMENT
  // -------------------------------------------------------------
  /// Fetches all users from GET /users with optional gaushalaId and roleId filters.
  Future<List<UserModel>> getUsers({String? gaushalaId, String? roleId}) async {
    final Map<String, dynamic> queryParameters = {};
    if (gaushalaId != null && gaushalaId.trim().isNotEmpty && gaushalaId != 'all') {
      queryParameters['gaushalaId'] = gaushalaId.trim();
    }
    if (roleId != null && roleId.trim().isNotEmpty && roleId != 'all') {
      queryParameters['roleId'] = roleId.trim();
    }

    final response = await _dio.get(
      '/users',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );

    if (response.statusCode == 200 && response.data != null) {
      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is List) {
        final List list = responseData['data'] as List;
        return list
            .map((item) => UserModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    }
    return [];
  }

  /// Fetches a single user by ID. GET /users/:id
  Future<UserModel> getUserById(String id) async {
    final response = await _dio.get('/users/$id');
    if (response.statusCode == 200 && response.data != null) {
      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is Map) {
        return UserModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to fetch user.',
    );
  }

  /// Creates a new user. POST /users
  Future<UserModel> createUser({
    required String name,
    required String gaushalaId,
    required String roleId,
    required String emailId,
    required String username,
    required String password,
    bool isActive = true,
    String? fcmToken,
  }) async {
    final Map<String, dynamic> data = {
      'name': name.trim(),
      'gaushalaId': gaushalaId.trim(),
      'roleId': roleId.trim(),
      'emailId': emailId.trim(),
      'username': username.trim(),
      'password': password,
      'isActive': isActive,
      'fcmToken': fcmToken,
    };

    final response = await _dio.post(
      '/users',
      data: data,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return UserModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to create user.',
    );
  }

  /// Updates an existing user. POST /users/:id/update
  Future<UserModel> updateUser(
    String id, {
    String? name,
    String? gaushalaId,
    String? roleId,
    String? emailId,
    String? username,
    String? password,
    bool? isActive,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null && name.trim().isNotEmpty) data['name'] = name.trim();
    if (gaushalaId != null && gaushalaId.trim().isNotEmpty) data['gaushalaId'] = gaushalaId.trim();
    if (roleId != null && roleId.trim().isNotEmpty) data['roleId'] = roleId.trim();
    if (emailId != null && emailId.trim().isNotEmpty) data['emailId'] = emailId.trim();
    if (username != null && username.trim().isNotEmpty) data['username'] = username.trim();
    if (password != null && password.trim().isNotEmpty) data['password'] = password.trim();
    if (isActive != null) data['isActive'] = isActive;

    final response = await _dio.post(
      '/users/$id/update',
      data: data,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return UserModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to update user.',
    );
  }

  /// Deletes a user by ID. POST /users/:id/delete
  Future<bool> deleteUser(String id) async {
    final response = await _dio.post('/users/$id/delete');
    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      if (response.data is Map && (response.data as Map).containsKey('success')) {
        return response.data['success'] == true;
      }
      return true;
    }
    return false;
  }

  /// Updates user active status. POST /users/:id/status
  Future<bool> updateUserStatus(String id, bool isActive) async {
    final response = await _dio.post(
      '/users/$id/status',
      data: {'isActive': isActive},
    );
    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      if (response.data is Map && (response.data as Map).containsKey('success')) {
        return response.data['success'] == true;
      }
      return true;
    }
    return false;
  }

  /// Changes user password. POST /auth/change-password
  Future<bool> changePassword({
    required String userId,
    String? oldPassword,
    required String newPassword,
  }) async {
    final Map<String, dynamic> data = {
      'userId': userId,
      'newPassword': newPassword.trim(),
    };
    if (oldPassword != null && oldPassword.trim().isNotEmpty) {
      data['oldPassword'] = oldPassword.trim();
    }

    try {
      final response = await _dio.post(
        '/auth/change-password',
        data: data,
      );
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        if (response.data is Map && (response.data as Map).containsKey('success')) {
          return response.data['success'] == true;
        }
        return true;
      }
      return false;
    } on DioException {
      // If /auth/change-password requires oldPassword, fallback to /users/:id/update for admin
      if (oldPassword == null || oldPassword.trim().isEmpty) {
        try {
          final fallbackResponse = await _dio.post(
            '/users/$userId/update',
            data: {'password': newPassword.trim()},
          );
          if (fallbackResponse.statusCode == 200 || fallbackResponse.statusCode == 201) {
            return true;
          }
        } catch (_) {}
      }
      rethrow;
    }
  }

  // -------------------------------------------------------------
  // VETERINARY / MEDICAL STOCK MANAGEMENT (FEFO TRACKING)
  // -------------------------------------------------------------

  /// Retrieves dashboard summary metrics for Medical Stock
  /// GET /medical-stock/summary?gaushalaId={id}
  Future<MedicalSummaryModel> getMedicalStockSummary({String? gaushalaId}) async {
    final Map<String, dynamic> queryParams = {};
    final cleanGId = gaushalaId?.trim();
    if (cleanGId != null && cleanGId.isNotEmpty && cleanGId != 'all') {
      queryParams['gaushalaId'] = cleanGId;
    }

    try {
      final response = await _dio.get(
        '/medical-stock/summary',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data;
        if (resData is Map) {
          if (resData['data'] is Map) {
            return MedicalSummaryModel.fromJson(Map<String, dynamic>.from(resData['data'] as Map));
          }
          return MedicalSummaryModel.fromJson(Map<String, dynamic>.from(resData));
        }
      }
    } catch (e) {
      if (kDebugMode) print('[ApiService] getMedicalStockSummary error: $e');
      rethrow;
    }

    return const MedicalSummaryModel();
  }

  /// Retrieves low-stock medical items (totalStock <= minStockAlert)
  /// GET /medical-stock/items/low-stock?gaushalaId={id}
  Future<List<MedicalItemModel>> getLowStockMedicalItems({String? gaushalaId}) async {
    final Map<String, dynamic> queryParams = {};
    final cleanGId = gaushalaId?.trim();
    if (cleanGId != null && cleanGId.isNotEmpty && cleanGId != 'all') {
      queryParams['gaushalaId'] = cleanGId;
    }

    final response = await _dio.get(
      '/medical-stock/items/low-stock',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.statusCode == 200 && response.data != null) {
      final resData = response.data;
      if (resData is Map && resData['data'] is List) {
        return (resData['data'] as List)
            .whereType<Map>()
            .map((i) => MedicalItemModel.fromJson(Map<String, dynamic>.from(i)))
            .toList();
      } else if (resData is List) {
        return resData
            .whereType<Map>()
            .map((i) => MedicalItemModel.fromJson(Map<String, dynamic>.from(i)))
            .toList();
      }
    }
    return <MedicalItemModel>[];
  }

  /// Retrieves batches expiring within specified days (default 30 days)
  /// GET /medical-stock/batches/expiring?gaushalaId={id}&days=30
  Future<List<MedicalBatchModel>> getExpiringMedicalBatches({
    String? gaushalaId,
    int days = 30,
  }) async {
    final Map<String, dynamic> queryParams = {'days': days};
    final cleanGId = gaushalaId?.trim();
    if (cleanGId != null && cleanGId.isNotEmpty && cleanGId != 'all') {
      queryParams['gaushalaId'] = cleanGId;
    }

    final response = await _dio.get(
      '/medical-stock/batches/expiring',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data != null) {
      final resData = response.data;
      if (resData is Map && resData['data'] is List) {
        return (resData['data'] as List)
            .whereType<Map>()
            .map((b) => MedicalBatchModel.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      } else if (resData is List) {
        return resData
            .whereType<Map>()
            .map((b) => MedicalBatchModel.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      }
    }
    return <MedicalBatchModel>[];
  }

  /// Retrieves paginated list of medical items with filters
  /// GET /medical-stock/items
  Future<MedicalItemPaginatedResult> getMedicalItems({
    String? gaushalaId,
    String? search,
    String? category,
    String? unit,
    bool? lowStockOnly,
    int page = 1,
    int limit = 5,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'limit': limit,
    };
    final cleanGId = gaushalaId?.trim();
    if (cleanGId != null && cleanGId.isNotEmpty && cleanGId != 'all') {
      queryParams['gaushalaId'] = cleanGId;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (category != null && category.trim().isNotEmpty && category != 'ALL') {
      queryParams['category'] = category.trim();
    }
    if (unit != null && unit.trim().isNotEmpty && unit != 'ALL') {
      queryParams['unit'] = unit.trim();
    }
    if (lowStockOnly == true) {
      queryParams['lowStockOnly'] = true;
    }

    final response = await _dio.get(
      '/medical-stock/items',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data != null) {
      final resData = response.data;
      List<MedicalItemModel> items = [];
      int total = 0;
      int resPage = page;
      int resLimit = limit;
      int totalPages = 1;

      if (resData is Map) {
        final dataSection = resData['data'];
        if (dataSection is Map) {
          if (dataSection['items'] is List) {
            items = (dataSection['items'] as List)
                .whereType<Map>()
                .map((i) => MedicalItemModel.fromJson(Map<String, dynamic>.from(i)))
                .toList();
          }
          total = dataSection['total'] ?? items.length;
          resPage = dataSection['page'] ?? page;
          resLimit = dataSection['limit'] ?? limit;
          totalPages = dataSection['totalPages'] ?? ((total / resLimit).ceil());
        } else if (dataSection is List) {
          items = dataSection
              .whereType<Map>()
              .map((i) => MedicalItemModel.fromJson(Map<String, dynamic>.from(i)))
              .toList();
          total = resData['total'] ?? items.length;
          totalPages = (total / limit).ceil();
        }
      } else if (resData is List) {
        items = resData
            .whereType<Map>()
            .map((i) => MedicalItemModel.fromJson(Map<String, dynamic>.from(i)))
            .toList();
        total = items.length;
        totalPages = 1;
      }

      return MedicalItemPaginatedResult(
        items: items,
        total: total,
        page: resPage,
        limit: resLimit,
        totalPages: totalPages > 0 ? totalPages : 1,
      );
    }

    return MedicalItemPaginatedResult(
      items: <MedicalItemModel>[],
      total: 0,
      page: page,
      limit: limit,
      totalPages: 1,
    );
  }

  /// Retrieves single medical item details with its active batches
  /// GET /medical-stock/items/:id
  Future<MedicalItemModel?> getMedicalItemById(String id) async {
    final response = await _dio.get('/medical-stock/items/$id');
    if (response.statusCode == 200 && response.data != null) {
      final resData = response.data;
      if (resData is Map && resData['data'] is Map) {
        return MedicalItemModel.fromJson(Map<String, dynamic>.from(resData['data'] as Map));
      } else if (resData is Map) {
        return MedicalItemModel.fromJson(Map<String, dynamic>.from(resData));
      }
    }
    return null;
  }

  /// Creates a new Medical Item SKU
  /// POST /medical-stock/items
  Future<MedicalItemModel> createMedicalItem({
    required String gaushalaId,
    required String itemName,
    String? itemCode,
    required String category,
    required String unit,
    double minStockAlert = 20.0,
    String? manufacturer,
    String? description,
    List<MedicalInwardBatchDto>? initialBatches,
  }) async {
    final Map<String, dynamic> data = {
      'gaushalaId': gaushalaId.trim(),
      'itemName': itemName.trim(),
      if (itemCode != null && itemCode.trim().isNotEmpty) 'itemCode': itemCode.trim(),
      'category': category.trim(),
      'unit': unit.trim(),
      'minStockAlert': minStockAlert,
      if (manufacturer != null && manufacturer.trim().isNotEmpty) 'manufacturer': manufacturer.trim(),
      if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
      if (initialBatches != null && initialBatches.isNotEmpty)
        'initialBatches': initialBatches.map((b) => b.toJson()).toList(),
    };

    final response = await _dio.post(
      '/medical-stock/items',
      data: data,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final resData = response.data;
        if (resData is Map && resData['data'] is Map) {
          return MedicalItemModel.fromJson(Map<String, dynamic>.from(resData['data'] as Map));
        } else if (resData is Map) {
          return MedicalItemModel.fromJson(Map<String, dynamic>.from(resData));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to create medical item.',
    );
  }

  /// Updates an existing Medical Item SKU
  /// POST /medical-stock/items/:id/update (with fallback to POST /medical-stock/items/:id)
  Future<MedicalItemModel> updateMedicalItem(String id, Map<String, dynamic> data) async {
    Response response;
    try {
      response = await _dio.post(
        '/medical-stock/items/$id/update',
        data: data,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        response = await _dio.post(
          '/medical-stock/items/$id',
          data: data,
        );
      } else {
        rethrow;
      }
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final resData = response.data;
        if (resData is Map && resData['data'] is Map) {
          return MedicalItemModel.fromJson(Map<String, dynamic>.from(resData['data'] as Map));
        } else if (resData is Map) {
          return MedicalItemModel.fromJson(Map<String, dynamic>.from(resData));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to update medical item.',
    );
  }

  /// Deletes a Medical Item SKU (Soft delete)
  /// DELETE /medical-stock/items/:id or POST /medical-stock/items/:id/delete
  Future<bool> deleteMedicalItem(String id) async {
    try {
      final response = await _dio.delete('/medical-stock/items/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        final response = await _dio.post('/medical-stock/items/$id/delete');
        return response.statusCode == 200 || response.statusCode == 204;
      }
      rethrow;
    }
    return false;
  }

  /// Records Stock Inward with single or dynamic multi-batch array
  /// POST /medical-stock/transactions/inward
  Future<MedicalTransactionModel> recordMedicalStockInward(MedicalStockInwardRequest request) async {
    final response = await _dio.post(
      '/medical-stock/transactions/inward',
      data: request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final resData = response.data;
        if (resData is Map && resData['data'] != null) {
          final dataMap = resData['data'];
          if (dataMap is Map && dataMap['transaction'] != null) {
            return MedicalTransactionModel.fromJson(Map<String, dynamic>.from(dataMap['transaction'] as Map));
          } else if (dataMap is Map) {
            return MedicalTransactionModel.fromJson(Map<String, dynamic>.from(dataMap));
          }
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to record medical stock inward.',
    );
  }

  /// Records Stock Outward with automatic backend FEFO deduction
  /// POST /medical-stock/transactions/outward
  Future<MedicalStockOutwardResponse> recordMedicalStockOutward(MedicalStockOutwardRequest request) async {
    final response = await _dio.post(
      '/medical-stock/transactions/outward',
      data: request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final resData = response.data;
        if (resData is Map && resData['data'] is Map) {
          return MedicalStockOutwardResponse.fromJson(Map<String, dynamic>.from(resData['data'] as Map));
        } else if (resData is Map) {
          return MedicalStockOutwardResponse.fromJson(Map<String, dynamic>.from(resData));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to record medical stock outward.',
    );
  }

  /// Records Stock Adjustment or Expired Stock Disposal
  /// POST /medical-stock/transactions/adjustment
  Future<MedicalTransactionModel> recordMedicalStockAdjustment(MedicalStockAdjustmentRequest request) async {
    final response = await _dio.post(
      '/medical-stock/transactions/adjustment',
      data: request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final resData = response.data;
        if (resData is Map && resData['data'] != null) {
          final dataMap = resData['data'];
          if (dataMap is Map && dataMap['transaction'] != null) {
            return MedicalTransactionModel.fromJson(Map<String, dynamic>.from(dataMap['transaction'] as Map));
          } else if (dataMap is Map) {
            return MedicalTransactionModel.fromJson(Map<String, dynamic>.from(dataMap));
          }
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to record stock adjustment.',
    );
  }

  /// Retrieves transaction ledger history with batch breakdown
  /// GET /medical-stock/transactions
  Future<MedicalTransactionPaginatedResult> getMedicalTransactions({
    String? gaushalaId,
    String? itemId,
    String? type,
    String? reason,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 5,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'limit': limit,
    };
    final cleanGId = gaushalaId?.trim();
    if (cleanGId != null && cleanGId.isNotEmpty && cleanGId != 'all') {
      queryParams['gaushalaId'] = cleanGId;
    }
    if (itemId != null && itemId.trim().isNotEmpty && itemId != 'all') {
      queryParams['itemId'] = itemId.trim();
    }
    if (type != null && type.trim().isNotEmpty && type != 'ALL') {
      queryParams['type'] = type.trim();
    }
    if (reason != null && reason.trim().isNotEmpty && reason != 'ALL') {
      queryParams['reason'] = reason.trim();
    }
    if (startDate != null) {
      queryParams['startDate'] = "${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
    }
    if (endDate != null) {
      queryParams['endDate'] = "${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
    }

    final response = await _dio.get(
      '/medical-stock/transactions',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data != null) {
      final resData = response.data;
      List<MedicalTransactionModel> items = [];
      int total = 0;
      int resPage = page;
      int resLimit = limit;
      int totalPages = 1;

      if (resData is Map) {
        final dataSection = resData['data'];
        if (dataSection is Map) {
          if (dataSection['items'] is List) {
            items = (dataSection['items'] as List)
                .whereType<Map>()
                .map((t) => MedicalTransactionModel.fromJson(Map<String, dynamic>.from(t)))
                .toList();
          } else if (dataSection['transactions'] is List) {
            items = (dataSection['transactions'] as List)
                .whereType<Map>()
                .map((t) => MedicalTransactionModel.fromJson(Map<String, dynamic>.from(t)))
                .toList();
          }
          total = dataSection['total'] ?? items.length;
          resPage = dataSection['page'] ?? page;
          resLimit = dataSection['limit'] ?? limit;
          totalPages = dataSection['totalPages'] ?? ((total / resLimit).ceil());
        } else if (dataSection is List) {
          items = dataSection
              .whereType<Map>()
              .map((t) => MedicalTransactionModel.fromJson(Map<String, dynamic>.from(t)))
              .toList();
          total = resData['total'] ?? items.length;
          totalPages = (total / limit).ceil();
        }
      } else if (resData is List) {
        items = resData
            .whereType<Map>()
            .map((t) => MedicalTransactionModel.fromJson(Map<String, dynamic>.from(t)))
            .toList();
        total = items.length;
        totalPages = 1;
      }

      return MedicalTransactionPaginatedResult(
        items: items,
        total: total,
        page: resPage,
        limit: resLimit,
        totalPages: totalPages > 0 ? totalPages : 1,
      );
    }

    return MedicalTransactionPaginatedResult(
      items: <MedicalTransactionModel>[],
      total: 0,
      page: page,
      limit: limit,
      totalPages: 1,
    );
  }

  /// Retrieves list of batches with filters
  /// GET /medical-stock/batches?gaushalaId={id}&itemId=&status=ACTIVE&search=
  Future<List<MedicalBatchModel>> getMedicalBatches({
    String? gaushalaId,
    String? itemId,
    String? status = 'ACTIVE',
    String? search,
  }) async {
    final Map<String, dynamic> queryParams = {};
    final cleanGId = gaushalaId?.trim();
    if (cleanGId != null && cleanGId.isNotEmpty && cleanGId != 'all') {
      queryParams['gaushalaId'] = cleanGId;
    }
    if (itemId != null && itemId.trim().isNotEmpty && itemId != 'all') {
      queryParams['itemId'] = itemId.trim();
    }
    if (status != null && status.trim().isNotEmpty && status != 'ALL') {
      queryParams['status'] = status.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _dio.get(
      '/medical-stock/batches',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.statusCode == 200 && response.data != null) {
      final resData = response.data;
      if (resData is Map && resData['data'] is List) {
        return (resData['data'] as List)
            .whereType<Map>()
            .map((b) => MedicalBatchModel.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      } else if (resData is List) {
        return resData
            .whereType<Map>()
            .map((b) => MedicalBatchModel.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      }
    }

    return <MedicalBatchModel>[];
  }

  // -------------------------------------------------------------
  // COW TREATMENT & VETERINARY MANAGEMENT APIS
  // -------------------------------------------------------------

  /// Dashboard Metrics: GET /treatments/dashboard/summary?gaushalaId={gaushalaId}
  Future<TreatmentSummaryModel> getTreatmentSummary({required String gaushalaId}) async {
    final cleanGId = gaushalaId.trim();
    if (cleanGId.isEmpty) return const TreatmentSummaryModel();

    try {
      final response = await _dio.get(
        '/treatments/dashboard/summary',
        queryParameters: {'gaushalaId': cleanGId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data;
        if (resData is Map) {
          if (resData['data'] is Map) {
            return TreatmentSummaryModel.fromJson(Map<String, dynamic>.from(resData['data'] as Map));
          }
          return TreatmentSummaryModel.fromJson(Map<String, dynamic>.from(resData));
        }
      }
    } catch (e) {
      if (kDebugMode) print('[ApiService] getTreatmentSummary error: $e');
    }
    return const TreatmentSummaryModel();
  }

  /// Today Due Doses Alert List: GET /treatments/doses/today-due?gaushalaId={gaushalaId}
  Future<List<CowTreatmentModel>> getTodayDueDoses({required String gaushalaId}) async {
    final cleanGId = gaushalaId.trim();
    if (cleanGId.isEmpty) return [];

    try {
      final response = await _dio.get(
        '/treatments/doses/today-due',
        queryParameters: {'gaushalaId': cleanGId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data;
        dynamic listData;
        if (resData is Map) {
          listData = resData['data'] ?? resData['items'] ?? resData['treatments'];
        } else if (resData is List) {
          listData = resData;
        }

        if (listData is List) {
          return listData
              .whereType<Map>()
              .map((t) => CowTreatmentModel.fromJson(Map<String, dynamic>.from(t)))
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('[ApiService] getTodayDueDoses error: $e');
    }
    return [];
  }

  /// List Treatments with Filters & Pagination:
  /// GET /treatments?gaushalaId={gaushalaId}&cowId={cowId}&status={status}&severity={severity}&search={query}&page={page}&limit={limit}
  Future<TreatmentPaginatedResult> getTreatments({
    required String gaushalaId,
    String? cowId,
    String? status,
    String? severity,
    String? search,
    int page = 1,
    int limit = 5,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final cleanGId = gaushalaId.trim();
    final Map<String, dynamic> queryParams = {
      'page': page,
      'limit': limit,
    };
    if (cleanGId.isNotEmpty && cleanGId != 'all') {
      queryParams['gaushalaId'] = cleanGId;
    }
    if (cowId != null && cowId.trim().isNotEmpty && cowId != 'all') {
      queryParams['cowId'] = cowId.trim();
    }
    if (status != null && status.trim().isNotEmpty && status != 'ALL') {
      queryParams['status'] = status.trim();
    }
    if (severity != null && severity.trim().isNotEmpty && severity != 'ALL') {
      queryParams['severity'] = severity.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    try {
      final response = await _dio.get(
        '/treatments',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data;
        List<CowTreatmentModel> items = [];
        int total = 0;
        int resPage = page;
        int resLimit = limit;
        int totalPages = 1;

        if (resData is Map) {
          final dataSection = resData['data'];
          if (dataSection is List) {
            items = dataSection
                .whereType<Map>()
                .map((t) => CowTreatmentModel.fromJson(Map<String, dynamic>.from(t)))
                .toList();
          } else if (dataSection is Map) {
            final subList = dataSection['treatments'] ?? dataSection['items'] ?? dataSection['data'];
            if (subList is List) {
              items = subList
                  .whereType<Map>()
                  .map((t) => CowTreatmentModel.fromJson(Map<String, dynamic>.from(t)))
                  .toList();
            }
          }

          // Check pagination object
          if (resData['pagination'] is Map) {
            final p = resData['pagination'] as Map;
            total = int.tryParse(p['total']?.toString() ?? '') ?? items.length;
            resPage = int.tryParse(p['page']?.toString() ?? '') ?? page;
            resLimit = int.tryParse(p['limit']?.toString() ?? '') ?? limit;
            totalPages = int.tryParse(p['totalPages']?.toString() ?? '') ?? ((total / resLimit).ceil());
          } else {
            total = int.tryParse(resData['total']?.toString() ?? resData['count']?.toString() ?? '') ?? items.length;
            totalPages = total > 0 ? (total / resLimit).ceil() : 1;
          }
        } else if (resData is List) {
          items = resData
              .whereType<Map>()
              .map((t) => CowTreatmentModel.fromJson(Map<String, dynamic>.from(t)))
              .toList();
          total = items.length;
          totalPages = 1;
        }

        return TreatmentPaginatedResult(
          items: items,
          total: total,
          page: resPage,
          limit: resLimit,
          totalPages: totalPages > 0 ? totalPages : 1,
        );
      }
    } catch (e) {
      if (kDebugMode) print('[ApiService] getTreatments error: $e');
    }

    return TreatmentPaginatedResult(
      items: [],
      total: 0,
      page: page,
      limit: limit,
      totalPages: 1,
    );
  }

  /// Get Treatment by ID: GET /treatments/{id}
  Future<CowTreatmentModel?> getTreatmentById(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return null;

    try {
      final response = await _dio.get('/treatments/$cleanId');

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data;
        if (resData is Map) {
          final data = resData['data'] ?? resData['treatment'] ?? resData;
          if (data is Map) {
            return CowTreatmentModel.fromJson(Map<String, dynamic>.from(data));
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('[ApiService] getTreatmentById error: $e');
    }
    return null;
  }

  /// Create Treatment Case: POST /treatments
  Future<CowTreatmentModel?> createTreatment(Map<String, dynamic> data) async {
    final response = await _dio.post(
      '/treatments',
      data: data,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final resData = response.data;
      if (resData is Map) {
        final itemData = resData['data'] ?? resData['treatment'] ?? resData;
        if (itemData is Map) {
          return CowTreatmentModel.fromJson(Map<String, dynamic>.from(itemData));
        }
      }
    }
    return null;
  }

  /// Administer Scheduled Dose: POST /treatments/{id}/doses/{doseNumber}/administer
  Future<CowTreatmentModel?> administerDose({
    required String treatmentId,
    required int doseNumber,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dio.post(
      '/treatments/${treatmentId.trim()}/doses/$doseNumber/administer',
      data: data,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final resData = response.data;
      if (resData is Map) {
        final itemData = resData['data'] ?? resData['treatment'] ?? resData;
        if (itemData is Map) {
          return CowTreatmentModel.fromJson(Map<String, dynamic>.from(itemData));
        }
      }
    }
    return null;
  }

  /// Update Treatment Details: POST /treatments/{id}/update
  Future<CowTreatmentModel?> updateTreatmentDetails({
    required String treatmentId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dio.post(
      '/treatments/${treatmentId.trim()}/update',
      data: data,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final resData = response.data;
      if (resData is Map) {
        final itemData = resData['data'] ?? resData['treatment'] ?? resData;
        if (itemData is Map) {
          return CowTreatmentModel.fromJson(Map<String, dynamic>.from(itemData));
        }
      }
    }
    return null;
  }

  /// Update Treatment Status: POST /treatments/{id}/status
  Future<bool> updateTreatmentStatus({
    required String treatmentId,
    required String status,
    String? recoveryNotes,
    bool markCowDied = false,
  }) async {
    final response = await _dio.post(
      '/treatments/${treatmentId.trim()}/status',
      data: {
        'status': status.trim().toUpperCase(),
        if (recoveryNotes != null && recoveryNotes.trim().isNotEmpty)
          'recoveryNotes': recoveryNotes.trim(),
        'markCowDied': markCowDied,
      },
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Delete Treatment: POST /treatments/{id}/delete
  Future<bool> deleteTreatment(String treatmentId) async {
    final response = await _dio.post('/treatments/${treatmentId.trim()}/delete');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // -------------------------------------------------------------
  // IN-APP NOTIFICATION & ALERT APIS
  // -------------------------------------------------------------

  /// Unread Count: GET /notifications/unread-count?gaushalaId={gaushalaId}
  Future<int> getNotificationUnreadCount({required String gaushalaId}) async {
    final cleanGId = gaushalaId.trim();
    if (cleanGId.isEmpty) return 0;

    try {
      final response = await _dio.get(
        '/notifications/unread-count',
        queryParameters: {'gaushalaId': cleanGId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data;
        if (resData is Map) {
          final data = resData['data'];
          if (data is Map) {
            return int.tryParse(data['unreadCount']?.toString() ?? data['count']?.toString() ?? '0') ?? 0;
          }
          return int.tryParse(resData['unreadCount']?.toString() ?? resData['count']?.toString() ?? '0') ?? 0;
        }
      }
    } catch (e) {
      if (kDebugMode) print('[ApiService] getNotificationUnreadCount error: $e');
    }
    return 0;
  }

  /// Get Notifications List: GET /notifications?gaushalaId={gaushalaId}&isRead={bool}&type={type}&page={page}&limit={limit}
  Future<NotificationPaginatedResult> getNotifications({
    required String gaushalaId,
    bool? isRead,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    final cleanGId = gaushalaId.trim();
    final Map<String, dynamic> queryParams = {
      'page': page,
      'limit': limit,
    };
    if (cleanGId.isNotEmpty && cleanGId != 'all') {
      queryParams['gaushalaId'] = cleanGId;
    }
    if (isRead != null) {
      queryParams['isRead'] = isRead;
    }
    if (type != null && type.trim().isNotEmpty) {
      queryParams['type'] = type.trim();
    }

    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data;
        List<NotificationModel> items = [];
        int total = 0;
        int unread = 0;
        int resPage = page;
        int resLimit = limit;
        int totalPages = 1;

        if (resData is Map) {
          final dataSection = resData['data'];
          if (dataSection is List) {
            items = dataSection
                .whereType<Map>()
                .map((n) => NotificationModel.fromJson(Map<String, dynamic>.from(n)))
                .toList();
          } else if (dataSection is Map) {
            final subList = dataSection['notifications'] ?? dataSection['items'] ?? dataSection['data'];
            if (subList is List) {
              items = subList
                  .whereType<Map>()
                  .map((n) => NotificationModel.fromJson(Map<String, dynamic>.from(n)))
                  .toList();
            }
            unread = int.tryParse(dataSection['unreadCount']?.toString() ?? '') ?? 0;
          }

          if (resData['pagination'] is Map) {
            final p = resData['pagination'] as Map;
            total = int.tryParse(p['total']?.toString() ?? '') ?? items.length;
            resPage = int.tryParse(p['page']?.toString() ?? '') ?? page;
            resLimit = int.tryParse(p['limit']?.toString() ?? '') ?? limit;
            totalPages = int.tryParse(p['totalPages']?.toString() ?? '') ?? ((total / resLimit).ceil());
          } else {
            total = int.tryParse(resData['total']?.toString() ?? resData['count']?.toString() ?? '') ?? items.length;
            totalPages = total > 0 ? (total / resLimit).ceil() : 1;
          }

          if (unread == 0 && resData['unreadCount'] != null) {
            unread = int.tryParse(resData['unreadCount'].toString()) ?? 0;
          }
        } else if (resData is List) {
          items = resData
              .whereType<Map>()
              .map((n) => NotificationModel.fromJson(Map<String, dynamic>.from(n)))
              .toList();
          total = items.length;
          totalPages = 1;
        }

        if (unread == 0) {
          unread = items.where((n) => !n.isRead).length;
        }

        return NotificationPaginatedResult(
          items: items,
          unreadCount: unread,
          total: total,
          page: resPage,
          limit: resLimit,
          totalPages: totalPages > 0 ? totalPages : 1,
        );
      }
    } catch (e) {
      if (kDebugMode) print('[ApiService] getNotifications error: $e');
    }

    return NotificationPaginatedResult(
      items: [],
      unreadCount: 0,
      total: 0,
      page: page,
      limit: limit,
      totalPages: 1,
    );
  }

  /// Mark Single as Read: POST /notifications/{id}/read
  Future<bool> markNotificationAsRead(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return false;

    try {
      final response = await _dio.post('/notifications/$cleanId/read');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) print('[ApiService] markNotificationAsRead error: $e');
      return false;
    }
  }

  /// Mark All as Read: POST /notifications/read-all
  Future<bool> markAllNotificationsAsRead(String gaushalaId) async {
    final cleanGId = gaushalaId.trim();
    try {
      final response = await _dio.post(
        '/notifications/read-all',
        data: {'gaushalaId': cleanGId},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) print('[ApiService] markAllNotificationsAsRead error: $e');
      return false;
    }
  }

  /// Delete Notification: POST /notifications/{id}/delete
  Future<bool> deleteNotification(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return false;

    try {
      final response = await _dio.post('/notifications/$cleanId/delete');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (kDebugMode) print('[ApiService] deleteNotification error: $e');
      return false;
    }
  }

  /// Create In-App Notification / Alert: POST /notifications
  Future<bool> createNotification({
    required String gaushalaId,
    required String title,
    required String message,
    String type = 'MILK_PRODUCTION_ALERT',
    String? cowTagId,
  }) async {
    final cleanGId = gaushalaId.trim();
    if (cleanGId.isEmpty) return false;

    try {
      final payload = {
        'gaushalaId': cleanGId,
        'title': title.trim(),
        'message': message.trim(),
        'type': type.trim(),
        if (cowTagId != null && cowTagId.trim().isNotEmpty) 'cowTagId': cowTagId.trim(),
      };

      final response = await _dio.post(
        '/notifications',
        data: payload,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) print('[ApiService] createNotification error: $e');
      return false;
    }
  }

  // -------------------------------------------------------------
  // DEPARTMENT APIS (/departments)
  // -------------------------------------------------------------

  /// GET /api/v1/departments?gaushalaId={id}&search={query}
  Future<List<DepartmentModel>> getDepartments({
    required String gaushalaId,
    String? search,
  }) async {
    final cleanGId = gaushalaId.trim();
    if (cleanGId.isEmpty || cleanGId == 'all') return [];

    final Map<String, dynamic> queryParameters = {
      'gaushalaId': cleanGId,
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    final response = await _dio.get(
      '/departments',
      queryParameters: queryParameters,
    );

    if (response.statusCode == 200 && response.data != null) {
      if (response.data is List) {
        final List list = response.data as List;
        return list
            .map((item) => DepartmentModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is List) {
        final List list = responseData['data'] as List;
        return list
            .map((item) => DepartmentModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } else if (responseData['departments'] is List) {
        final List list = responseData['departments'] as List;
        return list
            .map((item) => DepartmentModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } else if (responseData['data'] is Map && (responseData['data'] as Map)['departments'] is List) {
        final List list = (responseData['data'] as Map)['departments'] as List;
        return list
            .map((item) => DepartmentModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    }
    return [];
  }

  /// POST /api/v1/departments
  Future<DepartmentModel> createDepartment({
    required String gaushalaId,
    required String departmentName,
    required String departmentCode,
    String? description,
  }) async {
    final Map<String, dynamic> data = {
      'gaushalaId': gaushalaId.trim(),
      'departmentName': departmentName.trim(),
      'departmentCode': departmentCode.trim().toUpperCase(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };

    final response = await _dio.post(
      '/departments',
      data: data,
    );

    if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is Map) {
        return DepartmentModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
      }
      return DepartmentModel.fromJson(responseData);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to create department.',
    );
  }

  /// POST /api/v1/departments/{id}/update
  Future<DepartmentModel> updateDepartment(
    String id, {
    required String departmentName,
    required String departmentCode,
    String? description,
    bool isActive = true,
  }) async {
    final Map<String, dynamic> data = {
      'departmentName': departmentName.trim(),
      'departmentCode': departmentCode.trim().toUpperCase(),
      'description': description?.trim() ?? '',
      'isActive': isActive,
    };

    final response = await _dio.post(
      '/departments/${id.trim()}/update',
      data: data,
    );

    if (response.statusCode == 200 && response.data != null) {
      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is Map) {
        return DepartmentModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
      }
      return DepartmentModel.fromJson(responseData);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to update department.',
    );
  }

  /// POST /api/v1/departments/{id}/delete
  Future<bool> deleteDepartment(String id) async {
    final response = await _dio.post(
      '/departments/${id.trim()}/delete',
      data: {},
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    return false;
  }

  /// GET /api/v1/departments/{id}/workers
  Future<List<WorkerModel>> getDepartmentWorkers(String departmentId) async {
    final cleanId = departmentId.trim();
    if (cleanId.isEmpty) return [];

    final response = await _dio.get('/departments/$cleanId/workers');
    if (response.statusCode == 200 && response.data != null) {
      if (response.data is List) {
        final List list = response.data as List;
        return list
            .map((item) => WorkerModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is List) {
        final List list = responseData['data'] as List;
        return list
            .map((item) => WorkerModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } else if (responseData['workers'] is List) {
        final List list = responseData['workers'] as List;
        return list
            .map((item) => WorkerModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    }
    return [];
  }

  // -------------------------------------------------------------
  // WORKER APIS (/workers)
  // -------------------------------------------------------------

  /// GET /api/v1/workers/department-summary?gaushalaId={id}
  Future<DepartmentSummaryModel> getWorkerDepartmentSummary({
    required String gaushalaId,
  }) async {
    final cleanGId = gaushalaId.trim();
    if (cleanGId.isEmpty || cleanGId == 'all') {
      return const DepartmentSummaryModel();
    }

    final response = await _dio.get(
      '/workers/department-summary',
      queryParameters: {'gaushalaId': cleanGId},
    );

    if (response.statusCode == 200 && response.data != null) {
      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);
      return DepartmentSummaryModel.fromJson(responseData);
    }

    return const DepartmentSummaryModel();
  }

  /// GET /api/v1/workers?gaushalaId={id}&departmentId={deptId}&isActive={true/false}&search={query}&page={page}&limit={limit}
  Future<WorkerPaginatedResult> getWorkers({
    required String gaushalaId,
    String? departmentId,
    bool? isActive,
    String? search,
    int page = 1,
    int limit = 5,
  }) async {
    final cleanGId = gaushalaId.trim();
    if (cleanGId.isEmpty || cleanGId == 'all') {
      return const WorkerPaginatedResult(items: [], total: 0, page: 1, limit: 5, totalPages: 1);
    }

    final Map<String, dynamic> queryParameters = {
      'gaushalaId': cleanGId,
      'page': page,
      'limit': limit,
    };
    if (departmentId != null && departmentId.trim().isNotEmpty && departmentId != 'all') {
      queryParameters['departmentId'] = departmentId.trim();
    }
    if (isActive != null) {
      queryParameters['isActive'] = isActive;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    final response = await _dio.get(
      '/workers',
      queryParameters: queryParameters,
    );

    if (response.statusCode == 200 && response.data != null) {
      final responseData = response.data;
      List<WorkerModel> items = [];
      int total = 0;
      int curPage = page;
      int pageLimit = limit;
      int totalPages = 1;

      if (responseData is Map) {
        if (responseData['data'] is List) {
          final List list = responseData['data'] as List;
          items = list
              .map((item) => WorkerModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        } else if (responseData['workers'] is List) {
          final List list = responseData['workers'] as List;
          items = list
              .map((item) => WorkerModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        } else if (responseData['data'] is Map && (responseData['data'] as Map)['workers'] is List) {
          final List list = (responseData['data'] as Map)['workers'] as List;
          items = list
              .map((item) => WorkerModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        }

        if (responseData['pagination'] is Map) {
          final p = responseData['pagination'] as Map;
          total = (p['total'] as num?)?.toInt() ?? items.length;
          curPage = (p['page'] as num?)?.toInt() ?? page;
          pageLimit = (p['limit'] as num?)?.toInt() ?? limit;
          totalPages = (p['totalPages'] as num?)?.toInt() ?? (total > 0 ? (total / pageLimit).ceil() : 1);
        } else if (responseData['meta'] is Map) {
          final m = responseData['meta'] as Map;
          total = (m['total'] as num?)?.toInt() ?? items.length;
          curPage = (m['page'] as num?)?.toInt() ?? page;
          pageLimit = (m['limit'] as num?)?.toInt() ?? limit;
          totalPages = (m['totalPages'] as num?)?.toInt() ?? (total > 0 ? (total / pageLimit).ceil() : 1);
        } else {
          total = (responseData['total'] as num?)?.toInt() ?? items.length;
          totalPages = (total > 0) ? (total / pageLimit).ceil() : 1;
        }
      } else if (responseData is List) {
        items = responseData
            .map((item) => WorkerModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        total = items.length;
      }

      return WorkerPaginatedResult(
        items: items,
        total: total,
        page: curPage,
        limit: pageLimit,
        totalPages: totalPages < 1 ? 1 : totalPages,
      );
    }

    return WorkerPaginatedResult(
      items: [],
      total: 0,
      page: page,
      limit: limit,
      totalPages: 1,
    );
  }

  /// GET /api/v1/workers/{id}
  Future<WorkerModel> getWorkerById(String id) async {
    final cleanId = id.trim();
    final response = await _dio.get('/workers/$cleanId');

    if (response.statusCode == 200 && response.data != null) {
      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is Map) {
        return WorkerModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
      }
      return WorkerModel.fromJson(responseData);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to fetch worker details.',
    );
  }

  /// POST /api/v1/workers
  Future<WorkerModel> createWorker({
    required String gaushalaId,
    required String departmentId,
    required String name,
    required DateTime joiningDate,
  }) async {
    final Map<String, dynamic> data = {
      'gaushalaId': gaushalaId.trim(),
      'departmentId': departmentId.trim(),
      'name': name.trim(),
      'joiningDate': joiningDate.toUtc().toIso8601String(),
    };

    final response = await _dio.post(
      '/workers',
      data: data,
    );

    if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is Map) {
        return WorkerModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
      }
      return WorkerModel.fromJson(responseData);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to add worker.',
    );
  }

  /// POST /api/v1/workers/{id}/update (Admin Edit)
  Future<WorkerModel> updateWorker(
    String id, {
    required String name,
    required String departmentId,
    required bool isActive,
  }) async {
    final Map<String, dynamic> data = {
      'name': name.trim(),
      'departmentId': departmentId.trim(),
      'isActive': isActive,
    };

    final response = await _dio.post(
      '/workers/${id.trim()}/update',
      data: data,
    );

    if (response.statusCode == 200 && response.data != null) {
      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is Map) {
        return WorkerModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
      }
      return WorkerModel.fromJson(responseData);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to update worker.',
    );
  }

  /// POST /api/v1/workers/{id}/status (Toggle Active/Inactive)
  Future<WorkerModel> updateWorkerStatus(
    String id, {
    required bool isActive,
  }) async {
    final Map<String, dynamic> data = {
      'isActive': isActive,
    };

    final response = await _dio.post(
      '/workers/${id.trim()}/status',
      data: data,
    );

    if (response.statusCode == 200 && response.data != null) {
      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is Map) {
        return WorkerModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
      }
      return WorkerModel.fromJson(responseData);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to update worker status.',
    );
  }

  /// POST /api/v1/workers/{id}/leave (Worker Leaving Gaushala)
  Future<WorkerModel> markWorkerLeft(
    String id, {
    required DateTime leavingDate,
  }) async {
    final Map<String, dynamic> data = {
      'leavingDate': leavingDate.toUtc().toIso8601String(),
    };

    final response = await _dio.post(
      '/workers/${id.trim()}/leave',
      data: data,
    );

    if (response.statusCode == 200 && response.data != null) {
      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is Map) {
        return WorkerModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
      }
      return WorkerModel.fromJson(responseData);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to record worker leaving date.',
    );
  }

  /// POST /api/v1/workers/{id}/delete (Soft Delete Worker)
  Future<bool> deleteWorker(String id) async {
    final response = await _dio.post(
      '/workers/${id.trim()}/delete',
      data: {},
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    return false;
  }

  // -------------------------------------------------------------
  // PERMISSIONS & RBAC APIS
  // -------------------------------------------------------------

  /// GET /api/v1/permissions/my-permissions
  /// Retrieves current logged-in user permissions and admin status
  Future<UserPermissionsResponse> getMyPermissions() async {
    final response = await _dio.get('/permissions/my-permissions');
    if (response.data is Map<String, dynamic>) {
      return UserPermissionsResponse.fromJson(response.data as Map<String, dynamic>);
    }
    return const UserPermissionsResponse(userId: '', role: '');
  }

  /// GET /api/v1/permissions/users/:userId (Admin only)
  /// Retrieves user permission matrix with all modules and submodules
  Future<UserPermissionMatrixResponse> getUserPermissionMatrix(String userId) async {
    final response = await _dio.get('/permissions/users/${userId.trim()}');
    if (response.data is Map<String, dynamic>) {
      return UserPermissionMatrixResponse.fromJson(response.data as Map<String, dynamic>);
    }
    return const UserPermissionMatrixResponse();
  }

  /// POST /api/v1/permissions/users/:userId (Admin only)
  /// Updates granular permission flags for a specified user
  Future<bool> updateUserPermissions(
    String userId,
    List<Map<String, dynamic>> permissions,
  ) async {
    final response = await _dio.post(
      '/permissions/users/${userId.trim()}',
      data: {'permissions': permissions},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    return false;
  }

  /// Aggregated Alerts Summary: GET /dashboard/alerts-summary?gaushalaId={gaushalaId}
  /// Returns consolidated alert metrics across treatments, milk, medical stock, and feed.
  Future<DashboardAlertsSummaryResponse?> getDashboardAlertsSummary({
    required String gaushalaId,
  }) async {
    final cleanGId = gaushalaId.trim();
    if (cleanGId.isEmpty) return null;

    try {
      final response = await _dio.get(
        '/dashboard/alerts-summary',
        queryParameters: {'gaushalaId': cleanGId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data;
        if (resData is Map<String, dynamic>) {
          return DashboardAlertsSummaryResponse.fromJson(resData);
        } else if (resData is Map) {
          return DashboardAlertsSummaryResponse.fromJson(Map<String, dynamic>.from(resData));
        }
      }
    } catch (e) {
      if (kDebugMode) print('[ApiService] getDashboardAlertsSummary fallback trigger: $e');
    }
    return null;
  }

  /// Low-stock Feed Items: GET /feed-stock/items/low-stock?gaushalaId={id}
  /// Gracefully falls back to client filtering over getFeedItems if endpoint is unavailable.
  Future<List<FeedItemModel>> getLowStockFeedItems({String? gaushalaId}) async {
    final Map<String, dynamic> queryParams = {};
    final cleanGId = gaushalaId?.trim();
    if (cleanGId != null && cleanGId.isNotEmpty && cleanGId != 'all') {
      queryParams['gaushalaId'] = cleanGId;
    }

    try {
      final response = await _dio.get(
        '/feed-stock/items/low-stock',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data;
        if (resData is Map && resData['data'] is List) {
          return (resData['data'] as List)
              .whereType<Map>()
              .map((i) => FeedItemModel.fromJson(Map<String, dynamic>.from(i)))
              .toList();
        } else if (resData is List) {
          return resData
              .whereType<Map>()
              .map((i) => FeedItemModel.fromJson(Map<String, dynamic>.from(i)))
              .toList();
        }
      }
    } catch (_) {
      // Fallback: fetch items and filter currentStock <= minStockAlert
      try {
        final allItems = await getFeedItems(
          gaushalaId: cleanGId,
        );
        return allItems
            .where((item) => item.currentStock <= item.minStockAlert)
            .toList();
      } catch (inner) {
        if (kDebugMode) print('[ApiService] getLowStockFeedItems fallback error: $inner');
      }
    }
    return <FeedItemModel>[];
  }

  /// Quick Medical Stock Inward for Dashboard inline actions:
  /// POST /medical-stock/transactions/inward
  Future<bool> recordQuickMedicalStockInward({
    required String gaushalaId,
    required String itemId,
    required String batchNumber,
    required DateTime expiryDate,
    required double quantity,
  }) async {
    final formattedDate =
        "${expiryDate.year.toString().padLeft(4, '0')}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}";

    final payload = {
      'gaushalaId': gaushalaId.trim(),
      'itemId': itemId.trim(),
      'batchNumber': batchNumber.trim(),
      'expiryDate': formattedDate,
      'quantity': quantity,
      'reason': 'PURCHASE',
      'supplierOrDonorName': 'Dashboard Quick Inward',
      'billOrReceiptNo': 'QCK-${DateTime.now().millisecondsSinceEpoch}',
      'batches': [
        {
          'batchNumber': batchNumber.trim(),
          'expiryDate': formattedDate,
          'quantity': quantity,
          'unitPrice': 0.0,
          'mrp': 0.0,
        }
      ],
    };

    final response = await _dio.post(
      '/medical-stock/transactions/inward',
      data: payload,
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Quick Feed Stock Inward for Dashboard inline actions:
  /// POST /feed-stock/transactions/inward
  Future<bool> recordQuickFeedStockInward({
    required String gaushalaId,
    required String itemId,
    required double quantity,
    required String unit,
    String reason = 'PURCHASE',
  }) async {
    final payload = {
      'gaushalaId': gaushalaId.trim(),
      'itemId': itemId.trim(),
      'quantity': quantity,
      'unit': unit.trim(),
      'reason': reason.trim(),
      'source': reason.trim(),
      'supplierOrDonorName': 'Dashboard Quick Inward',
      'billOrReceiptNo': 'QCK-${DateTime.now().millisecondsSinceEpoch}',
    };

    final response = await _dio.post(
      '/feed-stock/transactions/inward',
      data: payload,
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }
}


